const crypto = require("crypto");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const play = require("./exercise_play");

initializeApp();
const db = getFirestore();

const LINK_CODES = "teacher_link_codes";
const USERS = "users";
const NOTIFICATIONS = "notifications";
const EXERCISE_RESULTS = "exercise_results";
const EXERCISES = "exercises";
const INVOICES = "invoices";
const CLASS_TERMS = "student_class_terms";
const AUDIT_LOGS = "audit_logs";
const QUESTION_BANK = "question_bank";
const EXERCISE_ASSIGNMENTS = "exercise_assignments";
const STUDENT_PROGRESS = "student_progress";

// Midtrans Server Key lives ONLY here (never in the Flutter app or git).
// Set with: firebase functions:secrets:set MIDTRANS_SERVER_KEY
const MIDTRANS_SERVER_KEY = defineSecret("MIDTRANS_SERVER_KEY");

// Sandbox by default. Point at production only when going live.
const MIDTRANS_SNAP_URL =
  "https://app.sandbox.midtrans.com/snap/v1/transactions";

// The Price list and term validity live in Firestore `settings/pricing`,
// edited by admins in the app (Payments → Price list). `items` is the source
// of truth; the four legacy fields are read when `items` is missing. These are
// the fallbacks (course flyer, Oct 2026). The invoice amount is always derived
// server-side; a client value is ignored.
const DEFAULT_PRICE_ITEMS = [
  {id: "registration", name: "Registration (one-time)", price: 100000,
    kind: "registration", sessions: 0},
  {id: "package8", name: "8 class sessions", price: 2450000,
    kind: "sessions", sessions: 8},
  {id: "package16", name: "16 class sessions", price: 3950000,
    kind: "sessions", sessions: 16},
  {id: "book", name: "HSK materials & book", price: 250000,
    kind: "book", sessions: 0},
];
const DEFAULT_TERM_VALID_DAYS = 60;
const SETTINGS = "settings";

async function loadPricing() {
  const snap = await db.collection(SETTINGS).doc("pricing").get();
  const data = snap.exists ? snap.data() || {} : {};
  const positiveInt = (v, fallback) =>
    Number.isInteger(Number(v)) && Number(v) > 0 ? Number(v) : fallback;
  let items = Array.isArray(data.items) ?
    data.items
        .filter((it) => it && it.id && positiveInt(it.price, 0) > 0)
        .map((it) => ({
          id: String(it.id),
          name: String(it.name || it.id),
          price: Number(it.price),
          kind: String(it.kind || "other"),
          sessions: it.kind === "sessions" ? positiveInt(it.sessions, 0) : 0,
        })) :
    [];
  if (items.length === 0) {
    const legacy = {
      package8: positiveInt(data.package8, 2450000),
      package16: positiveInt(data.package16, 3950000),
      book: positiveInt(data.book, 250000),
      registration: positiveInt(data.registration, 100000),
    };
    items = DEFAULT_PRICE_ITEMS.map((it) => ({...it, price: legacy[it.id]}));
  }
  return {
    items,
    termValidDays: positiveInt(data.termValidDays, DEFAULT_TERM_VALID_DAYS),
  };
}

// Resolve the price-list row for an invoice request. New clients send
// `priceItemId`; older ones send `item` + `packageSize`.
function findPriceItem(pricing, {priceItemId, item, packageSize}) {
  if (priceItemId) {
    return pricing.items.find((it) => it.id === priceItemId) || null;
  }
  if (item === BOOK_ITEM) {
    return pricing.items.find((it) => it.kind === "book") || null;
  }
  const n = Number(packageSize);
  return pricing.items.find(
      (it) => it.kind === "sessions" && it.sessions === n,
  ) || null;
}

// Non-session item. "book" = HSK materials and textbook. Paying a book
// invoice credits no sessions.
const BOOK_ITEM = "book";
const BOOK_DESCRIPTION = "HSK materials and book";

// Worksheet import runs locally in the Flutter web app (Tesseract.js + PDF/Word
// parsers). No cloud AI or API keys are required for teachers.

function normalizeCode(raw) {
  return String(raw || "").trim().toUpperCase();
}

/**
 * Append an entry to the append-only audit log. Best-effort: a logging failure
 * must never break the action being audited. All writes are via the admin SDK
 * (clients can't create/read-write audit_logs; only admins read).
 */
async function writeAudit(entry) {
  try {
    await db.collection(AUDIT_LOGS).add({
      action: entry.action,
      actorId: entry.actorId || "system",
      actorName: entry.actorName || "System",
      targetType: entry.targetType || null,
      targetId: entry.targetId || null,
      detail: entry.detail || "",
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    logger.error("writeAudit failed", err);
  }
}

/**
 * Resolve a teacher link code to a teacherId.
 *
 * Runs with admin privileges so the `teacher_link_codes` collection can stay
 * closed to anonymous reads (no client-side enumeration of codes -> teachers).
 * Callable pre-signup: a student registering with email/password has no auth
 * account yet, so this must work without `request.auth`.
 */
exports.resolveLinkCode = onCall(async (request) => {
  const code = normalizeCode(request.data && request.data.code);
  if (code.length < 4) {
    throw new HttpsError(
      "invalid-argument",
      "Enter the link code from your teacher.",
    );
  }

  const snap = await db.collection(LINK_CODES).doc(code).get();
  if (!snap.exists) {
    throw new HttpsError(
      "not-found",
      "Invalid link code. Ask your teacher for the current code.",
    );
  }

  const data = snap.data() || {};
  const teacherId = data.teacherId;
  if (!teacherId) {
    throw new HttpsError(
      "failed-precondition",
      "This link code is no longer valid.",
    );
  }

  const expiresAt = data.expiresAt;
  const expiryMs =
    expiresAt && typeof expiresAt.toMillis === "function" ?
      expiresAt.toMillis() :
      0;
  if (!expiryMs || Date.now() > expiryMs) {
    throw new HttpsError(
      "deadline-exceeded",
      "This link code has expired. Ask your teacher for a new one.",
    );
  }

  // The code must belong to an active teacher. Rules now stop non-teachers
  // from minting codes, but older docs or a stale owner still fail here.
  const ownerSnap = await db.collection(USERS).doc(teacherId).get();
  const owner = ownerSnap.exists ? ownerSnap.data() || {} : {};
  if (owner.role !== "teacher" || owner.active === false) {
    throw new HttpsError(
      "failed-precondition",
      "This link code is no longer valid. Ask your teacher for a new one.",
    );
  }

  return {teacherId};
});

/**
 * Fan out registration notifications when a new student user doc is created.
 *
 * Clients cannot write to `notifications` (rules require staff), and a student
 * self-registering is not staff — so this trigger owns the notification write
 * with admin privileges. Fires for both self-registration and admin-created
 * students, covering every path exactly once.
 */
exports.onUserCreated = onDocumentCreated(`${USERS}/{uid}`, async (event) => {
  const snap = event.data;
  if (!snap) return;
  const user = snap.data() || {};
  if (user.role !== "student") return;

  const studentName = user.nameIndonesian || user.name || "A new student";

  let teacherName = null;
  if (user.teacherId) {
    try {
      const teacherSnap = await db.collection(USERS).doc(user.teacherId).get();
      if (teacherSnap.exists) {
        const teacher = teacherSnap.data() || {};
        teacherName = teacher.nameIndonesian || teacher.name || null;
      }
    } catch (err) {
      logger.warn("onUserCreated: failed to load teacher name", err);
    }
  }

  const now = FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.set(db.collection(NOTIFICATIONS).doc(), {
    kind: "registration",
    title: "New student registered",
    body: teacherName ?
      `${studentName} signed up with ${teacherName}'s centre.` :
      `${studentName} registered in Easy Study.`,
    forRole: "admin",
    userId: "", // broadcast; stored as '' so clients can query it
    targetRoute: "/admin",
    read: false,
    createdAt: now,
  });

  const teacherNotification = {
    kind: "registration",
    title: "New student registered",
    body: `${studentName} joined your centre.`,
    forRole: "teacher",
    userId: "",
    targetRoute: "/teacher",
    read: false,
    createdAt: now,
  };
  // Target the specific teacher when known; otherwise broadcast to all teachers.
  if (user.teacherId) {
    teacherNotification.userId = user.teacherId;
  }
  batch.set(db.collection(NOTIFICATIONS).doc(), teacherNotification);

  await batch.commit();
});

/**
 * Fan out grading notifications when a student submits an exercise.
 *
 * Students can't write to `notifications` (staff-only), so the client-side
 * write fails — this trigger owns it. Notifies the student's teacher and echoes
 * the score back to the student.
 */
exports.onExerciseResultCreated = onDocumentCreated(
  `${EXERCISE_RESULTS}/{resultId}`,
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const result = snap.data() || {};
    const studentId = result.studentId;
    if (!studentId) return;
    const score = typeof result.score === "number" ? result.score : 0;

    let studentName = "A student";
    let teacherId = null;
    try {
      const studentSnap = await db.collection(USERS).doc(studentId).get();
      if (studentSnap.exists) {
        const s = studentSnap.data() || {};
        studentName = s.nameIndonesian || s.name || studentName;
        teacherId = s.teacherId || null;
      }
    } catch (err) {
      logger.warn("onExerciseResultCreated: failed to load student", err);
    }

    let exerciseTitle = "an exercise";
    if (result.exerciseId) {
      try {
        const exSnap =
          await db.collection(EXERCISES).doc(result.exerciseId).get();
        if (exSnap.exists) {
          exerciseTitle = (exSnap.data() || {}).title || exerciseTitle;
        }
      } catch (err) {
        logger.warn("onExerciseResultCreated: failed to load exercise", err);
      }
    }

    const now = FieldValue.serverTimestamp();
    const batch = db.batch();

    const teacherNotification = {
      kind: "grading",
      title: "Practice submitted",
      body: `${studentName} scored ${score}% on ${exerciseTitle}.`,
      forRole: "teacher",
      userId: "",
      targetRoute: "/teacher",
      read: false,
      createdAt: now,
    };
    if (teacherId) {
      teacherNotification.userId = teacherId;
    }
    batch.set(db.collection(NOTIFICATIONS).doc(), teacherNotification);

    batch.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "grading",
      title: "Score recorded",
      body: `You scored ${score}% on ${exerciseTitle}.`,
      forRole: "student",
      userId: studentId,
      targetRoute: "/student",
      read: false,
      createdAt: now,
    });

    await batch.commit();
  },
);

/**
 * Purge expired teacher link codes (they are only deleted on rotation otherwise).
 */
exports.cleanupExpiredLinkCodes = onSchedule("every 60 minutes", async () => {
  const now = Timestamp.now();
  const snap = await db
    .collection(LINK_CODES)
    .where("expiresAt", "<", now)
    .limit(500)
    .get();

  if (snap.empty) {
    logger.info("cleanupExpiredLinkCodes: nothing to delete");
    return;
  }

  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  logger.info(`cleanupExpiredLinkCodes: deleted ${snap.size} codes`);
});

/**
 * Resolve a student's parent-access code to that student (+ their teacher).
 *
 * Mirrors resolveLinkCode: runs with admin privileges so it works during
 * parent email/password registration (before the parent has an auth account),
 * and so the `users` collection stays closed to code enumeration.
 */
exports.resolveChildCode = onCall(async (request) => {
  const code = normalizeCode(request.data && request.data.code);
  if (code.length < 4) {
    throw new HttpsError(
      "invalid-argument",
      "Enter the child access code from your child's profile.",
    );
  }

  const snap = await db
    .collection(USERS)
    .where("parentCode", "==", code)
    .where("role", "==", "student")
    .limit(1)
    .get();

  if (snap.empty) {
    throw new HttpsError(
      "not-found",
      "Invalid child access code. Check your child's profile for the code.",
    );
  }

  const doc = snap.docs[0];
  const data = doc.data() || {};
  return {
    studentId: doc.id,
    teacherId: data.teacherId || null,
    studentName: data.nameIndonesian || data.name || null,
  };
});

/**
 * Authoritatively link the calling parent to a child via the child's access
 * code. This is the ONLY path that may write `studentIds`/`teacherIds` on a
 * parent doc — clients are blocked from writing those fields by the rules, so a
 * parent can never link to a student whose code they don't hold.
 */
exports.linkChild = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in to link a child.");
  }
  const code = normalizeCode(request.data && request.data.code);
  if (code.length < 4) {
    throw new HttpsError(
      "invalid-argument",
      "Enter the child access code from your child's profile.",
    );
  }

  const callerRef = db.collection(USERS).doc(auth.uid);
  const callerSnap = await callerRef.get();
  if (!callerSnap.exists || (callerSnap.data() || {}).role !== "parent") {
    throw new HttpsError(
      "permission-denied",
      "Only parent accounts can link a child.",
    );
  }

  const snap = await db
    .collection(USERS)
    .where("parentCode", "==", code)
    .where("role", "==", "student")
    .limit(1)
    .get();
  if (snap.empty) {
    throw new HttpsError(
      "not-found",
      "Invalid child access code. Check your child's profile for the code.",
    );
  }

  const child = snap.docs[0];
  const childData = child.data() || {};
  const update = {studentIds: FieldValue.arrayUnion(child.id)};
  if (childData.teacherId) {
    update.teacherIds = FieldValue.arrayUnion(childData.teacherId);
  }
  await callerRef.update(update);

  return {
    studentId: child.id,
    studentName: childData.nameIndonesian || childData.name || null,
  };
});

/**
 * Create a pending invoice and a Midtrans Snap transaction.
 *
 * Staff-only (admin/teacher). Writes the invoice with status "pending" using
 * admin privileges, then calls Midtrans Snap with the Server Key and returns
 * the Snap token + redirect URL. Never flips an invoice to paid — only the
 * webhook does that.
 */
exports.createInvoice = onCall(
  {secrets: [MIDTRANS_SERVER_KEY]},
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Sign in to create invoices.");
    }

    const callerSnap = await db.collection(USERS).doc(auth.uid).get();
    const caller = callerSnap.exists ? callerSnap.data() : {};
    const callerRole = (caller && caller.role) || "";
    const isStaff = callerRole === "admin" || callerRole === "teacher";
    if (!isStaff) {
      throw new HttpsError(
        "permission-denied",
        "Only staff can create invoices.",
      );
    }

    const data = request.data || {};
    const studentId = String(data.studentId || "").trim();
    const dueDate = String(data.dueDate || "").trim();
    const classTermId = String(data.classTermId || "").trim() || null;

    if (!studentId) {
      throw new HttpsError("invalid-argument", "studentId is required.");
    }

    // Amount is authoritative on the server — derive from the Price list and
    // ignore any client-supplied value so a caller can't misprice a sale.
    const pricing = await loadPricing();
    const priceItem = findPriceItem(pricing, {
      priceItemId: data.priceItemId,
      item: data.item,
      packageSize: data.packageSize,
    });
    if (!priceItem) {
      throw new HttpsError(
          "failed-precondition",
          "That item is not on the Price list.",
      );
    }
    const amount = priceItem.price;
    const item = priceItem.kind === "book" ? BOOK_ITEM : "package";
    const packageSize = priceItem.sessions;
    const description = priceItem.name;

    const studentSnap = await db.collection(USERS).doc(studentId).get();
    if (!studentSnap.exists) {
      throw new HttpsError("not-found", "Student not found.");
    }
    const student = studentSnap.data() || {};
    const teacherId = student.teacherId || auth.uid;
    const studentName = student.nameIndonesian || student.name || "Student";

    // Teachers may only invoice their own students.
    if (callerRole === "teacher" && teacherId !== auth.uid) {
      throw new HttpsError(
        "permission-denied",
        "You can only invoice your own students.",
      );
    }

    const orderId = `ES-INV-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const invoiceRef = db.collection(INVOICES).doc();

    await invoiceRef.set({
      invoiceNumber: orderId,
      studentId,
      studentName,
      teacherId,
      item,
      description,
      packageSize,
      priceItemId: priceItem.id,
      kind: priceItem.kind,
      sessions: priceItem.sessions,
      amount,
      currency: "IDR",
      status: "pending",
      paymentMethod: "midtrans",
      dueDate,
      midtransOrderId: orderId,
      ...(classTermId ? {classTermId} : {}),
      createdBy: auth.uid,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Call Midtrans Snap.
    const serverKey = MIDTRANS_SERVER_KEY.value();
    const authHeader =
      "Basic " + Buffer.from(`${serverKey}:`).toString("base64");

    let snapToken = null;
    let redirectUrl = null;
    try {
      const res = await fetch(MIDTRANS_SNAP_URL, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": authHeader,
        },
        body: JSON.stringify({
          transaction_details: {
            order_id: orderId,
            gross_amount: amount,
          },
          item_details: [
            {
              id: priceItem.id,
              price: amount,
              quantity: 1,
              name: priceItem.name.slice(0, 50),
            },
          ],
          customer_details: {
            first_name: studentName,
            email: student.email || undefined,
          },
        }),
      });

      const body = await res.json();
      if (!res.ok) {
        logger.error("createInvoice: Midtrans error", body);
        throw new HttpsError(
          "internal",
          "Payment provider rejected the request.",
        );
      }
      snapToken = body.token || null;
      redirectUrl = body.redirect_url || null;

      await invoiceRef.update({
        snapToken,
        redirectUrl,
      });
    } catch (err) {
      // Snap creation failed — remove the dangling pending invoice so the
      // student isn't left with an unpayable (no redirectUrl) invoice.
      await invoiceRef.delete().catch(() => {});
      if (err instanceof HttpsError) throw err;
      logger.error("createInvoice: Snap request failed", err);
      throw new HttpsError("internal", "Could not reach the payment provider.");
    }

    await writeAudit({
      action: "invoice.created",
      actorId: auth.uid,
      actorName: caller.name || caller.nameIndonesian || "Staff",
      targetType: "invoice",
      targetId: invoiceRef.id,
      detail:
        `${orderId} · ${description} · Rp ${amount} for ${studentName}`,
    });

    return {invoiceId: invoiceRef.id, snapToken, redirectUrl};
  },
);

/**
 * Inside a transaction that just flipped `invoiceRef` to paid: give the
 * student what the invoice is for. A sessions invoice linked to an existing
 * term (`classTermId`, teacher added the term first) marks that term paid;
 * otherwise a new term is created. Book / registration / other credit nothing.
 * Returns what was credited, for the notification and the audit line.
 */
function creditPaidInvoice(tx, invoiceRef, invoice, termValidDays) {
  const sessions = Number(invoice.sessions);
  const credits = invoice.kind === "sessions" ?
    sessions > 0 :
    (invoice.item !== BOOK_ITEM && Number(invoice.packageSize) > 0);
  const packageSize = invoice.kind === "sessions" ?
    sessions :
    Number(invoice.packageSize) || 0;
  if (!credits || !invoice.studentId) {
    return {invoice, packageSize: 0, book: true};
  }
  if (invoice.classTermId) {
    tx.update(db.collection(CLASS_TERMS).doc(invoice.classTermId), {
      sourceInvoiceId: invoiceRef.id,
      paidAt: FieldValue.serverTimestamp(),
    });
    return {invoice, packageSize, existingTerm: true};
  }
  const now = new Date();
  const deadline = new Date(now.getTime() + termValidDays * 86400000);
  const fmt = (d) => d.toISOString().slice(0, 10);
  tx.set(db.collection(CLASS_TERMS).doc(), {
    studentId: invoice.studentId,
    packageSize,
    sessionsRemaining: packageSize,
    sessionsUsed: 0,
    status: "active",
    startDate: fmt(now),
    deadlineDate: fmt(deadline),
    sourceInvoiceId: invoiceRef.id,
    createdBy: invoice.paymentMethod === "midtrans" ? "midtrans" : "admin",
    purchasedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });
  return {invoice, packageSize};
}

function paidAuditDetail(credited, ref) {
  const inv = credited.invoice;
  const who = inv.studentName || inv.studentId;
  let what;
  if (credited.book) {
    what = `${inv.description || BOOK_DESCRIPTION} paid by ${who}`;
  } else if (credited.existingTerm) {
    what = `${credited.packageSize}-session voucher of ${who} marked paid`;
  } else {
    what = `${credited.packageSize} sessions credited to ${who}`;
  }
  return `${ref} · Rp ${inv.amount || 0} · ${what}`;
}

/**
 * Admin records a payment made by hand (cash or bank transfer at the centre).
 * Same crediting as the Midtrans webhook, in one transaction, idempotent.
 */
exports.markInvoicePaid = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const callerSnap = await db.collection(USERS).doc(auth.uid).get();
  const caller = callerSnap.exists ? callerSnap.data() : {};
  if (!caller || caller.role !== "admin" || caller.active === false) {
    throw new HttpsError(
        "permission-denied", "Only admins can record payments.",
    );
  }
  const data = request.data || {};
  const invoiceId = String(data.invoiceId || "").trim();
  const method = data.method === "transfer" ? "transfer" : "cash";
  const note = String(data.note || "").trim().slice(0, 200);
  if (!invoiceId) {
    throw new HttpsError("invalid-argument", "invoiceId is required.");
  }

  const invoiceRef = db.collection(INVOICES).doc(invoiceId);
  const {termValidDays} = await loadPricing();
  let credited = null;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(invoiceRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Invoice not found.");
    }
    const invoice = snap.data() || {};
    if (invoice.status && invoice.status !== "pending") {
      throw new HttpsError(
          "failed-precondition",
          `This invoice is already ${invoice.status}.`,
      );
    }
    tx.update(invoiceRef, {
      status: "paid",
      paidAt: FieldValue.serverTimestamp(),
      paymentMethod: method,
      paidBy: auth.uid,
      ...(note ? {note} : {}),
    });
    credited = creditPaidInvoice(
        tx, invoiceRef, {...invoice, paymentMethod: method}, termValidDays,
    );
  });

  if (credited) {
    await notifyInvoicePaid(credited.invoice, credited.packageSize);
    await writeAudit({
      action: "invoice.paid",
      actorId: auth.uid,
      actorName: caller.name || caller.nameIndonesian || "Admin",
      targetType: "invoice",
      targetId: invoiceId,
      detail: `${paidAuditDetail(credited, invoiceId)} (${method})`,
    });
  }
  return {ok: true};
});

function midtransStatusToInvoice(transactionStatus, fraudStatus) {
  if (
    transactionStatus === "settlement" ||
    (transactionStatus === "capture" && fraudStatus !== "challenge")
  ) {
    return "paid";
  }
  if (transactionStatus === "expire") return "expired";
  if (
    transactionStatus === "deny" ||
    transactionStatus === "cancel" ||
    transactionStatus === "failure"
  ) {
    return "failed";
  }
  return null; // pending / challenge — leave as-is
}

/**
 * Midtrans notification webhook. Verifies the signature, maps the transaction
 * status, and on "paid" credits sessions to student_class_terms + notifies.
 * Idempotent: repeat notifications for an already-final invoice are ignored.
 *
 * Register this URL in the Midtrans dashboard after deploy.
 */
exports.midtransNotification = onRequest(
  {secrets: [MIDTRANS_SERVER_KEY]},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const body = req.body || {};
    const orderId = body.order_id;
    const statusCode = body.status_code;
    const grossAmount = body.gross_amount;
    const signatureKey = body.signature_key;

    if (!orderId || !statusCode || !grossAmount || !signatureKey) {
      res.status(400).send("Missing fields");
      return;
    }

    const serverKey = MIDTRANS_SERVER_KEY.value();
    const expected = crypto
      .createHash("sha512")
      .update(`${orderId}${statusCode}${grossAmount}${serverKey}`)
      .digest("hex");

    if (expected !== signatureKey) {
      logger.warn("midtransNotification: bad signature", {orderId});
      res.status(403).send("Invalid signature");
      return;
    }

    const newStatus = midtransStatusToInvoice(
      body.transaction_status,
      body.fraud_status,
    );
    if (!newStatus) {
      res.status(200).send("OK (no status change)");
      return;
    }

    const query = await db
      .collection(INVOICES)
      .where("midtransOrderId", "==", orderId)
      .limit(1)
      .get();
    if (query.empty) {
      logger.warn("midtransNotification: unknown order", {orderId});
      res.status(200).send("OK (unknown order)");
      return;
    }

    const invoiceRef = query.docs[0].ref;

    // Flip pending -> final AND (on paid) create the session package in ONE
    // atomic transaction. This prevents both double-crediting (a duplicate /
    // concurrent notification hits the idempotency guard) and paid-but-
    // uncredited invoices (a transient failure after marking paid). Only the
    // transaction that performs the flip returns the payload to notify.
    let credited = null;
    const {termValidDays} = await loadPricing();
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(invoiceRef);
      const invoice = snap.data() || {};
      // Idempotent — don't reprocess a final invoice.
      if (invoice.status && invoice.status !== "pending") return;
      tx.update(invoiceRef, {
        status: newStatus,
        ...(newStatus === "paid" ? {paidAt: FieldValue.serverTimestamp()} : {}),
      });
      if (newStatus !== "paid") return;
      credited = creditPaidInvoice(tx, invoiceRef, invoice, termValidDays);
    });

    if (credited) {
      // Best-effort — the sessions are already credited atomically above.
      await notifyInvoicePaid(credited.invoice, credited.packageSize);
      await writeAudit({
        action: "invoice.paid",
        actorId: "system",
        actorName: "Midtrans",
        targetType: "invoice",
        targetId: invoiceRef.id,
        detail: paidAuditDetail(credited, orderId),
      });
    }

    res.status(200).send("OK");
  },
);

/**
 * Notify the student + teacher that a payment landed. Best-effort only — the
 * session package is already credited atomically in the webhook transaction, so
 * a notification failure must never affect crediting.
 */
async function notifyInvoicePaid(invoice, packageSize) {
  try {
    const now = FieldValue.serverTimestamp();
    const batch = db.batch();
    const isBook = packageSize === 0;
    batch.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "session",
      title: "Payment received",
      body: isBook ?
        `Your payment for ${BOOK_DESCRIPTION} was received.` :
        `${packageSize} sessions have been added to your account.`,
      forRole: "student",
      userId: invoice.studentId,
      targetRoute: "/student",
      read: false,
      createdAt: now,
    });
    if (invoice.teacherId) {
      batch.set(db.collection(NOTIFICATIONS).doc(), {
        kind: "session",
        title: "Invoice paid",
        body: isBook ?
          `${invoice.studentName || "A student"} paid for ${BOOK_DESCRIPTION}.` :
          `${invoice.studentName || "A student"} paid for a ${packageSize}-session package.`,
        forRole: "teacher",
        userId: invoice.teacherId,
        targetRoute: "/teacher",
        read: false,
        createdAt: now,
      });
    }
    await batch.commit();
  } catch (err) {
    logger.error("notifyInvoicePaid failed", err);
  }
}

/**
 * Nightly Firestore export to the backup bucket (docs/NAS_BACKUP_SETUP.md).
 * The NAS pulls that bucket with rclone at ~03:00; keep this schedule earlier.
 * Requires the runtime SA to have datastore.importExportAdmin and storage.admin
 * on gs://chinese-tracker-backups (IAM commands are in the setup doc).
 */
const {v1: firestoreAdminV1} = require("@google-cloud/firestore");
const exportClient = new firestoreAdminV1.FirestoreAdminClient();

// ---------------------------------------------------------------------------
// Bank-based exercises ("packages"): the answer keys never reach the student.
// A package names worksheets (`bankSheets`) and single questions
// (`bankQuestionIds`) in `question_bank`; the student receives the questions
// without answers from startExercise, each answer is checked by
// checkExerciseAnswer, and finishExercise writes the result. Students cannot
// read `question_bank` themselves (rules: staff only).
// ---------------------------------------------------------------------------

/** Loads the signed-in caller's profile or throws. */
async function requireCaller(request) {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const snap = await db.collection(USERS).doc(auth.uid).get();
  const profile = snap.exists ? snap.data() || {} : null;
  if (!profile || profile.active === false) {
    throw new HttpsError("permission-denied", "This account is not active.");
  }
  return {uid: auth.uid, profile};
}

/** The published package exercise the student is assigned to, or throws. */
async function loadAssignedPackage(exerciseId, studentId) {
  if (!exerciseId) {
    throw new HttpsError("invalid-argument", "exerciseId is required.");
  }
  const exSnap = await db.collection(EXERCISES).doc(exerciseId).get();
  if (!exSnap.exists) throw new HttpsError("not-found", "Exercise not found.");
  const exercise = exSnap.data() || {};
  if (exercise.isPublished === false) {
    throw new HttpsError("failed-precondition", "This exercise is not published.");
  }
  const assignment = await db.collection(EXERCISE_ASSIGNMENTS)
      .doc(`${exerciseId}_${studentId}`).get();
  if (!assignment.exists) {
    throw new HttpsError(
        "permission-denied", "This exercise is not assigned to you.",
    );
  }
  return exercise;
}

/** Bank items of a package, ordered as the package lists them. */
async function loadPackageItems(exercise) {
  const sheets = Array.isArray(exercise.bankSheets) ?
    exercise.bankSheets.map(String) : [];
  const ids = Array.isArray(exercise.bankQuestionIds) ?
    exercise.bankQuestionIds.map(String) : [];
  const byId = new Map();
  const add = (doc) => {
    if (!doc.exists) return;
    const data = doc.data() || {};
    const created = data.createdAt && typeof data.createdAt.toMillis === "function" ?
      data.createdAt.toMillis() : 0;
    byId.set(doc.id, {id: doc.id, ...data, createdAtMillis: created});
  };
  const bank = db.collection(QUESTION_BANK);
  for (let i = 0; i < sheets.length; i += 30) {
    const chunk = sheets.slice(i, i + 30);
    const [byCode, byTag] = await Promise.all([
      bank.where("sheetCode", "in", chunk).get(),
      // Questions imported before `sheetCode` existed carry the code as a tag.
      bank.where("tags", "array-contains-any", chunk).get(),
    ]);
    byCode.docs.forEach(add);
    byTag.docs.forEach(add);
  }
  if (ids.length) {
    const snaps = await db.getAll(...ids.map((id) => bank.doc(id)));
    snaps.forEach(add);
  }
  return play.orderPackageItems([...byId.values()], sheets, ids);
}

exports.startExercise = onCall(async (request) => {
  const {uid} = await requireCaller(request);
  const exerciseId = String((request.data || {}).exerciseId || "").trim();
  const exercise = await loadAssignedPackage(exerciseId, uid);
  const items = await loadPackageItems(exercise);
  return {
    exerciseId,
    title: exercise.title || "",
    instructions: exercise.instructions || "",
    questions: items.map(play.stripQuestion),
  };
});

exports.checkExerciseAnswer = onCall(async (request) => {
  const {uid} = await requireCaller(request);
  const data = request.data || {};
  const exerciseId = String(data.exerciseId || "").trim();
  const questionId = String(data.questionId || "").trim();
  if (!questionId) {
    throw new HttpsError("invalid-argument", "questionId is required.");
  }
  const exercise = await loadAssignedPackage(exerciseId, uid);
  const items = await loadPackageItems(exercise);
  const item = items.find((it) => it.id === questionId);
  if (!item) {
    throw new HttpsError("not-found", "This question is not in the exercise.");
  }
  return play.checkAnswer(item, data.answer || {});
});

exports.finishExercise = onCall(async (request) => {
  const {uid} = await requireCaller(request);
  const data = request.data || {};
  const exerciseId = String(data.exerciseId || "").trim();
  const exercise = await loadAssignedPackage(exerciseId, uid);
  const items = await loadPackageItems(exercise);
  const answers = data.answers && typeof data.answers === "object" ?
    data.answers : {};
  const result = play.scoreAttempt(items, answers);
  await db.collection(EXERCISE_RESULTS).add({
    studentId: uid,
    exerciseId,
    score: result.score,
    correct: result.correct,
    total: result.total,
    scoredBy: "server",
    submittedAt: FieldValue.serverTimestamp(),
  });
  return result;
});

/**
 * Admin removes an account for good: the Auth login, the profile, the
 * student's progress and assignments. Exercise results, invoices and
 * attendance stay (they are the centre's records). Admins cannot delete
 * themselves.
 */
exports.deleteUserAccount = onCall(async (request) => {
  const {uid: callerUid, profile: caller} = await requireCaller(request);
  if (caller.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can delete accounts.");
  }
  const targetUid = String((request.data || {}).uid || "").trim();
  if (!targetUid) throw new HttpsError("invalid-argument", "uid is required.");
  if (targetUid === callerUid) {
    throw new HttpsError("failed-precondition", "You cannot delete your own account.");
  }
  const targetSnap = await db.collection(USERS).doc(targetUid).get();
  const target = targetSnap.exists ? targetSnap.data() || {} : {};

  try {
    await getAuth().deleteUser(targetUid);
  } catch (err) {
    if (err && err.code !== "auth/user-not-found") throw err;
  }

  const batch = db.batch();
  batch.delete(db.collection(USERS).doc(targetUid));
  batch.delete(db.collection(STUDENT_PROGRESS).doc(targetUid));
  const assignments = await db.collection(EXERCISE_ASSIGNMENTS)
      .where("studentId", "==", targetUid).limit(400).get();
  assignments.docs.forEach((d) => batch.delete(d.ref));
  if (target.role === "teacher") {
    const codes = await db.collection(LINK_CODES)
        .where("teacherId", "==", targetUid).limit(50).get();
    codes.docs.forEach((d) => batch.delete(d.ref));
  }
  batch.set(db.collection(AUDIT_LOGS).doc(), {
    action: "user.delete",
    actorId: callerUid,
    targetId: targetUid,
    targetEmail: target.email || null,
    targetRole: target.role || null,
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  logger.info("deleteUserAccount", {by: callerUid, target: targetUid});
  return {deleted: true};
});

exports.scheduledFirestoreExport = onSchedule(
  {schedule: "every day 02:00", timeZone: "Asia/Jakarta"},
  async () => {
    const projectId = process.env.GCLOUD_PROJECT;
    const name = exportClient.databasePath(projectId, "(default)");
    const day = new Date().toISOString().slice(0, 10);
    await exportClient.exportDocuments({
      name,
      outputUriPrefix: `gs://chinese-tracker-backups/firestore/${day}`,
      collectionIds: [], // empty = all collections
    });
    return null;
  },
);
