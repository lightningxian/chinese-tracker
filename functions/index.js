const crypto = require("crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

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

// Midtrans Server Key lives ONLY here (never in the Flutter app or git).
// Set with: firebase functions:secrets:set MIDTRANS_SERVER_KEY
const MIDTRANS_SERVER_KEY = defineSecret("MIDTRANS_SERVER_KEY");

// Sandbox by default. Point at production only when going live.
const MIDTRANS_SNAP_URL =
  "https://app.sandbox.midtrans.com/snap/v1/transactions";

const ALLOWED_PACKAGE_SIZES = [8, 16];
const TERM_VALID_DAYS = 90;

// Authoritative price table (whole IDR) keyed by package size. The invoice
// amount is derived from this server-side — the client value is ignored so a
// caller can never set an arbitrary price. Keep in sync with the sizes above
// and AppConstants.packagePricesIdr in the app (display only).
const PACKAGE_PRICES = {
  8: 800000,
  16: 1500000,
};

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
    targetRoute: "/admin",
    read: false,
    createdAt: now,
  });

  const teacherNotification = {
    kind: "registration",
    title: "New student registered",
    body: `${studentName} joined your centre.`,
    forRole: "teacher",
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
    const packageSize = Number(data.packageSize);
    const dueDate = String(data.dueDate || "").trim();

    if (!studentId) {
      throw new HttpsError("invalid-argument", "studentId is required.");
    }
    if (!ALLOWED_PACKAGE_SIZES.includes(packageSize)) {
      throw new HttpsError(
        "invalid-argument",
        `packageSize must be one of ${ALLOWED_PACKAGE_SIZES.join(", ")}.`,
      );
    }

    // Amount is authoritative on the server — derive from the price table and
    // ignore any client-supplied value so a caller can't misprice a sale.
    const amount = PACKAGE_PRICES[packageSize];
    if (!Number.isInteger(amount) || amount <= 0) {
      throw new HttpsError(
        "failed-precondition",
        `No price configured for package size ${packageSize}.`,
      );
    }

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
      packageSize,
      amount,
      currency: "IDR",
      status: "pending",
      dueDate,
      midtransOrderId: orderId,
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
              id: `pkg-${packageSize}`,
              price: amount,
              quantity: 1,
              name: `${packageSize} session package`,
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
        `${orderId} · ${packageSize} sessions · Rp ${amount} for ${studentName}`,
    });

    return {invoiceId: invoiceRef.id, snapToken, redirectUrl};
  },
);

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

      const packageSize = Number(invoice.packageSize) || 0;
      if (!invoice.studentId || !ALLOWED_PACKAGE_SIZES.includes(packageSize)) {
        logger.warn("midtransNotification: paid invoice with invalid package", {
          orderId,
        });
        return;
      }
      const now = new Date();
      const deadline = new Date(now.getTime() + TERM_VALID_DAYS * 86400000);
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
        createdBy: "midtrans",
        purchasedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      });
      credited = {invoice, packageSize};
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
        detail:
          `${orderId} · Rp ${credited.invoice.amount || 0} · ` +
          `${credited.packageSize} sessions credited to ` +
          `${credited.invoice.studentName || credited.invoice.studentId}`,
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
    batch.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "session",
      title: "Payment received",
      body: `${packageSize} sessions have been added to your account.`,
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
        body: `${invoice.studentName || "A student"} paid for a ${packageSize}-session package.`,
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
