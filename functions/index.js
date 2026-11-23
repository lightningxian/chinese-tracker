const crypto = require("crypto");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const play = require("./exercise_play");
const reminders = require("./reminders");

initializeApp();
const db = getFirestore();

const LINK_CODES = "teacher_link_codes";
const USERS = "users";
const NOTIFICATIONS = "notifications";
const EXERCISE_RESULTS = "exercise_results";
const EXERCISE_ATTEMPTS = "exercise_attempts";
const RATE_LIMITS = "rate_limits";
const EXERCISES = "exercises";
const INVOICES = "invoices";
const CLASS_TERMS = "student_class_terms";
const AUDIT_LOGS = "audit_logs";
const QUESTION_BANK = "question_bank";
const EXERCISE_ASSIGNMENTS = "exercise_assignments";
const STUDENT_PROGRESS = "student_progress";
const PUSH_TOKENS = "push_tokens";
const APP_URL = "https://chinese-tracker.web.app";

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
  {id: "registration", name: "Registration (one-time)", nameChinese: "报名费",
    price: 100000, kind: "registration", sessions: 0, validDays: 0},
  {id: "package8", name: "8 class sessions", nameChinese: "8次课程", price: 2450000,
    kind: "sessions", sessions: 8, validDays: 60},
  {id: "package16", name: "16 class sessions", nameChinese: "16次课程", price: 3950000,
    kind: "sessions", sessions: 16, validDays: 60},
  {id: "book", name: "HSK materials & book", nameChinese: "HSK教材费", price: 250000,
    kind: "book", sessions: 0, validDays: 0},
];
const DEFAULT_TERM_VALID_DAYS = 60;
const SETTINGS = "settings";
// Build 5: the voucher ledger (purchase and expiry entries).
const VOUCHER_HISTORY = "voucher_history";
const payments = require("./payments");

async function loadPricing() {
  const snap = await db.collection(SETTINGS).doc("pricing").get();
  const data = snap.exists ? snap.data() || {} : {};
  const positiveInt = (v, fallback) =>
    Number.isInteger(Number(v)) && Number(v) > 0 ? Number(v) : fallback;
  let items = Array.isArray(data.items) ?
    data.items
        .filter((it) => it && it.id && positiveInt(it.price, 0) > 0)
        .map((it) => payments.cleanPriceItem(it)) :
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
  await throttle(request, "link", 30, 10 * 60 * 1000);
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

  // Build 3: a self-registered student waits on the admin's Approval list;
  // their teacher hears about them when the admin approves.
  if (user.status === "pending") {
    batch.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "registration",
      title: "Registration waiting for approval",
      body: `${studentName} registered and is waiting for approval.`,
      forRole: "admin",
      userId: "",
      targetRoute: "/admin/users/approval",
      read: false,
      createdAt: now,
    });
    await batch.commit();
    return;
  }

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
    // Build 2A: some answers wait for a teacher; the score is not final yet.
    const pending = result.status === "pending_marking";

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
      body: pending ?
        `${studentName} finished ${exerciseTitle}; answers wait for your marking.` :
        `${studentName} scored ${score}% on ${exerciseTitle}.`,
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
      title: pending ? "Waiting for marking" : "Score recorded",
      body: pending ?
        `Your teacher will mark some answers of ${exerciseTitle}.` :
        `You scored ${score}% on ${exerciseTitle}.`,
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
/**
 * Push every notification addressed to one user (`userId` set) to the
 * devices that opted in on the profile tab (`push_tokens`, uid == userId).
 * Broadcasts (`userId === ""`, e.g. "new student registered" for all
 * admins) are not pushed yet: that needs a per-role token lookup and a cap,
 * and the in-app bell already shows them. Dead tokens are deleted.
 */
exports.onNotificationCreated = onDocumentCreated(
  `${NOTIFICATIONS}/{notificationId}`,
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const n = snap.data() || {};
    const uid = typeof n.userId === "string" ? n.userId : "";
    if (!uid) return;

    const tokensSnap = await db.collection(PUSH_TOKENS)
        .where("uid", "==", uid).limit(50).get();
    if (tokensSnap.empty) return;
    const tokens = tokensSnap.docs.map((d) => d.id);
    const route = typeof n.targetRoute === "string" && n.targetRoute.startsWith("/") ?
      n.targetRoute : "/";
    const link = `${APP_URL}${route}`;

    let result;
    try {
      result = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: String(n.title || "Easy Study"),
          body: String(n.body || ""),
        },
        data: {
          kind: String(n.kind || ""),
          link,
          notificationId: event.params.notificationId,
        },
        webpush: {fcmOptions: {link}},
      });
    } catch (err) {
      logger.warn("onNotificationCreated: send failed", err);
      return;
    }

    const dead = new Set([
      "messaging/registration-token-not-registered",
      "messaging/invalid-registration-token",
      "messaging/invalid-argument",
    ]);
    const batch = db.batch();
    let removed = 0;
    result.responses.forEach((r, i) => {
      if (!r.success && r.error && dead.has(r.error.code)) {
        batch.delete(tokensSnap.docs[i].ref);
        removed++;
      }
    });
    if (removed) await batch.commit();
    logger.info(
        `onNotificationCreated: ${result.successCount} sent, ` +
        `${result.failureCount} failed, ${removed} tokens removed`,
    );
  },
);

/**
 * 07:00 Jakarta: one reminder per assignment that is due within the next
 * 24 hours and has no result yet. The reminder is a `notifications` doc
 * (so it shows in the bell too); onNotificationCreated pushes it. The
 * assignment remembers the day it was reminded (`reminderSentOn`) so a
 * re-run never sends twice.
 */
exports.dailyReminders = onSchedule(
  {schedule: "every day 07:00", timeZone: "Asia/Jakarta", timeoutSeconds: 540},
  async () => {
    try {
      await assignmentReminders();
    } catch (err) {
      logger.error("dailyReminders: reminders", err);
    }
    // Build 4: every student's progress summary and the warning notices.
    await dailyProgressPass();
  },
);

/** "Due today" reminders of assignments (the job's first half). */
async function assignmentReminders() {
  {
    const now = Date.now();
    const windowMs = 24 * 60 * 60 * 1000;
    const todayKey = reminders.jakartaDateKey(now);
    const snap = await db.collection(EXERCISE_ASSIGNMENTS)
        .where("dueDate", ">=", Timestamp.fromMillis(now))
        .where("dueDate", "<=", Timestamp.fromMillis(now + windowMs))
        .limit(500)
        .get();
    const candidates = reminders.dueSoon(
        snap.docs.map((d) => {
          const a = d.data() || {};
          return {
            id: d.id,
            ref: d.ref,
            studentId: String(a.studentId || ""),
            exerciseId: String(a.exerciseId || ""),
            dueMillis: a.dueDate && typeof a.dueDate.toMillis === "function" ?
              a.dueDate.toMillis() : NaN,
            reminderSentOn: a.reminderSentOn,
          };
        }),
        now, windowMs, todayKey,
    );
    if (!candidates.length) {
      logger.info("dailyReminders: nothing due");
      return;
    }

    const titles = new Map();
    let sent = 0;
    const batch = db.batch();
    for (const a of candidates) {
      if (!a.studentId || !a.exerciseId) continue;
      const done = await db.collection(EXERCISE_RESULTS)
          .where("studentId", "==", a.studentId)
          .where("exerciseId", "==", a.exerciseId)
          .limit(1).get();
      if (!done.empty) continue;
      if (!titles.has(a.exerciseId)) {
        const ex = await db.collection(EXERCISES).doc(a.exerciseId).get();
        titles.set(a.exerciseId, ex.exists ? (ex.data() || {}).title || "" : "");
      }
      const text = reminders.reminderText(titles.get(a.exerciseId), a.dueMillis, now);
      batch.set(db.collection(NOTIFICATIONS).doc(), {
        kind: "reminder",
        title: text.title,
        body: text.body,
        forRole: "student",
        userId: a.studentId,
        targetRoute: "/student",
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      batch.update(a.ref, {reminderSentOn: todayKey});
      sent++;
      if (sent >= 200) break; // batch limit headroom; the rest tomorrow
    }
    if (sent) await batch.commit();
    logger.info(`dailyReminders: ${sent} reminders written`);
  }
}

exports.cleanupExpiredLinkCodes = onSchedule("every 60 minutes", async () => {
  const now = Timestamp.now();
  const snap = await db
    .collection(LINK_CODES)
    .where("expiresAt", "<", now)
    .limit(500)
    .get();

  const stale = await db
    .collection(RATE_LIMITS)
    .where("updatedAt", "<", Timestamp.fromMillis(Date.now() - 86400000))
    .limit(400)
    .get();

  if (snap.empty && stale.empty) {
    logger.info("cleanupExpiredLinkCodes: nothing to delete");
    return;
  }

  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  stale.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  logger.info(
      `cleanupExpiredLinkCodes: deleted ${snap.size} codes, ` +
      `${stale.size} rate-limit counters`,
  );
});

/**
 * Resolve a student's parent-access code to that student (+ their teacher).
 *
 * Mirrors resolveLinkCode: runs with admin privileges so it works during
 * parent email/password registration (before the parent has an auth account),
 * and so the `users` collection stays closed to code enumeration.
 */
exports.resolveChildCode = onCall(async (request) => {
  await throttle(request, "child", 30, 10 * 60 * 1000);
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
  const callerData = callerSnap.data() || {};
  if (!callerSnap.exists || callerData.role !== "parent" ||
      callerData.active === false) {
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
  const caller = callerSnap.data() || {};
  const update = {studentIds: FieldValue.arrayUnion(child.id)};
  if (childData.teacherId) {
    update.teacherIds = FieldValue.arrayUnion(childData.teacherId);
  }
  // The student's app shows "payments handled by <parent>" from these two
  // fields; the parent's own access still comes from studentIds above.
  const batch = db.batch();
  batch.update(callerRef, update);
  batch.update(child.ref, {
    linkedParentUid: auth.uid,
    linkedParentName: caller.nameIndonesian || caller.name || "",
  });
  await batch.commit();

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

    // Build 5: a student buys for themself, a linked parent for the child;
    // staff invoice as before. Pending students are refused here.
    const {profile: caller} = await requireCaller(request);
    const callerRole = (caller && caller.role) || "";

    const data = request.data || {};
    const studentId = String(data.studentId || "").trim() ||
      (callerRole === "student" ? auth.uid : "");
    const dueDate = String(data.dueDate || "").trim();
    const classTermId = String(data.classTermId || "").trim() || null;

    if (!studentId) {
      throw new HttpsError("invalid-argument", "studentId is required.");
    }
    const buyer = payments.buyerRole(caller, auth.uid, studentId);
    if (!buyer) {
      throw new HttpsError("permission-denied",
          "You can only buy for yourself or your own child.", {reason: "not-yours"});
    }
    const selfPurchase = buyer !== "staff";
    if (selfPurchase && data.acceptedTerms !== true) {
      throw new HttpsError("failed-precondition", "Tick the terms first.",
          {reason: "terms"});
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
    // Self-purchases are session packages that are switched on.
    if (selfPurchase && (priceItem.kind !== "sessions" || priceItem.active === false)) {
      throw new HttpsError("failed-precondition", "That package cannot be bought here.",
          {reason: "not-buyable"});
    }
    // Follow-up 2026-11-23: the buyer may pick a class day (an active
    // weekly schedule); the voucher gets it when the payment settles.
    const classDay = String(data.classDay || "").trim();
    let classDayLabel = "";
    if (classDay) {
      const sch = await db.collection("schedules").doc(classDay.replace(/\//g, "_")).get();
      const sd = sch.exists ? sch.data() || {} : null;
      if (!sd || sd.active === false) {
        throw new HttpsError("invalid-argument", "That class day is not on the timetable.",
            {reason: "class-day"});
      }
      classDayLabel = `${sched.WEEKDAY_NAMES[sd.weekday] || ""} ` +
        `${sched.clock(sd.startMinutes)}–${sched.clock(sd.endMinutes)} · ${sd.className || ""}`;
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

    // One open self-purchase at a time: a second Buy reuses its payment link.
    if (selfPurchase) {
      const open = await db.collection(INVOICES)
          .where("studentId", "==", studentId).where("status", "==", "pending").get();
      const mine = open.docs.find((d) => (d.data() || {}).selfPurchase === true &&
        (d.data() || {}).redirectUrl);
      if (mine) {
        const inv = mine.data() || {};
        return {invoiceId: mine.id, snapToken: inv.snapToken || null,
          redirectUrl: inv.redirectUrl || null, reused: true};
      }
    }

    // Teachers may only invoice their own students.
    if (callerRole === "teacher" && teacherId !== auth.uid) {
      throw new HttpsError(
        "permission-denied",
        "You can only invoice your own students.",
      );
    }

    // A linked voucher must be this student's (otherwise the payment would
    // mark someone else's voucher paid).
    if (classTermId) {
      const termSnap = await db.collection(CLASS_TERMS).doc(classTermId).get();
      if (!termSnap.exists || (termSnap.data() || {}).studentId !== studentId) {
        throw new HttpsError(
            "invalid-argument", "That voucher does not belong to this student.",
        );
      }
    }

    const orderId =
      `ES-INV-${Date.now()}-${crypto.randomBytes(3).toString("hex")}`;
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
      // Build 5: the voucher's Chinese name and validity travel with it.
      nameChinese: priceItem.nameChinese || "",
      validDays: priceItem.validDays || 0,
      amount,
      currency: "IDR",
      status: "pending",
      paymentMethod: "midtrans",
      dueDate,
      midtransOrderId: orderId,
      ...(classTermId ? {classTermId} : {}),
      ...(classDay ? {classDay, classDayLabel} : {}),
      createdBy: auth.uid,
      createdByRole: callerRole,
      selfPurchase,
      ...(selfPurchase ? {acceptedTerms: true, termsVersion: payments.TERMS_VERSION} : {}),
      createdAt: FieldValue.serverTimestamp(),
    });

    // Call Midtrans Snap.
    const serverKey = MIDTRANS_SERVER_KEY.value();
    const authHeader =
      "Basic " + Buffer.from(`${serverKey}:`).toString("base64");

    let snapToken = null;
    let redirectUrl = null;
    try {
      // On the emulator the flow test answers Snap with a local stub.
      const snapUrl = process.env.FUNCTIONS_EMULATOR === "true" &&
        process.env.MIDTRANS_SNAP_URL_EMULATOR ?
        process.env.MIDTRANS_SNAP_URL_EMULATOR : MIDTRANS_SNAP_URL;
      const res = await fetch(snapUrl, {
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
        `${orderId} · ${description} · Rp ${amount} for ${studentName}` +
        (selfPurchase ? ` (bought in the app by the ${buyer === "self" ? "student" : "parent"})` : ""),
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
function creditPaidInvoice(tx, invoiceRef, invoice, termValidDays, termSnap) {
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
  // The linked term was read by the caller before the first write (Firestore
  // transactions read first). A term that was deleted meanwhile, or that
  // belongs to another student, is ignored and a fresh term is created, so a
  // settled payment never fails to credit.
  if (termSnap && termSnap.exists &&
      (termSnap.data() || {}).studentId === invoice.studentId) {
    tx.update(termSnap.ref, {
      sourceInvoiceId: invoiceRef.id,
      paidAt: FieldValue.serverTimestamp(),
    });
    return {invoice, packageSize, existingTerm: true};
  }
  const start = payments.jakartaDate(Date.now());
  const validDays = Number(invoice.validDays) > 0 ? Number(invoice.validDays) : termValidDays;
  const termRef = db.collection(CLASS_TERMS).doc();
  tx.set(termRef, {
    studentId: invoice.studentId,
    packageSize,
    sessionsRemaining: packageSize,
    sessionsUsed: 0,
    // Build 6 counts bookings here.
    sessionsBooked: 0,
    status: "active",
    startDate: start,
    deadlineDate: payments.termDeadline(start, validDays),
    validDays,
    nameChinese: invoice.nameChinese || "",
    priceItemId: invoice.priceItemId || "",
    // Follow-up 2026-11-23: the class day picked in the buy sheet.
    ...(invoice.classDay ? {classDay: invoice.classDay} : {}),
    source: invoice.selfPurchase === true ? "app" :
      (invoice.paymentMethod === "midtrans" ? "midtrans" : invoice.paymentMethod || "admin"),
    sourceInvoiceId: invoiceRef.id,
    createdBy: invoice.paymentMethod === "midtrans" ? "midtrans" : "admin",
    purchasedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });
  // Build 5: the voucher ledger (one purchase entry per invoice).
  tx.set(db.collection(VOUCHER_HISTORY).doc(`${invoiceRef.id}_purchase`), {
    kind: "purchase",
    studentId: invoice.studentId,
    termId: termRef.id,
    invoiceId: invoiceRef.id,
    sessions: packageSize,
    nameChinese: invoice.nameChinese || "",
    amount: Number(invoice.amount) || 0,
    method: invoice.paymentMethod || "",
    date: FieldValue.serverTimestamp(),
  });
  return {invoice, packageSize};
}

/**
 * An invoice with its Price list row's Chinese name and validity filled in
 * (invoices made by staff before Build 5 carry neither).
 */
function withPriceItem(invoice, pricing) {
  const item = pricing.items.find((it) => it.id === invoice.priceItemId);
  if (!item) return invoice;
  return {
    ...invoice,
    nameChinese: invoice.nameChinese || item.nameChinese || "",
    validDays: Number(invoice.validDays) > 0 ? invoice.validDays : item.validDays || 0,
  };
}

/** The voucher an invoice is linked to, read inside the transaction. */
async function linkedTermSnap(tx, invoice) {
  const id = String(invoice.classTermId || "").trim();
  return id ? tx.get(db.collection(CLASS_TERMS).doc(id)) : null;
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
  const pricing = await loadPricing();
  const {termValidDays} = pricing;
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
    const termSnap = await linkedTermSnap(tx, invoice);
    tx.update(invoiceRef, {
      status: "paid",
      paidAt: FieldValue.serverTimestamp(),
      paymentMethod: method,
      paidBy: auth.uid,
      ...(note ? {note} : {}),
    });
    credited = creditPaidInvoice(
        tx, invoiceRef, withPriceItem({...invoice, paymentMethod: method}, pricing),
        termValidDays, termSnap,
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
    if (!payments.signatureOk(signatureKey, orderId, statusCode, grossAmount, serverKey)) {
      logger.warn("midtransNotification: bad signature", {orderId});
      res.status(403).send("Invalid signature");
      return;
    }

    const newStatus = payments.invoiceStatusFor(
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
    let amountMismatch = false;
    const pricing = await loadPricing();
    const {termValidDays} = pricing;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(invoiceRef);
      const invoice = snap.data() || {};
      const decision = payments.creditDecision(invoice, newStatus, grossAmount);
      // Idempotent — don't reprocess a final invoice (MT-03).
      if (decision === "ignore-final" || decision === "no-change") return;
      // A settlement for a different amount than the invoice is not
      // credited; it stays pending for the admin to look at.
      if (decision === "amount-mismatch") {
        amountMismatch = true;
        return;
      }
      const termSnap = newStatus === "paid" ?
        await linkedTermSnap(tx, invoice) : null;
      tx.update(invoiceRef, {
        status: newStatus,
        ...(newStatus === "paid" ? {paidAt: FieldValue.serverTimestamp()} : {}),
      });
      if (newStatus !== "paid") return;
      credited = creditPaidInvoice(
          tx, invoiceRef, withPriceItem(invoice, pricing), termValidDays, termSnap,
      );
    });
    if (amountMismatch) {
      logger.error("midtransNotification: amount mismatch, not credited", {
        orderId, grossAmount,
      });
      res.status(200).send("OK (amount mismatch, left pending)");
      return;
    }

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
    try {
      const s = await db.collection(USERS).doc(invoice.studentId).get();
      const parentUid = s.exists ? (s.data() || {}).linkedParentUid : "";
      if (parentUid) {
        batch.set(db.collection(NOTIFICATIONS).doc(), {
          kind: "session", title: "Payment received",
          body: isBook ? `${invoice.studentName || "Your child"}: payment received.` :
            `${packageSize} sessions were added for ${invoice.studentName || "your child"}.`,
          forRole: "parent", userId: parentUid, targetRoute: "/parent",
          read: false, createdAt: now,
        });
      }
    } catch (err) {
      logger.warn("notifyInvoicePaid: parent", err);
    }
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

// ---------------------------------------------------------------------------
// Bank-based exercises ("packages"): the answer keys never reach the student.
// A package names worksheets (`bankSheets`) and single questions
// (`bankQuestionIds`) in `question_bank`; the student receives the questions
// without answers from startExercise; finishExercise checks every answer at
// once, writes the result and returns the review (each key) for the result
// page. checkExerciseAnswer (one answer at a time) is kept for clients built
// before 2026-11-11 and is no longer called by the app. Students cannot read
// `question_bank` themselves (rules: staff only).
// ---------------------------------------------------------------------------

/** Client address behind the Cloud Run proxy, for rate limiting only. */
function clientIp(request) {
  const raw = request.rawRequest || {};
  const fwd = raw.headers && raw.headers["x-forwarded-for"];
  const first = typeof fwd === "string" ? fwd.split(",")[0].trim() : "";
  return first || raw.ip || "unknown";
}

/**
 * At most `max` calls per `windowMs` per client for `bucket` (the public
 * code resolvers, which run before sign-in and could otherwise be used to
 * guess codes). Counters live in `rate_limits` (no client access) and are
 * cleaned up by cleanupExpiredLinkCodes.
 */
async function throttle(request, bucket, max, windowMs) {
  const key = crypto.createHash("sha256")
      .update(`${bucket}:${clientIp(request)}`).digest("hex").slice(0, 24);
  const ref = db.collection(RATE_LIMITS).doc(key);
  const now = Date.now();
  const blocked = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.exists ? snap.data() || {} : {};
    const start = typeof d.windowStart === "number" ? d.windowStart : 0;
    const inWindow = now - start < windowMs;
    const count = inWindow ? Number(d.count) || 0 : 0;
    if (count >= max) return true;
    tx.set(ref, {
      bucket,
      count: count + 1,
      windowStart: inWindow ? start : now,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return false;
  });
  if (blocked) {
    throw new HttpsError(
        "resource-exhausted", "Too many attempts. Try again in a few minutes.",
    );
  }
}

/** Seconds allowed for a package, or null when it has no time limit. */
function timeLimitSeconds(exercise) {
  const minutes = Number(exercise.timeLimitMinutes);
  return Number.isFinite(minutes) && minutes > 0 ? Math.round(minutes * 60) : null;
}

/** Seconds left on an attempt's server clock, or null without a limit. */
function remainingSecondsOf(attempt, limitSeconds) {
  if (!limitSeconds) return null;
  const started = attempt.startedAt && typeof attempt.startedAt.toMillis === "function" ?
    attempt.startedAt.toMillis() : Date.now();
  return Math.max(0, limitSeconds - Math.round((Date.now() - started) / 1000));
}

/** Submitted more than three minutes after the clock ran out. */
const LATE_GRACE_SECONDS = 180;
function isLate(attempt, limitSeconds) {
  if (!limitSeconds) return false;
  const started = attempt.startedAt && typeof attempt.startedAt.toMillis === "function" ?
    attempt.startedAt.toMillis() : Date.now();
  return Date.now() > started + (limitSeconds + LATE_GRACE_SECONDS) * 1000;
}

/** Loads the signed-in caller's profile or throws. */
async function requireCaller(request) {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const snap = await db.collection(USERS).doc(auth.uid).get();
  const profile = snap.exists ? snap.data() || {} : null;
  if (!profile || profile.active === false) {
    throw new HttpsError("permission-denied", "This account is not active.");
  }
  // Build 3: a self-registered student waits for the admin's approval.
  if ((profile.role || "student") === "student" && !isApprovedStatus(profile.status)) {
    throw new HttpsError("permission-denied", "This account is waiting for approval.",
        {reason: "not-approved"});
  }
  return {uid: auth.uid, profile};
}

/** Students made before Build 3 have no `status`: they count as approved. */
function isApprovedStatus(status) {
  return status === undefined || status === null || status === "" || status === "active";
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
  const data = request.data || {};
  const exerciseId = String(data.exerciseId || "").trim();
  const exercise = await loadAssignedPackage(exerciseId, uid);
  const items = await loadPackageItems(exercise);
  const category = play.packageCategory(items);
  // Owner decision 2026-11-16: HSK simulations run only through test codes
  // (the supervised test track); exam packages stay as they are.
  if (category === "hsk_simulation") {
    throw new HttpsError("failed-precondition",
        "HSK simulations are taken in Tests: ask your teacher for a token.",
        {reason: "hsk-simulation-in-tests"});
  }
  const oneAttempt = play.isOneAttempt(category);
  const limitSeconds = timeLimitSeconds(exercise);
  const attemptRef = db.collection(EXERCISE_ATTEMPTS).doc(`${exerciseId}_${uid}`);
  const meta = {
    exerciseId,
    title: exercise.title || "",
    instructions: exercise.instructions || "",
    category,
    oneAttempt,
    timeLimitMinutes: limitSeconds ? Math.round(limitSeconds / 60) : null,
    questionCount: items.length,
  };

  // `peek`: what the player shows before the student starts (exams show a
  // start screen first, so the clock does not run while they read it).
  if (data.peek === true) {
    const snap = oneAttempt ? await attemptRef.get() : null;
    const attempt = snap && snap.exists ? snap.data() || {} : null;
    return {
      ...meta,
      started: attempt !== null,
      finished: !!(attempt && attempt.finishedAt),
      remainingSeconds: attempt ? remainingSecondsOf(attempt, limitSeconds) : null,
    };
  }

  let remainingSeconds = null;
  if (oneAttempt) {
    // One attempt: the first start writes the attempt with the server time;
    // a reload resumes the same clock; a finished attempt cannot be reopened.
    const attempt = await db.runTransaction(async (tx) => {
      const snap = await tx.get(attemptRef);
      if (snap.exists) {
        const existing = snap.data() || {};
        if (existing.finishedAt) {
          throw new HttpsError(
              "failed-precondition", "This exam allows one attempt.",
              {reason: "already-attempted"},
          );
        }
        return existing;
      }
      const fresh = {
        studentId: uid,
        exerciseId,
        category,
        startedAt: FieldValue.serverTimestamp(),
        ...(limitSeconds ? {timeLimitSeconds: limitSeconds} : {}),
      };
      tx.set(attemptRef, fresh);
      return {...fresh, startedAt: Timestamp.now()};
    });
    remainingSeconds = remainingSecondsOf(attempt, limitSeconds);
  }

  return {
    ...meta,
    questions: items.map(play.stripQuestion),
    remainingSeconds,
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
  // Never a key oracle for a one-attempt exam.
  if (play.isOneAttempt(play.packageCategory(items))) {
    throw new HttpsError(
        "permission-denied", "Exams are checked only when you submit.",
    );
  }
  const item = items.find((it) => it.id === questionId);
  if (!item) {
    throw new HttpsError("not-found", "This question is not in the exercise.");
  }
  return play.checkAnswer(item, data.answer || {});
});

exports.finishExercise = onCall(async (request) => {
  const {uid, profile} = await requireCaller(request);
  const data = request.data || {};
  const exerciseId = String(data.exerciseId || "").trim();
  const exercise = await loadAssignedPackage(exerciseId, uid);
  const items = await loadPackageItems(exercise);
  const answers = data.answers && typeof data.answers === "object" ?
    data.answers : {};
  // Type of exercise follows the first worksheet of the package.
  const category = play.packageCategory(items);
  if (category === "hsk_simulation") {
    throw new HttpsError("failed-precondition",
        "HSK simulations are taken in Tests: ask your teacher for a token.",
        {reason: "hsk-simulation-in-tests"});
  }
  const oneAttempt = play.isOneAttempt(category);
  const limitSeconds = timeLimitSeconds(exercise);

  // One attempt: close it (no second submit) and apply the server clock.
  let late = false;
  if (oneAttempt) {
    const attemptRef =
      db.collection(EXERCISE_ATTEMPTS).doc(`${exerciseId}_${uid}`);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(attemptRef);
      if (!snap.exists) {
        throw new HttpsError(
            "failed-precondition", "Start the exam first.",
            {reason: "not-started"},
        );
      }
      const attempt = snap.data() || {};
      if (attempt.finishedAt) {
        throw new HttpsError(
            "failed-precondition", "This exam allows one attempt.",
            {reason: "already-attempted"},
        );
      }
      late = isLate(attempt, limitSeconds);
      tx.update(attemptRef, {
        finishedAt: FieldValue.serverTimestamp(),
        ...(late ? {late: true} : {}),
      });
    });
  }

  const scored = play.scoreAttempt(items, answers);
  // Answers that arrive after the clock (plus grace) are not counted; the
  // review is still returned so the student sees the keys.
  const result = late ?
    {
      score: 0, correct: 0, total: scored.total, review: scored.review,
      earned: 0, possible: scored.possible, open: 0,
      points: Object.fromEntries(Object.entries(scored.points).map(
          ([id, p]) => [id, {...p, earned: 0, review: false}])),
      bySkill: Object.fromEntries(Object.entries(scored.bySkill).map(
          ([skill, b]) => [skill, {correct: 0, total: b.total}])),
    } :
    scored;
  // Seconds the student spent, as measured by the app (shown in the
  // student's exercise history; the time limit is enforced above).
  const duration = Number(data.durationSeconds);
  const durationSeconds = Number.isFinite(duration) && duration > 0 ?
    Math.min(Math.round(duration), 24 * 3600) : null;
  // Build 2A: answers a teacher must look at go to the marking queue (the
  // package's teacher and the student's teacher see them); the result
  // stays "pending_marking" until they are marked.
  const status = result.open > 0 ? "pending_marking" : "final";
  const resultRef = db.collection(EXERCISE_RESULTS).doc();
  const batch = db.batch();
  batch.set(resultRef, {
    studentId: uid,
    exerciseId,
    exerciseTitle: exercise.title || "",
    category,
    score: result.score,
    correct: result.correct,
    total: result.total,
    earned: result.earned,
    possible: result.possible,
    points: result.points,
    status,
    openMarking: result.open,
    bySkill: result.bySkill,
    ...(durationSeconds === null ? {} : {durationSeconds}),
    ...(late ? {late: true} : {}),
    scoredBy: "server",
    submittedAt: FieldValue.serverTimestamp(),
  });
  if (!late) {
    const teacherIds = marking.teacherIdsFor(exercise.teacherId, profile.teacherId);
    const queue = marking.queueItems(items, answers, result.points, {
      source: "package",
      resultId: resultRef.id,
      exerciseId,
      title: exercise.title || "",
      studentId: uid,
      studentName: latinName(profile),
      teacherIds,
      createdAt: FieldValue.serverTimestamp(),
    });
    for (const q of queue) {
      batch.set(db.collection(MARKING_ITEMS).doc(`${resultRef.id}_${q.questionId}`), q.data);
    }
  }
  await batch.commit();
  return {...result, late, status, resultId: resultRef.id};
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
  // Lesson progress is one doc per lesson with its own id.
  const progress = await db.collection(STUDENT_PROGRESS)
      .where("studentId", "==", targetUid).limit(400).get();
  progress.docs.forEach((d) => batch.delete(d.ref));
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

// Nightly backups: Firestore's own scheduled backups (daily, 7-day retention,
// created by the owner on 2026-11-13 with
// `firebase firestore:backups:schedules:create`). The former
// `scheduledFirestoreExport` function was removed the same day.

// ---------------------------------------------------------------------------
// Supervised tests (PLAN.md §3, Build 1). Admins write `test_formats` and
// `test_codes` from the app; everything below is written only here.
// A teacher opens a session for a code and shows its token; a student types
// the token and sits the test part by part, each part on its own server
// clock. Answer keys never leave the server. Pure logic: supervised_test.js.
// ---------------------------------------------------------------------------
const tests = require("./supervised_test");
const marking = require("./marking");

const TEST_CODES = "test_codes";
const TEST_SESSIONS = "test_sessions";
const TEST_ATTEMPTS = "test_attempts";
const TEST_RESULTS = "test_results";
// Build 2A: answers waiting for a teacher (functions write, staff read).
const MARKING_ITEMS = "marking_items";

/** Signed-in, active teacher or admin. */
async function requireStaff(request) {
  const caller = await requireCaller(request);
  const role = caller.profile.role;
  if (role !== "teacher" && role !== "admin") {
    throw new HttpsError("permission-denied", "Only teachers and admins can do this.");
  }
  return caller;
}

/** Signed-in, active student. */
async function requireStudent(request) {
  const caller = await requireCaller(request);
  if ((caller.profile.role || "student") !== "student") {
    throw new HttpsError("permission-denied", "Only students sit tests.");
  }
  return caller;
}

/** Latin name: nameIndonesian, falling back to name (PLAN.md §3 Names). */
function latinName(profile) {
  const v = String(profile.nameIndonesian || "").trim();
  return v || String(profile.name || "").trim();
}

function millisOf(ts) {
  return ts && typeof ts.toMillis === "function" ? ts.toMillis() : 0;
}

async function loadTestCode(codeId) {
  const id = tests.normalizeTestCode(codeId);
  if (!id) throw new HttpsError("invalid-argument", "codeId is required.");
  const snap = await db.collection(TEST_CODES).doc(id).get();
  if (!snap.exists) throw new HttpsError("not-found", "Test code not found.");
  const code = snap.data() || {};
  return {id, code, format: tests.cleanFormat(code.format)};
}

/** Worksheet items of a code, split into its parts. */
async function loadTestParts(code, format) {
  const items = await loadPackageItems({bankSheets: [String(code.sheetKey || "")]});
  return tests.splitIntoParts(items, format.parts);
}

/** What the start screen shows (no questions). */
function testFacts(codeId, code, format, partClocks, placement = false) {
  return {
    placement: placement === true || code.placement === true,
    codeId,
    code: code.code || codeId,
    family: code.family || "",
    level: code.level || "",
    levelKey: code.levelKey || "",
    releaseYear: code.releaseYear || null,
    parts: format.parts.map((p) => ({
      skill: p.skill, minutes: p.minutes, questions: p.questions, maxScore: p.maxScore,
    })),
    passMark: format.passMark,
    partClocks: partClocks !== false,
  };
}

/** The listening recording of a set of items (one per worksheet). */
function recordingOf(items) {
  const it = items.find((x) => x.sectionAudioUrl && partSkillIsListening(x));
  return it ? String(it.sectionAudioUrl) : "";
}
function partSkillIsListening(item) {
  return tests.partSkillOf(item) === "listening";
}

/**
 * The open part as the player needs it: its questions without keys, the
 * seconds left on its clock and, for listening, how far the recording is.
 * With one clock for the whole paper (`partClocks` false) the only "part"
 * is the whole paper: every question, in part order.
 */
function partPayload(split, format, attempt, nowMs) {
  const partClocks = attempt.partClocks !== false;
  const clock = tests.clockFormat(format, partClocks);
  const index = attempt.partIndex;
  const items = partClocks ? split[index] || [] : split.flat();
  const startedMs = millisOf((attempt.partStartedAt || [])[index]);
  const seconds = tests.partSeconds(clock, index);
  const part = partClocks ? format.parts[index] : null;
  const recording = !partClocks || (part && part.skill === "listening") ?
    recordingOf(items) : "";
  return {
    partIndex: index,
    partCount: clock.parts.length,
    skill: part ? part.skill : "reading",
    questions: items.map(play.stripQuestion),
    secondsLeft: tests.secondsLeft(startedMs, seconds, nowMs),
    partSeconds: seconds,
    elapsedSeconds: tests.elapsedSeconds(startedMs, nowMs),
    recordingUrl: recording,
  };
}

/** Wrong tokens per student (not per address: a class shares one Wi-Fi). */
const WRONG_TOKEN_MAX = 8;
const WRONG_TOKEN_WINDOW_MS = 10 * 60 * 1000;
function wrongTokenRef(uid) {
  const key = crypto.createHash("sha256").update(`test-token:${uid}`)
      .digest("hex").slice(0, 24);
  return db.collection(RATE_LIMITS).doc(key);
}
/**
 * Follow-up 2026-11-23: a visitor has no uid, so the visitor path checks two
 * keys: this browser tab (8 wrong tokens) and the address (40, so one
 * classroom Wi-Fi does not block the whole room after a few typos).
 */
const WRONG_TOKEN_MAX_PER_ADDRESS = 40;
async function assertNotTokenBlocked(uid, max = WRONG_TOKEN_MAX) {
  const snap = await wrongTokenRef(uid).get();
  const d = snap.exists ? snap.data() || {} : {};
  const inWindow = Date.now() - (Number(d.windowStart) || 0) < WRONG_TOKEN_WINDOW_MS;
  if (inWindow && (Number(d.count) || 0) >= max) {
    throw new HttpsError(
        "resource-exhausted", "Too many wrong tokens. Try again in a few minutes.",
        {reason: "token-blocked"},
    );
  }
}
async function recordWrongToken(uid) {
  const ref = wrongTokenRef(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.exists ? snap.data() || {} : {};
    const now = Date.now();
    const start = Number(d.windowStart) || 0;
    const inWindow = now - start < WRONG_TOKEN_WINDOW_MS;
    tx.set(ref, {
      bucket: "test-token",
      count: (inWindow ? Number(d.count) || 0 : 0) + 1,
      windowStart: inWindow ? start : now,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

/** The open session a token belongs to, or null. */
async function sessionForToken(token) {
  const snap = await db.collection(TEST_SESSIONS)
      .where("token", "==", token).where("status", "==", "open").limit(1).get();
  if (snap.empty) return null;
  return {id: snap.docs[0].id, session: snap.docs[0].data() || {}};
}

/**
 * Parts whose clock (plus grace) ran out without a submit count as empty
 * and the next part opens now (a reload after a power cut). Returns the new
 * part index and start times; `finished` when no part is left.
 */
function advanceExpiredParts(attempt, testFormat, nowMs) {
  const format = tests.clockFormat(testFormat, attempt.partClocks !== false);
  const startedAt = [...(attempt.partStartedAt || [])];
  let index = attempt.partIndex;
  let changed = false;
  while (index < format.parts.length) {
    const startedMs = millisOf(startedAt[index]);
    if (!tests.isPartLate(startedMs, tests.partSeconds(format, index),
        LATE_GRACE_SECONDS, nowMs)) {
      break;
    }
    index += 1;
    changed = true;
    if (index < format.parts.length) startedAt[index] = Timestamp.fromMillis(nowMs);
  }
  return {changed, partIndex: index, partStartedAt: startedAt,
    finished: index >= format.parts.length};
}

function partEndsAt(format, index, startedTs, partClocks) {
  const clock = tests.clockFormat(format, partClocks !== false);
  return Timestamp.fromMillis(millisOf(startedTs) + tests.partSeconds(clock, index) * 1000);
}

/**
 * Scores an attempt and writes its result (in the caller's transaction).
 * Parts never submitted count as empty.
 */
function writeTestResult(writer, {attemptId, attempt, codeId, code, format, split,
  session}) {
  const scored = tests.scoreTest(split, format, attempt.answers || {}, true);
  const nowMs = Date.now();
  // Build 2A: answers a teacher must look at (half credit, free writing)
  // go to the marking queue; the result stays pending until they are done.
  const teacherId = (session && session.openedBy) || attempt.openedBy || "";
  const context = {
    source: "test",
    resultId: attemptId,
    codeId,
    title: code.code || codeId,
    studentId: attempt.studentId,
    studentName: attempt.studentName || "",
    // The session's teacher and the student's own teacher (Build 1C Must 8).
    teacherIds: marking.teacherIdsFor(teacherId, attempt.studentTeacherId),
    createdAt: FieldValue.serverTimestamp(),
  };
  split.forEach((items, i) => {
    const partOf = Object.fromEntries(items.map((it) => [it.id, i]));
    const queue = marking.queueItems(items, (attempt.answers || {})[String(i)] || {},
        scored.parts[i].points, context, partOf);
    for (const q of queue) {
      writer.set(db.collection(MARKING_ITEMS).doc(`${attemptId}_${q.questionId}`), q.data);
    }
  });
  writer.set(db.collection(TEST_RESULTS).doc(attemptId), {
    codeId,
    code: code.code || codeId,
    family: code.family || "",
    level: code.level || "",
    levelKey: code.levelKey || "",
    releaseYear: code.releaseYear || null,
    studentId: attempt.studentId,
    studentName: attempt.studentName || "",
    studentNameChinese: attempt.studentNameChinese || "",
    sessionId: attempt.sessionId || "",
    openedBy: (session && session.openedBy) || attempt.openedBy || "",
    supervisorName: (session && session.openedByName) || attempt.supervisorName || "",
    parts: scored.parts.map(({points, ...p}) => p),
    points: tests.pointsByQuestion(scored),
    total: scored.total,
    max: scored.max,
    passMark: scored.passMark,
    passed: scored.passed,
    valid: true,
    invalidReason: "",
    status: scored.status,
    openMarking: scored.open,
    resultNumber: tests.resultNumber(attemptId, nowMs),
    leftCount: Number(attempt.leftCount) || 0,
    // Build 3: placement results stay off the board and the count.
    placement: attempt.placement === true || code.placement === true ||
      !!(session && session.placement === true),
    // Server time from start to the last submit: Build 2's leaderboard
    // breaks ties by the shorter time.
    durationSeconds: tests.durationSeconds(millisOf(attempt.startedAt), nowMs),
    finishedAt: Timestamp.fromMillis(nowMs),
    createdAt: FieldValue.serverTimestamp(),
  });
  return scored;
}

/**
 * Staff: open a supervised session for a test code (→ token, 15-minute
 * join window), or with `sessionId` give an open session a new token, which
 * also extends its join window.
 */
exports.openTestSession = onCall(async (request) => {
  const {uid, profile} = await requireStaff(request);
  const data = request.data || {};
  const sessionId = String(data.sessionId || "").trim();
  const now = Date.now();
  const joinUntil = Timestamp.fromMillis(now + tests.JOIN_WINDOW_SECONDS * 1000);

  const freshToken = async () => {
    for (let i = 0; i < 8; i++) {
      const token = tests.makeToken((max) => crypto.randomInt(max));
      if (!(await sessionForToken(token))) return token;
    }
    throw new HttpsError("unavailable", "Could not make a token. Try again.");
  };

  if (sessionId) {
    const ref = db.collection(TEST_SESSIONS).doc(sessionId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "Session not found.");
    const s = snap.data() || {};
    if (profile.role !== "admin" && s.openedBy !== uid) {
      throw new HttpsError("permission-denied", "This is another teacher's session.");
    }
    if (s.status !== "open") {
      throw new HttpsError("failed-precondition", "This session is closed.");
    }
    const token = await freshToken();
    await ref.update({token, joinUntil, tokenCount: FieldValue.increment(1)});
    return {sessionId, token, joinUntilMillis: joinUntil.toMillis()};
  }

  const {id: codeId, code, format} = await loadTestCode(data.codeId);
  if (code.active === false) {
    throw new HttpsError("failed-precondition", "This test code is not active.");
  }
  if (!format.parts.length) {
    throw new HttpsError("failed-precondition", "This test code has no parts.");
  }
  // Owner decision 2026-11-16: the teacher chooses per session. true = a
  // clock per part (as planned); false = one clock for the whole paper.
  const partClocks = data.partClocks !== false;
  // Build 3: a placement session (any code; a placement code always is one).
  const placement = data.placement === true || code.placement === true;
  const token = await freshToken();
  const ref = db.collection(TEST_SESSIONS).doc();
  await ref.set({
    codeId,
    code: code.code || codeId,
    family: code.family || "",
    level: code.level || "",
    levelKey: code.levelKey || "",
    partClocks,
    placement,
    // Visitors (no account) may join only a placement code's session.
    visitorsAllowed: code.placement === true,
    token,
    joinUntil,
    openedBy: uid,
    openedByName: latinName(profile),
    status: "open",
    tokenCount: 1,
    createdAt: FieldValue.serverTimestamp(),
  });
  await writeAudit({action: "test.session.open", actorId: uid,
    actorName: latinName(profile), targetType: "test_session", targetId: ref.id,
    detail: placement ? `${codeId} (placement)` : codeId});
  return {sessionId: ref.id, token, joinUntilMillis: joinUntil.toMillis(), placement};
});

/**
 * Student: start (or resume) a supervised test.
 * - `{token, peek: true}`: the start-screen facts only.
 * - `{token}`: joins within the join window, creates the attempt and opens
 *   part 1 (an unfinished attempt for the same code resumes instead).
 * - `{codeId}`: resumes the student's own unfinished attempt (after a
 *   reload), without a token.
 * Returns the open part's questions without keys, the seconds left in the
 * part and the elapsed seconds of the recording.
 */
exports.startTest = onCall(async (request) => {
  const {uid, profile} = await requireStudent(request);
  const data = request.data || {};
  const nowMs = Date.now();

  let codeId;
  let sessionRef = null;
  let session = null;
  if (data.codeId && !data.token) {
    codeId = tests.normalizeTestCode(data.codeId);
  } else {
    await assertNotTokenBlocked(uid);
    const token = tests.normalizeToken(data.token);
    const found = token ? await sessionForToken(token) : null;
    if (!found) {
      await recordWrongToken(uid);
      throw new HttpsError("not-found", "This token is not valid.", {reason: "bad-token"});
    }
    codeId = found.session.codeId;
    sessionRef = db.collection(TEST_SESSIONS).doc(found.id);
    session = found.session;
  }

  const {code, format} = await loadTestCode(codeId);
  const attemptId = `${codeId}_${uid}`;
  const attemptRef = db.collection(TEST_ATTEMPTS).doc(attemptId);
  const existingSnap = await attemptRef.get();
  const existing = existingSnap.exists ? existingSnap.data() || {} : null;
  if (existing && existing.finishedAt) {
    throw new HttpsError("failed-precondition", "You have already sat this test.",
        {reason: "already-attempted", codeId});
  }
  if (!existing && !session) {
    throw new HttpsError("not-found", "Type the token from your teacher.",
        {reason: "no-attempt"});
  }
  if (!existing && millisOf(session.joinUntil) < nowMs) {
    throw new HttpsError("deadline-exceeded",
        "The time to join has ended. Ask for a new token.", {reason: "join-closed"});
  }
  if (!existing && code.active === false) {
    throw new HttpsError("failed-precondition", "This test code is not active.");
  }

  const partClocks = existing ?
    existing.partClocks !== false : session.partClocks !== false;
  const placement = existing ? existing.placement === true : session.placement === true;
  const facts = testFacts(codeId, code, format, partClocks, placement);
  if (data.peek === true) {
    return {...facts, started: !!existing, finished: false};
  }

  const split = await loadTestParts(code, format);
  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(attemptRef);
    let attempt = snap.exists ? snap.data() || {} : null;
    if (attempt && attempt.finishedAt) {
      throw new HttpsError("failed-precondition", "You have already sat this test.",
          {reason: "already-attempted", codeId});
    }
    if (!attempt) {
      const startedTs = Timestamp.fromMillis(nowMs);
      attempt = {
        codeId,
        studentId: uid,
        studentName: latinName(profile),
        studentNameChinese: String(profile.nameChinese || "").trim(),
        studentTeacherId: String(profile.teacherId || "").trim(),
        sessionId: sessionRef.id,
        openedBy: session.openedBy || "",
        supervisorName: session.openedByName || "",
        partClocks,
        placement,
        partIndex: 0,
        partCount: tests.clockFormat(format, partClocks).parts.length,
        partStartedAt: [startedTs],
        partEndsAt: partEndsAt(format, 0, startedTs, partClocks),
        answers: {},
        leftCount: 0,
        events: [],
        status: "in_progress",
        startedAt: startedTs,
      };
      tx.set(attemptRef, attempt);
      return {attempt, finished: false};
    }
    const adv = advanceExpiredParts(attempt, format, nowMs);
    if (adv.finished) {
      const sSnap = attempt.sessionId ?
        await tx.get(db.collection(TEST_SESSIONS).doc(attempt.sessionId)) : null;
      const closed = {...attempt, partIndex: adv.partIndex};
      tx.update(attemptRef, {
        partIndex: adv.partIndex, partStartedAt: adv.partStartedAt,
        status: "finished", finishedAt: Timestamp.fromMillis(nowMs),
      });
      writeTestResult(tx, {attemptId, attempt: closed, codeId, code, format, split,
        session: sSnap && sSnap.exists ? sSnap.data() : null});
      return {attempt: closed, finished: true};
    }
    if (adv.changed) {
      const startedTs = adv.partStartedAt[adv.partIndex];
      tx.update(attemptRef, {
        partIndex: adv.partIndex, partStartedAt: adv.partStartedAt,
        partEndsAt: partEndsAt(format, adv.partIndex, startedTs, attempt.partClocks),
      });
      attempt = {...attempt, partIndex: adv.partIndex, partStartedAt: adv.partStartedAt};
    }
    return {attempt, finished: false};
  });

  if (out.finished) return {...facts, finished: true, resultId: attemptId};
  return {...facts, finished: false, attemptId,
    ...partPayload(split, format, out.attempt, Date.now())};
});

/**
 * Student: submit the open part. A part that is already closed is refused;
 * a submit later than the part clock plus the grace is stored as empty.
 * Opens the next part and returns it, or after the last part scores the
 * attempt and writes `test_results`.
 */
exports.submitTestPart = onCall(async (request) => {
  const {uid} = await requireStudent(request);
  const data = request.data || {};
  const {id: codeId, code, format} = await loadTestCode(data.codeId);
  const partIndex = Number(data.partIndex);
  if (!Number.isInteger(partIndex) || partIndex < 0) {
    throw new HttpsError("invalid-argument", "partIndex is required.");
  }
  const split = await loadTestParts(code, format);
  const attemptId = `${codeId}_${uid}`;
  const attemptRef = db.collection(TEST_ATTEMPTS).doc(attemptId);

  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(attemptRef);
    if (!snap.exists) {
      throw new HttpsError("failed-precondition", "Start the test first.",
          {reason: "not-started"});
    }
    const attempt = snap.data() || {};
    if (attempt.finishedAt) {
      return {finished: true};
    }
    if (partIndex !== attempt.partIndex) {
      throw new HttpsError("failed-precondition", "This part is already closed.",
          {reason: "part-closed", partIndex: attempt.partIndex});
    }
    const sSnap = attempt.sessionId ?
      await tx.get(db.collection(TEST_SESSIONS).doc(attempt.sessionId)) : null;
    const partClocks = attempt.partClocks !== false;
    const clock = tests.clockFormat(format, partClocks);
    const nowMs = Date.now();
    const startedMs = millisOf((attempt.partStartedAt || [])[partIndex]);
    const late = tests.isPartLate(startedMs, tests.partSeconds(clock, partIndex),
        LATE_GRACE_SECONDS, nowMs);
    const answers = {...(attempt.answers || {})};
    if (partClocks) {
      answers[String(partIndex)] = late ? {} :
        tests.answersForPart(split[partIndex] || [], data.answers);
    } else {
      // One clock, one submit: the answers go to the part of each question.
      split.forEach((items, i) => {
        answers[String(i)] = late ? {} : tests.answersForPart(items, data.answers);
      });
    }
    const lateParts = late ?
      [...(attempt.lateParts || []), partIndex] : attempt.lateParts || [];
    const next = partIndex + 1;
    // The teacher ended the session (Build 2A): this part is kept and the
    // attempt finishes here, no next part opens.
    if (next >= clock.parts.length || attempt.submitRequested === true) {
      const closed = {...attempt, answers, partIndex: next};
      tx.update(attemptRef, {
        answers, partIndex: next, lateParts, status: "finished",
        finishedAt: Timestamp.fromMillis(nowMs),
      });
      writeTestResult(tx, {attemptId, attempt: closed, codeId, code, format, split,
        session: sSnap && sSnap.exists ? sSnap.data() : null});
      return {finished: true};
    }
    const startedTs = Timestamp.fromMillis(nowMs);
    const partStartedAt = [...(attempt.partStartedAt || [])];
    partStartedAt[next] = startedTs;
    tx.update(attemptRef, {
      answers, partIndex: next, partStartedAt, lateParts,
      partEndsAt: partEndsAt(format, next, startedTs, partClocks),
    });
    return {finished: false, attempt: {...attempt, answers, partIndex: next, partStartedAt}};
  });

  if (out.finished) return {finished: true, resultId: attemptId};
  return {
    ...testFacts(codeId, code, format, out.attempt.partClocks, out.attempt.placement),
    finished: false,
    attemptId,
    ...partPayload(split, format, out.attempt, Date.now()),
  };
});

/** Student: "left the page" / "came back", throttled to one per 2 seconds. */
exports.reportTestEvent = onCall(async (request) => {
  const {uid} = await requireStudent(request);
  const data = request.data || {};
  const type = data.type === "back" ? "back" : "left";
  const codeId = tests.normalizeTestCode(data.codeId);
  if (!codeId) throw new HttpsError("invalid-argument", "codeId is required.");
  const ref = db.collection(TEST_ATTEMPTS).doc(`${codeId}_${uid}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return {recorded: false};
    const a = snap.data() || {};
    if (a.finishedAt) return {recorded: false};
    const now = Date.now();
    const events = Array.isArray(a.events) ? a.events : [];
    const last = events[events.length - 1];
    if (last && last.type === type && now - Number(last.at || 0) < 2000) {
      return {recorded: false};
    }
    tx.update(ref, {
      events: tests.appendEvent(events, {type, at: now, part: a.partIndex}),
      ...(type === "left" ? {leftCount: FieldValue.increment(1)} : {}),
      lastEventAt: Timestamp.fromMillis(now),
    });
    return {recorded: true};
  });
});

/**
 * Staff: end the session for everyone. Every open attempt of the session
 * is finished and scored; parts never submitted count as empty.
 */
exports.closeTestSession = onCall({timeoutSeconds: 120}, async (request) => {
  const {uid, profile} = await requireStaff(request);
  const sessionId = String((request.data || {}).sessionId || "").trim();
  if (!sessionId) throw new HttpsError("invalid-argument", "sessionId is required.");
  const sSnap = await db.collection(TEST_SESSIONS).doc(sessionId).get();
  if (!sSnap.exists) throw new HttpsError("not-found", "Session not found.");
  const session = sSnap.data() || {};
  if (profile.role !== "admin" && session.openedBy !== uid) {
    throw new HttpsError("permission-denied", "This is another teacher's session.");
  }
  return finishSession(sessionId, {actorId: uid, actorName: latinName(profile),
    waitMs: SUBMIT_WAIT_MS});
});

/** How long "End test for everyone" waits for the players to send their part. */
const SUBMIT_WAIT_MS = 15 * 1000;

/**
 * Ends a session (the button, or the hourly job for a forgotten one).
 * Build 2A: first stops new joins and asks every sitting student's player
 * to send the open part (`submitRequested` on the attempt, which the player
 * listens to), waits [waitMs], then finishes whoever is still sitting;
 * parts never sent count as empty.
 */
async function finishSession(sessionId, {actorId, actorName, waitMs}) {
  const sessionRef = db.collection(TEST_SESSIONS).doc(sessionId);
  const sSnap = await sessionRef.get();
  const session = sSnap.exists ? sSnap.data() || {} : null;
  if (!session) throw new HttpsError("not-found", "Session not found.");
  if (session.status === "closed") return {closed: true, finished: 0};
  const {id: codeId, code, format} = await loadTestCode(session.codeId);
  const split = await loadTestParts(code, format);
  await sessionRef.update({
    status: "closing", closingAt: FieldValue.serverTimestamp(),
    joinUntil: Timestamp.fromMillis(Date.now()),
  });
  const sitting = (await db.collection(TEST_ATTEMPTS)
      .where("sessionId", "==", sessionId).get()).docs
      .filter((d) => !(d.data() || {}).finishedAt);
  if (sitting.length && waitMs > 0) {
    const batch = db.batch();
    for (const d of sitting) {
      batch.update(d.ref, {submitRequested: true,
        submitRequestedAt: FieldValue.serverTimestamp()});
    }
    await batch.commit();
    await new Promise((resolve) => setTimeout(resolve, waitMs));
  }
  await sessionRef.update({
    status: "closed", closedAt: FieldValue.serverTimestamp(), closedBy: actorId,
  });
  const attempts = await db.collection(TEST_ATTEMPTS)
      .where("sessionId", "==", sessionId).get();
  // Everyone sitting at the start is finished now: by their own player
  // during the wait, or by the loop below.
  const sittingIds = new Set(sitting.map((d) => d.id));
  let byServer = 0;
  let finished = sittingIds.size;
  for (const doc of attempts.docs) {
    const did = await db.runTransaction(async (tx) => {
      const snap = await tx.get(doc.ref);
      const attempt = snap.data() || {};
      if (attempt.finishedAt) return false;
      const closed = {...attempt, partIndex: format.parts.length};
      tx.update(doc.ref, {
        partIndex: format.parts.length, status: "finished", closedBySession: true,
        finishedAt: FieldValue.serverTimestamp(),
      });
      if (attempt.visitor === true) {
        writePlacementResult(tx, {attemptId: doc.id, attempt: closed, codeId, code,
          format, split, session, resultCode: await freshResultCode()});
      } else {
        writeTestResult(tx, {attemptId: doc.id, attempt: closed, codeId, code, format,
          split, session});
      }
      return true;
    });
    if (did) {
      byServer += 1;
      if (!sittingIds.has(doc.id)) finished += 1;
    }
  }
  await writeAudit({action: "test.session.close", actorId, actorName,
    targetType: "test_session", targetId: sessionId,
    detail: `${codeId}: ${finished} attempts finished (${byServer} by the server)`});
  return {closed: true, finished, byServer};
}

/**
 * Build 2A: a session the teacher forgot to end closes itself once its last
 * possible end (join window + the paper's minutes + grace) is more than
 * 10 minutes past. Only then can the students open their review.
 */
exports.closeForgottenTestSessions = onSchedule("every 60 minutes", async () => {
  const snap = await db.collection(TEST_SESSIONS)
      .where("status", "in", ["open", "closing"]).get();
  const now = Date.now();
  let closed = 0;
  for (const doc of snap.docs) {
    const s = doc.data() || {};
    try {
      const {format} = await loadTestCode(s.codeId);
      const minutes = format.parts.reduce((sum, p) => sum + p.minutes, 0);
      const lastEnd = millisOf(s.joinUntil) +
        (minutes * 60 + LATE_GRACE_SECONDS) * 1000;
      if (now - lastEnd < 10 * 60 * 1000) continue;
      await finishSession(doc.id, {actorId: "system",
        actorName: "Hourly job", waitMs: 0});
      closed += 1;
    } catch (err) {
      logger.error(`closeForgottenTestSessions: ${doc.id}`, err);
    }
  }
  if (closed) logger.info(`closeForgottenTestSessions: closed ${closed}`);
});

/** Staff: mark a result invalid (with a reason) or valid again. */
exports.setTestResultValidity = onCall(async (request) => {
  const {uid, profile} = await requireStaff(request);
  const data = request.data || {};
  const resultId = String(data.resultId || "").trim();
  const valid = data.valid === true;
  const reason = String(data.reason || "").trim().slice(0, 500);
  if (!resultId) throw new HttpsError("invalid-argument", "resultId is required.");
  if (!valid && !reason) {
    throw new HttpsError("invalid-argument", "Give a reason.", {reason: "reason-required"});
  }
  const ref = db.collection(TEST_RESULTS).doc(resultId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Result not found.");
    const r = snap.data() || {};
    if (profile.role !== "admin" && r.openedBy !== uid) {
      throw new HttpsError("permission-denied",
          "This result is from another teacher's session.");
    }
    tx.update(ref, {
      valid,
      invalidReason: valid ? "" : reason,
      passed: tests.isPassed(r.total, r.passMark, valid),
      validityBy: uid,
      validityByName: latinName(profile),
      validityAt: FieldValue.serverTimestamp(),
    });
  });
  await writeAudit({action: valid ? "test.result.valid" : "test.result.invalid",
    actorId: uid, actorName: latinName(profile), targetType: "test_result",
    targetId: resultId, detail: reason});
  return {valid};
});

/**
 * Student: the review of their finished test as learning material (owner
 * decision 2026-11-16): every question, their answer, the key, the
 * explanation and the recordings. Refused while the session is still open
 * (others may still be sitting the same paper). There is never a retake.
 */
exports.getTestReview = onCall(async (request) => {
  const {uid} = await requireStudent(request);
  const {id: codeId, code, format} = await loadTestCode((request.data || {}).codeId);
  const attemptSnap = await db.collection(TEST_ATTEMPTS).doc(`${codeId}_${uid}`).get();
  const attempt = attemptSnap.exists ? attemptSnap.data() || {} : null;
  if (!attempt || !attempt.finishedAt) {
    throw new HttpsError("failed-precondition", "Finish the test first.",
        {reason: "not-finished"});
  }
  if (attempt.sessionId) {
    const s = await db.collection(TEST_SESSIONS).doc(attempt.sessionId).get();
    const status = s.exists ? (s.data() || {}).status : "closed";
    if (status === "open" || status === "closing") {
      throw new HttpsError("failed-precondition",
          "The review opens when your teacher ends the session.",
          {reason: "session-open"});
    }
  }
  const split = await loadTestParts(code, format);
  // The transcript of the recording (Build 1B), stored on the worksheet's
  // bank questions, which students cannot read: sent only here, after the
  // session is closed.
  const transcriptItem = split.flat().find((it) =>
    typeof it.transcript === "string" && it.transcript.trim());
  const transcript = transcriptItem ? transcriptItem.transcript.trim() : "";
  const answers = attempt.answers || {};
  // Build 2A: the teacher's marks replace the machine's points.
  const marks = {};
  const queue = await db.collection(MARKING_ITEMS)
      .where("resultId", "==", `${codeId}_${uid}`).get();
  for (const d of queue.docs) {
    const m = d.data() || {};
    marks[m.questionId] = m.status === "marked" ?
      {status: "marked", points: Number(m.mark) || 0} : {status: "open"};
  }
  const items = [];
  const recordings = {};
  split.forEach((partItems, partIndex) => {
    const given = answers[String(partIndex)] || {};
    const scored = play.scoreAttempt(partItems, given);
    const rec = format.parts[partIndex] && format.parts[partIndex].skill === "listening" ?
      recordingOf(partItems) : "";
    if (rec) recordings[String(partIndex)] = rec;
    partItems.forEach((it, i) => {
      items.push({
        partIndex,
        question: play.stripQuestion(it),
        answer: Object.prototype.hasOwnProperty.call(given, it.id) ? given[it.id] : null,
        review: {...scored.review[i], marking: marks[it.id] || null},
      });
    });
  });
  return {codeId, items, recordings, transcript};
});

// ---------------------------------------------------------------------------
// Marking (Build 2A). The scoring functions put answers a teacher must look
// at into `marking_items` (half-credit typing, free writing). A teacher
// marks them here; the result is re-scored and becomes final when nothing
// is open, and the student is told.
// ---------------------------------------------------------------------------

/** Staff: mark one queue item. `{itemId, decision}` or `{itemId, rubric}`. */
exports.markAnswer = onCall(async (request) => {
  const {uid, profile} = await requireStaff(request);
  const data = request.data || {};
  const itemId = String(data.itemId || "").trim();
  if (!itemId) throw new HttpsError("invalid-argument", "itemId is required.");
  const itemRef = db.collection(MARKING_ITEMS).doc(itemId);

  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(itemRef);
    if (!snap.exists) throw new HttpsError("not-found", "Item not found.");
    const item = snap.data() || {};
    if (profile.role !== "admin" &&
        !(Array.isArray(item.teacherIds) && item.teacherIds.includes(uid))) {
      throw new HttpsError("permission-denied", "This answer is not in your queue.");
    }
    const isTest = item.source === "test";
    const resultRef = db.collection(isTest ? TEST_RESULTS : EXERCISE_RESULTS)
        .doc(String(item.resultId || ""));
    const [resultSnap, siblings] = await Promise.all([
      tx.get(resultRef),
      tx.get(db.collection(MARKING_ITEMS).where("resultId", "==", item.resultId)),
    ]);
    if (!resultSnap.exists) throw new HttpsError("not-found", "Result not found.");
    const result = resultSnap.data() || {};
    const {points, rubric} = marking.markPoints(item, data);

    const marks = {};
    for (const d of siblings.docs) {
      const m = d.data() || {};
      if (d.id === itemId) marks[m.questionId] = points;
      else if (m.status === "marked") marks[m.questionId] = Number(m.mark) || 0;
    }
    let update;
    if (isTest) {
      const r = tests.rescore(result, marks);
      update = {parts: r.parts, total: r.total, status: r.status,
        openMarking: r.open, passed: r.passed};
    } else {
      const r = play.totalsOf(result.points || {}, marks);
      update = {score: r.score, earned: r.earned, status: r.open ? "pending_marking" : "final",
        openMarking: r.open};
    }
    tx.update(itemRef, {
      status: "marked", mark: points, rubric: rubric || null,
      decision: rubric ? "rubric" : String(data.decision || "keep"),
      markedBy: uid, markedByName: latinName(profile),
      markedAt: FieldValue.serverTimestamp(),
    });
    tx.update(resultRef, {...update, markedAt: FieldValue.serverTimestamp()});
    const becameFinal = result.status === "pending_marking" && update.status === "final";
    if (becameFinal) {
      const scoreText = isTest ? `${update.total} / ${result.max}` : `${update.score}%`;
      tx.set(db.collection(NOTIFICATIONS).doc(), {
        kind: "grading",
        title: "Marked",
        body: `Your teacher has marked ${item.title || "your answers"}: ${scoreText}.`,
        forRole: "student",
        userId: item.studentId,
        targetRoute: isTest ? "/student/tests" : "/student",
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    return {points, status: update.status, final: update.status === "final"};
  });
  return out;
});

/**
 * Admin: delete a student's attempt and result of a test code so they can
 * sit it again (a power cut, a broken device). Audit-logged.
 */
exports.resetTestAttempt = onCall(async (request) => {
  const {uid, profile} = await requireCaller(request);
  if (profile.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can reset an attempt.");
  }
  const resultId = String((request.data || {}).resultId || "").trim();
  const reason = String((request.data || {}).reason || "").trim().slice(0, 500);
  if (!resultId) throw new HttpsError("invalid-argument", "resultId is required.");
  const resultRef = db.collection(TEST_RESULTS).doc(resultId);
  const attemptRef = db.collection(TEST_ATTEMPTS).doc(resultId);
  const [resultSnap, attemptSnap, queue] = await Promise.all([
    resultRef.get(), attemptRef.get(),
    db.collection(MARKING_ITEMS).where("resultId", "==", resultId).get(),
  ]);
  if (!resultSnap.exists && !attemptSnap.exists) {
    throw new HttpsError("not-found", "Nothing to reset.");
  }
  const r = resultSnap.exists ? resultSnap.data() || {} : {};
  const batch = db.batch();
  batch.delete(resultRef);
  batch.delete(attemptRef);
  queue.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  await writeAudit({action: "test.attempt.reset", actorId: uid,
    actorName: latinName(profile), targetType: "test_result", targetId: resultId,
    detail: `${r.studentName || ""} · ${r.code || ""} · total ${r.total ?? "-"}` +
      (reason ? ` · ${reason}` : "")});
  return {reset: true};
});

// ---------------------------------------------------------------------------
// Build 2B (docs/PLAN.md §4): leaderboard per test code and the promotion
// count. One trigger on `test_results` keeps both right after every change
// (a new final result, marking that makes it final, invalid / valid again,
// an attempt reset); the pure rules live in promotion.js.
// ---------------------------------------------------------------------------
const promo = require("./promotion");
const LEADERBOARDS = "leaderboards";
const LEVEL_PROMOTIONS = "level_promotions";
// What the student's Tests tab shows: "2 of 3 codes passed" at their level.
const PROMOTION_PROGRESS = "promotion_progress";

async function promotionMinCodes() {
  const snap = await db.collection(SETTINGS).doc("promotion").get();
  const v = Number((snap.data() || {}).minCodes);
  return v >= 1 ? Math.floor(v) : promo.DEFAULT_MIN_CODES;
}

/** Writes or removes the board entry of one student on one code. */
async function syncLeaderboardEntry(codeId, uid, result) {
  if (!codeId || !uid) return;
  const codeSnap = await db.collection(TEST_CODES).doc(codeId).get();
  const code = codeSnap.exists ? codeSnap.data() || {} : {};
  const entry = result ? promo.entryOf(result, code) : null;
  const board = db.collection(LEADERBOARDS).doc(codeId);
  const ref = board.collection("entries").doc(uid);
  if (!entry) {
    await ref.delete();
    return;
  }
  const {finishedAtMs, ...rest} = entry;
  await board.set({
    codeId, code: code.code || codeId, level: code.level || "",
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  await ref.set({
    ...rest,
    finishedAt: finishedAtMs === null ? null : Timestamp.fromMillis(finishedAtMs),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

/**
 * Recounts the codes a student passed at their current level; at
 * `settings/promotion.minCodes` writes one waiting recommendation and tells
 * the admins; below it, withdraws a waiting one.
 */
async function syncPromotion(uid) {
  if (!uid) return;
  const userSnap = await db.collection(USERS).doc(uid).get();
  if (!userSnap.exists) return;
  const user = userSnap.data() || {};
  if ((user.role || "student") !== "student") return;
  const levelKey = promo.levelKeyOf(user.level);
  if (!levelKey) return;
  const [minCodes, resultsSnap] = await Promise.all([
    promotionMinCodes(),
    db.collection(TEST_RESULTS).where("studentId", "==", uid).get(),
  ]);
  const codeIds = [...new Set(resultsSnap.docs
      .map((d) => (d.data() || {}).codeId).filter(Boolean))];
  const codes = {};
  await Promise.all(codeIds.map(async (id) => {
    const s = await db.collection(TEST_CODES).doc(id).get();
    codes[id] = s.exists ? s.data() || {} : {};
  }));
  const rows = resultsSnap.docs.map((d) => {
    const result = d.data() || {};
    return {result, code: codes[result.codeId] || {}};
  });
  const state = promo.promotionState(rows, levelKey, minCodes);
  const passedCodes = state.codes.map((id) => {
    const r = rows.find((x) => x.result.codeId === id).result;
    return {codeId: id, code: r.code || id, total: Number(r.total) || 0,
      max: Number(r.max) || 0};
  });
  const ref = db.collection(LEVEL_PROMOTIONS).doc(promo.promotionId(uid, levelKey));
  // `decision` tells the student's card what happened to a recommendation
  // at this level: "" (none yet), "waiting" or "declined".
  const decision = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists ? snap.data() || {} : null;
    const status = current ? current.status : "";
    if (status === "declined") return "declined";
    if (state.reached) {
      if (status === "approved") return "";
      const fresh = !current || status === "withdrawn";
      tx.set(ref, {
        studentId: uid,
        studentName: latinName(user),
        studentNameChinese: String(user.nameChinese || "").trim(),
        fromKey: levelKey, toKey: state.next,
        fromLevel: `HSK ${levelKey}`, toLevel: `HSK ${state.next}`,
        codes: passedCodes, count: state.count, minCodes: state.minCodes,
        status: "waiting",
        ...(fresh ? {createdAt: FieldValue.serverTimestamp()} : {}),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (fresh) {
        tx.set(db.collection(NOTIFICATIONS).doc(), {
          kind: "promotion",
          title: "Promotion to check",
          body: `${latinName(user)} passed ${state.count} codes at HSK ${levelKey}: ` +
            `ready for HSK ${state.next}.`,
          forRole: "admin",
          userId: "",
          targetRoute: "/admin/tests/promotion",
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      return "waiting";
    } else if (status === "waiting") {
      tx.update(ref, {
        status: "withdrawn", codes: passedCodes, count: state.count,
        withdrawnAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    return "";
  });
  await db.collection(PROMOTION_PROGRESS).doc(uid).set({
    studentId: uid, level: `HSK ${levelKey}`, levelKey,
    group: promo.groupOf(levelKey), next: state.next ? `HSK ${state.next}` : "",
    count: state.count, minCodes: state.minCodes, codes: passedCodes, decision,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

exports.onTestResultWritten = onDocumentWritten(`${TEST_RESULTS}/{resultId}`, async (event) => {
  const before = event.data && event.data.before.exists ? event.data.before.data() : null;
  const after = event.data && event.data.after.exists ? event.data.after.data() : null;
  const r = after || before;
  if (!r) return;
  await syncLeaderboardEntry(r.codeId, r.studentId, after);
  await syncPromotion(r.studentId);
  if (after) await syncPlacement(event.params.resultId, after);
  await safeRefresh(r.studentId, "test result");
});

/**
 * Admin: approve or decline a waiting promotion. Approve moves `users.level`
 * up one level, writes `users/{uid}/level_history`, tells the student and a
 * linked parent; decline keeps the level and stores the reason. Audit log.
 */
exports.decidePromotion = onCall(async (request) => {
  const {uid, profile} = await requireCaller(request);
  if (profile.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins decide promotions.");
  }
  const data = request.data || {};
  const id = String(data.promotionId || "").trim();
  const approve = data.approve === true;
  const reason = String(data.reason || "").trim().slice(0, 500);
  if (!id) throw new HttpsError("invalid-argument", "promotionId is required.");
  if (!approve && !reason) {
    throw new HttpsError("invalid-argument", "Give a reason to decline.");
  }
  const ref = db.collection(LEVEL_PROMOTIONS).doc(id);
  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Recommendation not found.");
    const p = snap.data() || {};
    if (p.status !== "waiting") {
      throw new HttpsError("failed-precondition", "This recommendation is not waiting.",
          {reason: "not-waiting"});
    }
    const userRef = db.collection(USERS).doc(p.studentId);
    const userSnap = await tx.get(userRef);
    const user = userSnap.exists ? userSnap.data() || {} : null;
    if (!user) throw new HttpsError("not-found", "Student not found.");
    if (promo.levelKeyOf(user.level) !== p.fromKey) {
      throw new HttpsError("failed-precondition", "The student's level has changed.",
          {reason: "level-changed"});
    }
    const now = FieldValue.serverTimestamp();
    tx.update(ref, {
      status: approve ? "approved" : "declined",
      ...(approve ? {} : {declineReason: reason}),
      decidedBy: uid, decidedByName: latinName(profile), decidedAt: now, updatedAt: now,
    });
    if (!approve) {
      // The student's card stops saying "waiting for the admin".
      tx.set(db.collection(PROMOTION_PROGRESS).doc(p.studentId),
          {decision: "declined", updatedAt: now}, {merge: true});
    }
    const isPlacementKind = p.kind === "placement";
    if (approve) {
      tx.update(userRef, {level: p.toLevel, updatedAt: now,
        ...(isPlacementKind ? {placementDone: true} : {})});
      // The count starts again at the new level.
      tx.set(db.collection(PROMOTION_PROGRESS).doc(p.studentId), {
        studentId: p.studentId, level: p.toLevel, levelKey: p.toKey,
        group: promo.groupOf(p.toKey),
        next: promo.nextLevelKey(p.toKey) ? `HSK ${promo.nextLevelKey(p.toKey)}` : "",
        count: 0, minCodes: Number(p.minCodes) || promo.DEFAULT_MIN_CODES, codes: [],
        decision: "", updatedAt: now,
      });
      tx.set(userRef.collection("level_history").doc(), {
        kind: isPlacementKind ? "placement" : "promotion",
        date: now, from: p.fromLevel, to: p.toLevel,
        fromGroup: promo.groupOf(p.fromKey), toGroup: promo.groupOf(p.toKey),
        codes: p.codes || [], promotionId: id, approvedBy: uid,
      });
      const note = {
        kind: "promotion", title: isPlacementKind ? "Placement result" : "Level up",
        body: isPlacementKind ?
          `${latinName(user)} starts at ${p.toLevel} after the placement test.` :
          `Congratulations! ${latinName(user)} moves from ${p.fromLevel} to ${p.toLevel}.`,
        read: false, createdAt: now,
      };
      tx.set(db.collection(NOTIFICATIONS).doc(),
          {...note, forRole: "student", userId: p.studentId, targetRoute: "/student/tests"});
      if (user.linkedParentUid) {
        tx.set(db.collection(NOTIFICATIONS).doc(),
            {...note, forRole: "parent", userId: user.linkedParentUid, targetRoute: "/parent"});
      }
    }
    return {student: latinName(user), from: p.fromLevel, to: p.toLevel,
      studentId: p.studentId};
  });
  await writeAudit({action: (approve ? "promotion.approve" : "promotion.decline") +
      (id.endsWith("_placement") ? ".placement" : ""),
    actorId: uid, actorName: latinName(profile), targetType: "level_promotion", targetId: id,
    detail: `${out.student} · ${out.from} → ${out.to}` + (reason ? ` · ${reason}` : "")});
  if (approve) await safeRefresh(out.studentId, "promotion approved");
  return {status: approve ? "approved" : "declined", level: approve ? out.to : out.from};
});

// ---------------------------------------------------------------------------
// Build 3 (docs/PLAN.md §4): registration approval and placement tests.
// A self-registered student is `status: 'pending'` until an admin approves
// them (decideRegistration). A placement result recommends a starting level
// (level_promotions/{uid}_placement, decided on the Promotion screen). A
// visitor with no account sits a placement paper behind a teacher's token
// (startPlacement / submitPlacementPart) and gets a result code that the
// register form and the Approval card read (resolvePlacementResult).
// ---------------------------------------------------------------------------
const placement = require("./placement");
const PLACEMENT_RESULTS = "placement_results";
const HSK_LEVELS = ["HSK 1", "HSK 2", "HSK 3", "HSK 4", "HSK 5", "HSK 6"];

/** A result code no placement result uses yet. */
async function freshResultCode() {
  for (let i = 0; i < 8; i++) {
    const code = placement.makeResultCode((max) => crypto.randomInt(max));
    const taken = await db.collection(PLACEMENT_RESULTS)
        .where("resultCode", "==", code).limit(1).get();
    if (taken.empty) return code;
  }
  throw new HttpsError("unavailable", "Could not make a result code. Try again.");
}

/**
 * Scores a visitor's attempt and writes `placement_results/{attemptId}` (in
 * the caller's transaction). Never a review, never a marking queue: the
 * papers are reused. Answers a teacher would mark count as zero.
 */
function writePlacementResult(writer, {attemptId, attempt, codeId, code, format, split,
  session, resultCode}) {
  const scored = tests.scoreTest(split, format, attempt.answers || {}, true);
  const total = scored.total;
  const passed = tests.isPassed(total, scored.passMark, true);
  const nowMs = Date.now();
  const recommended = placement.recommendedKey(code.level || code.levelKey, passed);
  const doc = {
    name: attempt.visitorName || "",
    whatsapp: attempt.visitorWhatsapp || "",
    codeId,
    code: code.code || codeId,
    level: code.level || "",
    levelKey: code.levelKey || placement.levelKeyOf(code.level),
    parts: scored.parts.map(({points, ...p}) => p),
    total,
    max: scored.max,
    passMark: scored.passMark,
    passed,
    recommendedLevel: recommended ? `HSK ${recommended}` : "",
    resultCode,
    sessionId: attempt.sessionId || "",
    openedBy: (session && session.openedBy) || attempt.openedBy || "",
    supervisorName: (session && session.openedByName) || attempt.supervisorName || "",
    durationSeconds: tests.durationSeconds(millisOf(attempt.startedAt), nowMs),
    finishedAt: Timestamp.fromMillis(nowMs),
    claimedBy: "",
    createdAt: FieldValue.serverTimestamp(),
  };
  writer.set(db.collection(PLACEMENT_RESULTS).doc(attemptId), doc);
  return doc;
}

/** What the visitor's result page shows (no keys, no answers). */
function visitorResultView(r) {
  return {
    finished: true,
    level: r.level || "",
    parts: (r.parts || []).map((p) => ({skill: p.skill, mark: p.mark,
      maxScore: p.maxScore})),
    total: r.total,
    max: r.max,
    passMark: r.passMark,
    passed: r.passed === true,
    recommendedLevel: r.recommendedLevel || "",
    resultCode: r.resultCode || "",
  };
}

/** The placement code a visitor may sit, or throws. */
async function loadPlacementCode(codeId) {
  const loaded = await loadTestCode(codeId);
  if (loaded.code.placement !== true || loaded.code.active === false) {
    throw new HttpsError("failed-precondition", "This is not an open placement test.",
        {reason: "not-placement"});
  }
  if (!loaded.format.parts.length) {
    throw new HttpsError("failed-precondition", "This test code has no parts.");
  }
  return loaded;
}

/**
 * Public: the active placement codes with their level, parts, minutes and
 * question counts (the landing page's Placement test list).
 */
exports.placementMenu = onCall(async (request) => {
  await throttle(request, "placement-menu", 60, 10 * 60 * 1000);
  const snap = await db.collection(TEST_CODES).where("placement", "==", true).get();
  const out = [];
  for (const doc of snap.docs) {
    const code = doc.data() || {};
    if (code.active === false) continue;
    const format = tests.cleanFormat(code.format);
    if (!format.parts.length) continue;
    let counts = [];
    try {
      counts = (await loadTestParts(code, format)).map((items) => items.length);
    } catch (err) {
      logger.warn(`placementMenu: ${doc.id}`, err);
    }
    out.push(placement.menuEntry(doc.id, code, format, counts));
  }
  out.sort((a, b) => a.level.localeCompare(b.level) || a.code.localeCompare(b.code));
  return {codes: out};
});

/** Loads a visitor attempt and checks its key, or throws. */
async function visitorAttempt(attemptId, key) {
  const id = String(attemptId || "").trim();
  if (!id || id.includes("/")) {
    throw new HttpsError("invalid-argument", "attemptId is required.");
  }
  const ref = db.collection(TEST_ATTEMPTS).doc(id);
  const snap = await ref.get();
  const a = snap.exists ? snap.data() || {} : null;
  if (!a || a.visitor !== true || !placement.keyMatches(key, a.keyHash)) {
    throw new HttpsError("permission-denied", "This test link is not valid.",
        {reason: "bad-key"});
  }
  return {ref, attempt: a};
}

/**
 * Public (no sign-in): a visitor starts a placement test.
 * - `{token, name, whatsapp}`: the session must be an open placement session
 *   on a placement code, inside its join window. Creates the attempt and
 *   returns its id and a key (**once**; only its hash is stored), the facts
 *   and part 1.
 * - `{attemptId, key}`: resumes (a reload), or returns the result when the
 *   attempt is finished.
 */
exports.startPlacement = onCall(async (request) => {
  await throttle(request, "placement-start", 60, 10 * 60 * 1000);
  const data = request.data || {};
  const nowMs = Date.now();

  if (data.attemptId) {
    const {ref, attempt} = await visitorAttempt(data.attemptId, data.key);
    const {id: codeId, code, format} = await loadTestCode(attempt.codeId);
    if (attempt.finishedAt) {
      const r = await db.collection(PLACEMENT_RESULTS).doc(ref.id).get();
      return r.exists ? visitorResultView(r.data() || {}) : {finished: true};
    }
    const split = await loadTestParts(code, format);
    const resultCode = await freshResultCode();
    const out = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      let a = snap.data() || {};
      if (a.finishedAt) return {finished: true};
      const adv = advanceExpiredParts(a, format, nowMs);
      if (adv.finished) {
        const sSnap = await tx.get(db.collection(TEST_SESSIONS).doc(a.sessionId));
        const closed = {...a, partIndex: adv.partIndex};
        tx.update(ref, {partIndex: adv.partIndex, partStartedAt: adv.partStartedAt,
          status: "finished", finishedAt: Timestamp.fromMillis(nowMs)});
        const doc = writePlacementResult(tx, {attemptId: ref.id, attempt: closed, codeId,
          code, format, split, session: sSnap.exists ? sSnap.data() : null, resultCode});
        return {finished: true, doc};
      }
      if (adv.changed) {
        const startedTs = adv.partStartedAt[adv.partIndex];
        tx.update(ref, {partIndex: adv.partIndex, partStartedAt: adv.partStartedAt,
          partEndsAt: partEndsAt(format, adv.partIndex, startedTs, a.partClocks)});
        a = {...a, partIndex: adv.partIndex, partStartedAt: adv.partStartedAt};
      }
      return {finished: false, attempt: a};
    });
    if (out.finished) {
      if (out.doc) return visitorResultView(out.doc);
      const r = await db.collection(PLACEMENT_RESULTS).doc(ref.id).get();
      return r.exists ? visitorResultView(r.data() || {}) : {finished: true};
    }
    return {...testFacts(codeId, code, format, out.attempt.partClocks, true),
      finished: false, attemptId: ref.id,
      ...partPayload(split, format, out.attempt, Date.now())};
  }

  // A wrong token counts against this browser tab and, more loosely,
  // against the address (a visitor has no uid; a class shares one Wi-Fi).
  const ip = clientIp(request);
  const device = String(data.deviceId || "").replace(/[^A-Za-z0-9_-]/g, "").slice(0, 40);
  const who = device ? `ip:${ip}:dev:${device}` : `ip:${ip}`;
  await assertNotTokenBlocked(who);
  if (device) await assertNotTokenBlocked(`ip:${ip}`, WRONG_TOKEN_MAX_PER_ADDRESS);
  const token = tests.normalizeToken(data.token);
  const found = token ? await sessionForToken(token) : null;
  if (!found || found.session.placement !== true) {
    await recordWrongToken(who);
    if (device) await recordWrongToken(`ip:${ip}`);
    throw new HttpsError("not-found", "This token is not valid.", {reason: "bad-token"});
  }
  const session = found.session;
  if (millisOf(session.joinUntil) < nowMs) {
    throw new HttpsError("deadline-exceeded",
        "The time to join has ended. Ask for a new token.", {reason: "join-closed"});
  }
  const {id: codeId, code, format} = await loadPlacementCode(session.codeId);
  const partClocks = session.partClocks !== false;
  if (data.peek === true) {
    return {...testFacts(codeId, code, format, partClocks, true), started: false,
      finished: false};
  }
  const name = placement.cleanVisitorName(data.name);
  const whatsapp = placement.cleanWhatsapp(data.whatsapp);
  if (!name || !whatsapp) {
    throw new HttpsError("invalid-argument", "Type your name and WhatsApp number.",
        {reason: "visitor-details"});
  }
  const split = await loadTestParts(code, format);
  const key = placement.makeVisitorKey();
  const ref = db.collection(TEST_ATTEMPTS)
      .doc(`${found.id}_${crypto.randomBytes(8).toString("hex")}`);
  const startedTs = Timestamp.fromMillis(nowMs);
  const attempt = {
    codeId,
    visitor: true,
    studentId: "",
    studentName: name,
    visitorName: name,
    visitorWhatsapp: whatsapp,
    keyHash: placement.hashKey(key),
    sessionId: found.id,
    openedBy: session.openedBy || "",
    supervisorName: session.openedByName || "",
    partClocks,
    placement: true,
    partIndex: 0,
    partCount: tests.clockFormat(format, partClocks).parts.length,
    partStartedAt: [startedTs],
    partEndsAt: partEndsAt(format, 0, startedTs, partClocks),
    answers: {},
    leftCount: 0,
    events: [],
    status: "in_progress",
    startedAt: startedTs,
  };
  await ref.set(attempt);
  return {...testFacts(codeId, code, format, partClocks, true), finished: false,
    attemptId: ref.id, key, ...partPayload(split, format, attempt, Date.now())};
});

/**
 * Public: a visitor submits the open part (like submitTestPart: a closed
 * part is refused, a late one counts as empty). After the last part writes
 * `placement_results` and returns the marks and the result code.
 */
exports.submitPlacementPart = onCall(async (request) => {
  await throttle(request, "placement-submit", 300, 10 * 60 * 1000);
  const data = request.data || {};
  const {ref, attempt: first} = await visitorAttempt(data.attemptId, data.key);
  const partIndex = Number(data.partIndex);
  if (!Number.isInteger(partIndex) || partIndex < 0) {
    throw new HttpsError("invalid-argument", "partIndex is required.");
  }
  const {id: codeId, code, format} = await loadTestCode(first.codeId);
  const split = await loadTestParts(code, format);
  const resultCode = await freshResultCode();
  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const attempt = snap.data() || {};
    if (attempt.finishedAt) return {finished: true};
    if (partIndex !== attempt.partIndex) {
      throw new HttpsError("failed-precondition", "This part is already closed.",
          {reason: "part-closed", partIndex: attempt.partIndex});
    }
    const sSnap = await tx.get(db.collection(TEST_SESSIONS).doc(attempt.sessionId));
    const partClocks = attempt.partClocks !== false;
    const clock = tests.clockFormat(format, partClocks);
    const nowMs = Date.now();
    const startedMs = millisOf((attempt.partStartedAt || [])[partIndex]);
    const late = tests.isPartLate(startedMs, tests.partSeconds(clock, partIndex),
        LATE_GRACE_SECONDS, nowMs);
    const answers = {...(attempt.answers || {})};
    if (partClocks) {
      answers[String(partIndex)] = late ? {} :
        tests.answersForPart(split[partIndex] || [], data.answers);
    } else {
      split.forEach((items, i) => {
        answers[String(i)] = late ? {} : tests.answersForPart(items, data.answers);
      });
    }
    const next = partIndex + 1;
    if (next >= clock.parts.length || attempt.submitRequested === true) {
      const closed = {...attempt, answers, partIndex: next};
      tx.update(ref, {answers, partIndex: next, status: "finished",
        finishedAt: Timestamp.fromMillis(nowMs)});
      const doc = writePlacementResult(tx, {attemptId: ref.id, attempt: closed, codeId,
        code, format, split, session: sSnap.exists ? sSnap.data() : null, resultCode});
      return {finished: true, doc};
    }
    const startedTs = Timestamp.fromMillis(nowMs);
    const partStartedAt = [...(attempt.partStartedAt || [])];
    partStartedAt[next] = startedTs;
    tx.update(ref, {answers, partIndex: next, partStartedAt,
      partEndsAt: partEndsAt(format, next, startedTs, partClocks)});
    return {finished: false, attempt: {...attempt, answers, partIndex: next, partStartedAt}};
  });
  if (out.finished) {
    if (out.doc) return visitorResultView(out.doc);
    const r = await db.collection(PLACEMENT_RESULTS).doc(ref.id).get();
    return r.exists ? visitorResultView(r.data() || {}) : {finished: true};
  }
  return {...testFacts(codeId, code, format, out.attempt.partClocks, true),
    finished: false, attemptId: ref.id,
    ...partPayload(split, format, out.attempt, Date.now())};
});

/** Public: a visitor's "left the page" / "came back" (like reportTestEvent). */
exports.reportPlacementEvent = onCall(async (request) => {
  await throttle(request, "placement-event", 300, 10 * 60 * 1000);
  const data = request.data || {};
  const {ref} = await visitorAttempt(data.attemptId, data.key);
  const type = data.type === "back" ? "back" : "left";
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const a = snap.data() || {};
    if (a.finishedAt) return {recorded: false};
    const now = Date.now();
    const events = Array.isArray(a.events) ? a.events : [];
    const last = events[events.length - 1];
    if (last && last.type === type && now - Number(last.at || 0) < 2000) {
      return {recorded: false};
    }
    tx.update(ref, {
      events: tests.appendEvent(events, {type, at: now, part: a.partIndex}),
      ...(type === "left" ? {leftCount: FieldValue.increment(1)} : {}),
      lastEventAt: Timestamp.fromMillis(now),
    });
    return {recorded: true};
  });
});

/** The placement result of a result code, or null. */
async function placementResultByCode(resultCode) {
  const code = placement.normalizeResultCode(resultCode);
  if (!code) return null;
  const snap = await db.collection(PLACEMENT_RESULTS)
      .where("resultCode", "==", code).limit(1).get();
  if (snap.empty) return null;
  return {id: snap.docs[0].id, ref: snap.docs[0].ref, result: snap.docs[0].data() || {}};
}

/** What a result code shows: no name, no number. */
function placementSummary(r) {
  return {
    resultCode: r.resultCode || "",
    code: r.code || "",
    level: r.level || "",
    total: Number(r.total) || 0,
    max: Number(r.max) || 0,
    passed: r.passed === true,
    recommendedLevel: r.recommendedLevel || "",
    claimed: !!r.claimedBy,
  };
}

/**
 * Public: what the register form shows for a result code: the paper's
 * level, the mark, passed, the recommended level and whether a registered
 * student already used it.
 */
exports.resolvePlacementResult = onCall(async (request) => {
  await throttle(request, "placement-resolve", 30, 10 * 60 * 1000);
  const found = await placementResultByCode((request.data || {}).resultCode);
  if (!found) {
    throw new HttpsError("not-found", "This result code is not valid.",
        {reason: "bad-result-code"});
  }
  return placementSummary(found.result);
});

/**
 * Keeps `level_promotions/{uid}_placement` for a signed-in student's final,
 * valid placement result: passed = paper level + 1, failed = paper level,
 * nothing when that equals the current level. Tells the admins once.
 */
async function syncPlacement(resultId, result) {
  const uid = result.studentId;
  if (!uid || result.placement !== true) return;
  if ((result.status || "final") !== "final" || result.valid === false) return;
  const userSnap = await db.collection(USERS).doc(uid).get();
  if (!userSnap.exists) return;
  const user = userSnap.data() || {};
  if ((user.role || "student") !== "student") return;
  const ref = db.collection(LEVEL_PROMOTIONS).doc(`${uid}_placement`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists ? snap.data() || {} : null;
    // A decided recommendation of this result stays decided (the approve
    // changed the level, so recomputing would compare with the new one).
    if (current && current.resultId === resultId && current.status !== "waiting") return;
    const fromLevel = current && current.resultId === resultId ?
      current.fromLevel : user.level;
    const rec = placement.recommendationFor(fromLevel, result.level || result.levelKey,
        result.passed === true);
    if (!rec) {
      if (current && current.status === "waiting") {
        tx.update(ref, {status: "withdrawn", withdrawnAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp()});
      }
      return;
    }
    const fresh = !current || current.status !== "waiting";
    tx.set(ref, {
      kind: "placement",
      studentId: uid,
      studentName: latinName(user),
      studentNameChinese: String(user.nameChinese || "").trim(),
      fromKey: rec.fromKey, toKey: rec.toKey,
      fromLevel: `HSK ${rec.fromKey}`, toLevel: `HSK ${rec.toKey}`,
      resultId,
      codes: [{codeId: result.codeId || "", code: result.code || result.codeId || "",
        total: Number(result.total) || 0, max: Number(result.max) || 0}],
      paperLevel: result.level || "",
      passed: result.passed === true,
      count: 1, minCodes: 1,
      status: "waiting",
      declineReason: FieldValue.delete(),
      ...(fresh ? {createdAt: FieldValue.serverTimestamp()} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    if (fresh) {
      tx.set(db.collection(NOTIFICATIONS).doc(), {
        kind: "promotion",
        title: "Placement result to check",
        body: `${latinName(user)} sat a placement test (${result.code || result.codeId}): ` +
          `HSK ${rec.fromKey} → HSK ${rec.toKey}.`,
        forRole: "admin",
        userId: "",
        targetRoute: "/admin/tests/promotion",
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

/**
 * Admin: the placement result behind a pending student's result code (the
 * Approval card; `placement_results` is staff-readable, but the code is
 * only on the student's profile).
 */
exports.registrationPlacement = onCall(async (request) => {
  await requireStaff(request);
  const found = await placementResultByCode((request.data || {}).resultCode);
  if (!found) return {found: false};
  return {found: true, claimedBy: found.result.claimedBy || "",
    ...placementSummary(found.result)};
});

/**
 * Admin: approve or reject a pending registration (one transaction).
 * Approve sets `status: 'active'`, the level and the teacher, stamps the
 * placement result code as used, tells the student and the teacher.
 * Reject stores the reason and tells the student. A rejected account may be
 * approved later. Audit log both ways.
 */
exports.decideRegistration = onCall(async (request) => {
  const {uid, profile} = await requireCaller(request);
  if (profile.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins approve registrations.");
  }
  const minCodes = await promotionMinCodes();
  const data = request.data || {};
  const studentId = String(data.studentId || "").trim();
  const approve = data.approve === true;
  const reason = String(data.reason || "").trim().slice(0, 500);
  const level = String(data.level || "").trim();
  const teacherId = String(data.teacherId || "").trim();
  if (!studentId || studentId.includes("/")) {
    throw new HttpsError("invalid-argument", "studentId is required.");
  }
  if (!approve && !reason) {
    throw new HttpsError("invalid-argument", "Give a reason to reject.",
        {reason: "reason-required"});
  }
  if (approve && !HSK_LEVELS.includes(level)) {
    throw new HttpsError("invalid-argument", "Pick a starting level.", {reason: "level"});
  }
  if (approve && !teacherId) {
    throw new HttpsError("invalid-argument", "Pick a teacher.", {reason: "teacher"});
  }
  const userRef = db.collection(USERS).doc(studentId);
  const pre = await userRef.get();
  const pending = pre.exists ? pre.data() || {} : null;
  const found = approve && pending && pending.placementResultCode ?
    await placementResultByCode(pending.placementResultCode) : null;

  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const user = snap.exists ? snap.data() || {} : null;
    if (!user || (user.role || "student") !== "student") {
      throw new HttpsError("not-found", "Student not found.");
    }
    if (user.status !== "pending" && user.status !== "rejected") {
      throw new HttpsError("failed-precondition", "This registration is already decided.",
          {reason: "not-pending"});
    }
    const now = FieldValue.serverTimestamp();
    if (!approve) {
      tx.update(userRef, {status: "rejected", rejectReason: reason, rejectedBy: uid,
        rejectedAt: now, updatedAt: now});
      tx.set(db.collection(NOTIFICATIONS).doc(), {
        kind: "registration", title: "Registration not approved",
        body: `Your registration was not approved: ${reason}`,
        forRole: "student", userId: studentId, targetRoute: "/waiting",
        read: false, createdAt: now,
      });
      return {student: latinName(user)};
    }
    const tSnap = await tx.get(db.collection(USERS).doc(teacherId));
    const teacher = tSnap.exists ? tSnap.data() || {} : null;
    if (!teacher || teacher.role !== "teacher" || teacher.active === false) {
      throw new HttpsError("failed-precondition", "Pick an active teacher.",
          {reason: "teacher"});
    }
    if (found) {
      const rSnap = await tx.get(found.ref);
      const r = rSnap.data() || {};
      if (r.claimedBy && r.claimedBy !== studentId) {
        throw new HttpsError("failed-precondition",
            "This placement result code was already used by another student.",
            {reason: "claimed"});
      }
      tx.update(found.ref, {claimedBy: studentId, claimedAt: now});
    }
    tx.update(userRef, {
      status: "active", level, teacherId, approvedAt: now, approvedBy: uid,
      rejectReason: FieldValue.delete(), updatedAt: now,
    });
    const key = promo.levelKeyOf(level);
    const next = promo.nextLevelKey(key);
    tx.set(db.collection(PROMOTION_PROGRESS).doc(studentId), {
      studentId, level, levelKey: key, group: promo.groupOf(key),
      next: next ? `HSK ${next}` : "",
      count: 0, minCodes, codes: [], decision: "", updatedAt: now,
    });
    const name = latinName(user);
    tx.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "registration", title: "Welcome to Easy Study",
      body: `Your registration is approved. You start at ${level}.`,
      forRole: "student", userId: studentId, targetRoute: "/student",
      read: false, createdAt: now,
    });
    tx.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "registration", title: "New student",
      body: `${name} joined your students at ${level}.`,
      forRole: "teacher", userId: teacherId, targetRoute: "/teacher",
      read: false, createdAt: now,
    });
    return {student: name, teacher: latinName(teacher)};
  });
  await writeAudit({action: approve ? "registration.approve" : "registration.reject",
    actorId: uid, actorName: latinName(profile), targetType: "user", targetId: studentId,
    detail: approve ? `${out.student} · ${level} · ${out.teacher}` :
      `${out.student} · ${reason}`});
  if (approve) await safeRefresh(studentId, "registration approved");
  return {status: approve ? "active" : "rejected"};
});

// ---------------------------------------------------------------------------
// Build 4 (docs/PLAN.md §4): the student progress summary. One document per
// student (`progress_summary/{uid}`) feeds the report screen of every role.
// `refreshProgressSummary` reads the student's documents with bounded
// queries and writes what functions/progress.js decides. Triggers on the
// source collections call it; the daily job refreshes every student (some
// warnings move with time) and sends the warning notices, at most once per
// 7 days per student and warning.
// ---------------------------------------------------------------------------
const progress = require("./progress");
const PROGRESS_SUMMARY = "progress_summary";
const PROGRESS_NOTES = "progress_notes";

function msOf(v) {
  if (!v) return null;
  if (typeof v.toMillis === "function") return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === "number") return v;
  return null;
}

/** Rank and board size of [uid] on the board of [codeId], or nulls. */
async function rankOn(codeId, uid) {
  const snap = await db.collection(LEADERBOARDS).doc(codeId).collection("entries").get();
  const entries = snap.docs.map((d) => {
    const e = d.data() || {};
    return {studentId: d.id, total: Number(e.total) || 0,
      seconds: e.seconds === null || e.seconds === undefined ? null : Number(e.seconds),
      finishedAtMs: msOf(e.finishedAt)};
  });
  const ranked = promo.rankEntries(entries);
  const mine = ranked.find((e) => e.studentId === uid);
  return {rank: mine ? mine.rank : null, boardSize: mine ? ranked.length : null};
}

/** Rebuilds `progress_summary/{uid}`; returns the summary or null. */
async function refreshProgressSummary(uid) {
  if (!uid) return null;
  const userSnap = await db.collection(USERS).doc(uid).get();
  if (!userSnap.exists) return null;
  const user = userSnap.data() || {};
  if ((user.role || "student") !== "student") return null;
  const ref = db.collection(PROGRESS_SUMMARY).doc(uid);
  const [prevSnap, promoSnap, exSnap, attSnap, termSnap, testSnap, noteSnap, histSnap] =
    await Promise.all([
      ref.get(),
      db.collection(PROMOTION_PROGRESS).doc(uid).get(),
      db.collection(EXERCISE_RESULTS).where("studentId", "==", uid)
          .orderBy("submittedAt", "desc").limit(200).get(),
      db.collection("attendance").where("studentId", "==", uid)
          .orderBy("sessionDate", "desc").limit(60).get(),
      db.collection(CLASS_TERMS).where("studentId", "==", uid).get(),
      db.collection(TEST_RESULTS).where("studentId", "==", uid).get(),
      db.collection(PROGRESS_NOTES).where("studentId", "==", uid)
          .orderBy("createdAt", "desc").limit(1).get(),
      db.collection(USERS).doc(uid).collection("level_history").get(),
    ]);
  const previous = prevSnap.exists ? prevSnap.data() || {} : {};
  const tests = testSnap.docs.map((d) => ({resultId: d.id, ...(d.data() || {})}))
      .map((t) => ({...t, finishedAtMs: msOf(t.finishedAt)}));
  // Ranks of the newest 20 codes on a board.
  const rankCodes = [...new Set(tests
      .filter((t) => (t.status || "final") === "final" && t.valid !== false &&
        t.placement !== true)
      .sort((a, b) => (b.finishedAtMs || 0) - (a.finishedAtMs || 0))
      .map((t) => t.codeId).filter(Boolean))].slice(0, 20);
  const ranks = {};
  await Promise.all(rankCodes.map(async (c) => {
    ranks[c] = await rankOn(c, uid);
  }));
  const note = noteSnap.empty ? null : noteSnap.docs[0].data() || {};
  const summary = progress.summarize({
    user: {level: user.level,
      activeSinceMs: msOf(user.approvedAt) || msOf(user.createdAt)},
    promotion: promoSnap.exists ? promoSnap.data() || {} : {},
    exercises: exSnap.docs.map((d) => {
      const e = d.data() || {};
      return {score: e.score, status: e.status, bySkill: e.bySkill,
        submittedAtMs: msOf(e.submittedAt)};
    }),
    attendance: attSnap.docs.map((d) => {
      const a = d.data() || {};
      return {sessionDate: a.sessionDate, status: a.attendanceStatus,
        title: a.sessionTitle || ""};
    }),
    terms: termSnap.docs.map((d) => ({id: d.id, ...(d.data() || {})})),
    tests: tests.map((t) => ({...t, ...(ranks[t.codeId] || {})})),
    note: note ? {text: note.text, teacherName: note.teacherName,
      createdAtMs: msOf(note.createdAt)} : null,
    levelHistory: histSnap.docs.map((d) => {
      const h = d.data() || {};
      return {from: h.from, to: h.to, kind: h.kind, dateMs: msOf(h.date)};
    }),
    previous,
  }, Date.now());
  await ref.set({
    ...summary,
    studentId: uid,
    studentName: latinName(user),
    studentNameChinese: String(user.nameChinese || "").trim(),
    teacherId: String(user.teacherId || ""),
    active: user.active !== false,
    notifiedAt: previous.notifiedAt || {},
    updatedAt: FieldValue.serverTimestamp(),
  });
  return summary;
}

/** A refresh never fails the write that triggered it. */
async function safeRefresh(uid, why) {
  try {
    await refreshProgressSummary(uid);
  } catch (err) {
    logger.error(`progress summary ${uid} (${why})`, err);
  }
}

function studentIdOfEvent(event) {
  const before = event.data && event.data.before.exists ? event.data.before.data() : null;
  const after = event.data && event.data.after.exists ? event.data.after.data() : null;
  return String(((after || before) || {}).studentId || "");
}

exports.onExerciseResultWritten = onDocumentWritten(`${EXERCISE_RESULTS}/{id}`,
    async (event) => safeRefresh(studentIdOfEvent(event), "exercise result"));
exports.onAttendanceWritten = onDocumentWritten("attendance/{id}",
    async (event) => safeRefresh(studentIdOfEvent(event), "attendance"));
exports.onClassTermWritten = onDocumentWritten(`${CLASS_TERMS}/{id}`,
    async (event) => {
      await safeRefresh(studentIdOfEvent(event), "voucher");
      // Follow-up 2026-11-23: a voucher that gets a class day (bought with
      // one, or set by the admin) is booked into the sessions already
      // generated for that schedule; new ones book it as they are made.
      const before = event.data && event.data.before.exists ? event.data.before.data() || {} : {};
      const after = event.data && event.data.after.exists ? event.data.after.data() || {} : null;
      if (!after || !after.classDay || after.classDay === before.classDay) return;
      if ((after.status || "active") !== "active" || !after.studentId) return;
      try {
        await bookClassDayForStudent(after.studentId, after.classDay);
      } catch (err) {
        logger.warn(`class day booking for ${after.studentId}: ${err.message}`);
      }
    });
exports.onProgressNoteWritten = onDocumentWritten(`${PROGRESS_NOTES}/{id}`,
    async (event) => safeRefresh(studentIdOfEvent(event), "note"));

/** Active, approved students (the daily pass and the rebuild). */
async function activeStudentIds() {
  const snap = await db.collection(USERS).where("role", "==", "student").get();
  return snap.docs.filter((d) => {
    const u = d.data() || {};
    return u.active !== false && isApprovedStatus(u.status);
  }).map((d) => d.id);
}

/**
 * The daily pass: refresh every active student's summary, then send the
 * warning notices that are due (the spec's table: who hears about which
 * warning), at most once per 7 days per student and warning.
 */
async function dailyProgressPass() {
  const nowMs = Date.now();
  const ids = await activeStudentIds();
  let notices = 0;
  for (const uid of ids) {
    try {
      await refreshProgressSummary(uid);
      const ref = db.collection(PROGRESS_SUMMARY).doc(uid);
      const snap = await ref.get();
      const s = snap.data() || {};
      const due = progress.noticesDue(s, nowMs, s.notifiedAt || {});
      if (!due.length) continue;
      const name = AppUserLabel(s);
      const batch = db.batch();
      const notified = {...(s.notifiedAt || {})};
      for (const d of due) {
        const text = progress.noticeText(d.id, name, d.detail);
        const base = {kind: "progress", title: text.title, body: text.body, read: false,
          studentId: uid, warning: d.id, createdAt: FieldValue.serverTimestamp()};
        for (const role of d.roles) {
          if (role === "student") {
            batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "student",
              userId: uid, targetRoute: "/student/progress"});
          } else if (role === "teacher" && s.teacherId) {
            batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "teacher",
              userId: s.teacherId, targetRoute: `/teacher/student/${uid}/progress`});
          } else if (role === "admin") {
            batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "admin",
              userId: "", targetRoute: `/admin/users/${uid}/progress`});
          }
          notices += 1;
        }
        notified[String(d.id)] = nowMs;
      }
      batch.update(ref, {notifiedAt: notified});
      await batch.commit();
    } catch (err) {
      logger.error(`dailyProgressPass: ${uid}`, err);
    }
  }
  logger.info(`dailyProgressPass: ${ids.length} summaries, ${notices} notices`);
  return {students: ids.length, notices};
}

/** `中文名 (Latin)` from a summary (staff read the notices). */
function AppUserLabel(s) {
  const c = String(s.studentNameChinese || "").trim();
  const l = String(s.studentName || "").trim();
  if (!c) return l;
  if (!l) return c;
  return `${c} (${l})`;
}

/** Admin: rebuild every active student's summary (once after the deploy). */
exports.rebuildProgressSummaries = onCall({timeoutSeconds: 540}, async (request) => {
  const {uid, profile} = await requireCaller(request);
  if (profile.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins rebuild the summaries.");
  }
  const ids = await activeStudentIds();
  let done = 0;
  for (const id of ids) {
    try {
      await refreshProgressSummary(id);
      done += 1;
    } catch (err) {
      logger.error(`rebuildProgressSummaries: ${id}`, err);
    }
  }
  await writeAudit({action: "progress.rebuild", actorId: uid, actorName: latinName(profile),
    targetType: "progress_summary", targetId: "all", detail: `${done} of ${ids.length}`});
  return {students: ids.length, rebuilt: done};
});

// ---------------------------------------------------------------------------
// Build 5 (docs/PLAN.md §4, Must 6): vouchers expire after their validity.
// Active terms whose deadline has passed become `expired`; the remaining
// sessions are forfeited, a ledger entry is written, and the student, a
// linked parent and the admins are told. Idempotent: an expired term is
// never active again.
// ---------------------------------------------------------------------------
async function expireVouchersNow(nowMs = Date.now()) {
  const today = payments.jakartaDate(nowMs);
  const snap = await db.collection(CLASS_TERMS).where("status", "==", "active").get();
  const due = payments.expiredTerms(snap.docs.map((d) => ({id: d.id, ...(d.data() || {})})),
      today);
  let expired = 0;
  for (const t of due) {
    const ref = db.collection(CLASS_TERMS).doc(t.id);
    try {
      const done = await db.runTransaction(async (tx) => {
        const cur = await tx.get(ref);
        const term = cur.data() || {};
        if ((term.status || "active") !== "active") return null;
        const forfeited = Math.max(0, Number(term.sessionsRemaining) || 0);
        tx.update(ref, {status: "expired", sessionsForfeited: forfeited,
          expiredAt: FieldValue.serverTimestamp()});
        tx.set(db.collection(VOUCHER_HISTORY).doc(`${t.id}_expiry`), {
          kind: "expiry", studentId: term.studentId || "", termId: t.id,
          sessions: -forfeited, nameChinese: term.nameChinese || "",
          deadlineDate: term.deadlineDate || "", date: FieldValue.serverTimestamp(),
        });
        return {studentId: term.studentId || "", forfeited,
          deadline: term.deadlineDate || "", name: term.nameChinese || ""};
      });
      if (!done) continue;
      expired += 1;
      const userSnap = done.studentId ?
        await db.collection(USERS).doc(done.studentId).get() : null;
      const user = userSnap && userSnap.exists ? userSnap.data() || {} : {};
      const label = latinName(user) || "A student";
      const body = `${done.name ? done.name + " · " : ""}voucher ended on ${done.deadline}` +
        (done.forfeited ? `; ${done.forfeited} unused sessions expired.` : ".");
      const batch = db.batch();
      const base = {kind: "session", title: "Voucher expired", read: false,
        createdAt: FieldValue.serverTimestamp()};
      if (done.studentId) {
        batch.set(db.collection(NOTIFICATIONS).doc(), {...base, body: `Your ${body}`,
          forRole: "student", userId: done.studentId, targetRoute: "/student"});
      }
      if (user.linkedParentUid) {
        batch.set(db.collection(NOTIFICATIONS).doc(), {...base, body: `${label}: ${body}`,
          forRole: "parent", userId: user.linkedParentUid, targetRoute: "/parent"});
      }
      batch.set(db.collection(NOTIFICATIONS).doc(), {...base, body: `${label}: ${body}`,
        forRole: "admin", userId: "", targetRoute: "/admin"});
      await batch.commit();
    } catch (err) {
      logger.error(`expireVouchers: ${t.id}`, err);
    }
  }
  logger.info(`expireVouchers: ${expired} expired`);
  return {expired};
}

/**
 * Follow-up 2026-11-23 (privacy): clears the name and WhatsApp number of
 * visitor placement results nobody claimed after
 * `settings/placement.retentionDays` (default 180), on the result and on
 * its attempt. Marks stay for the item analysis.
 */
async function cleanPlacementResultsNow(nowMs = Date.now()) {
  const cfg = await db.collection(SETTINGS).doc("placement").get();
  const days = Number((cfg.data() || {}).retentionDays) >= 1 ?
    Number((cfg.data() || {}).retentionDays) : placement.RETENTION_DAYS;
  const before = Timestamp.fromMillis(nowMs - days * 86400000);
  const snap = await db.collection(PLACEMENT_RESULTS).where("finishedAt", "<=", before).get();
  let cleared = 0;
  for (const d of snap.docs) {
    const r = d.data() || {};
    if (!placement.retentionDue({...r, finishedAtMs: millisOf(r.finishedAt)}, nowMs, days)) continue;
    const batch = db.batch();
    batch.update(d.ref, {name: "", whatsapp: "", personalDataClearedAt: FieldValue.serverTimestamp()});
    const att = db.collection(TEST_ATTEMPTS).doc(d.id);
    if ((await att.get()).exists) batch.update(att, {visitorName: "", visitorWhatsapp: ""});
    await batch.commit();
    cleared += 1;
  }
  logger.info(`cleanPlacementResults: ${cleared} cleared (${days} days)`);
  return {cleared, days};
}

exports.cleanPlacementResults = onSchedule(
    {schedule: "every day 02:00", timeZone: "Asia/Jakarta"},
    async () => {
      await cleanPlacementResultsNow();
    },
);

/** Admin, emulator only: run the clean-up with a chosen clock (flow test). */
exports.runPlacementCleanup = onCall(async (request) => {
  const caller = await requireCaller(request);
  if (caller.profile.role !== "admin") throw new HttpsError("permission-denied", "Admins only.");
  const nowMs = process.env.FUNCTIONS_EMULATOR === "true" && Number((request.data || {}).nowMs) ?
    Number(request.data.nowMs) : Date.now();
  return cleanPlacementResultsNow(nowMs);
});

exports.expireVouchers = onSchedule(
    {schedule: "every day 00:30", timeZone: "Asia/Jakarta"},
    async () => {
      await expireVouchersNow();
    },
);

// ---------------------------------------------------------------------------
// Build 6 (docs/PLAN.md §4): the weekly timetable and booking. Schedules are
// written only by `saveSchedule` (admin) so the conflict check cannot be
// skipped; sessions are generated two weeks ahead with deterministic ids;
// students book and cancel through functions that reserve a voucher
// session. Pure logic in functions/scheduling.js.
// ---------------------------------------------------------------------------
const sched = require("./scheduling");
const SCHEDULES = "schedules";
const SCHEDULE_LOCKS = "schedule_locks";
const DAYS_OFF = "teacher_days_off";
const CLASS_SESSIONS = "class_sessions";

async function schedulingSettings() {
  const snap = await db.collection(SETTINGS).doc("scheduling").get();
  const d = snap.exists ? snap.data() || {} : {};
  const num = (v, f) => Number.isFinite(Number(v)) && Number(v) >= 0 ? Number(v) : f;
  return {
    minGapMinutes: num(d.minGapMinutes, sched.DEFAULTS.minGapMinutes),
    weeklyHoursWarning: num(d.weeklyHoursWarning, sched.DEFAULTS.weeklyHoursWarning),
    defaultCapacity: num(d.defaultCapacity, sched.DEFAULTS.defaultCapacity) || 8,
  };
}

/** A clean schedule from the form. */
function scheduleFromInput(data, settings) {
  const n = (v) => Math.round(Number(v));
  return {
    id: String(data.id || "").trim() || null,
    className: String(data.className || "").trim().slice(0, 80),
    weekday: n(data.weekday),
    startMinutes: n(data.startMinutes),
    endMinutes: n(data.endMinutes),
    room: String(data.room || "").trim(),
    teacherId: String(data.teacherId || "").trim(),
    capacity: Number.isFinite(Number(data.capacity)) && Number(data.capacity) > 0 ?
      n(data.capacity) : settings.defaultCapacity,
    level: String(data.level || "").trim(),
    validFrom: String(data.validFrom || "").trim(),
    validTo: String(data.validTo || "").trim(),
    active: data.active !== false,
  };
}

/** Everything the conflict check needs, read outside or inside a transaction. */
async function scheduleContext(s, settings, read = (q) => q.get()) {
  const teacherSnap = s.teacherId ? await read(db.collection(USERS).doc(s.teacherId)) : null;
  const teacher = teacherSnap && teacherSnap.exists ? teacherSnap.data() || {} : null;
  const [tSched, rSched, tSess, rSess] = await Promise.all([
    s.teacherId ? read(db.collection(SCHEDULES).where("teacherId", "==", s.teacherId)) : null,
    s.room ? read(db.collection(SCHEDULES).where("room", "==", s.room)) : null,
    s.teacherId ? read(db.collection(CLASS_SESSIONS).where("teacherId", "==", s.teacherId)) : null,
    s.room ? read(db.collection(CLASS_SESSIONS).where("room", "==", s.room)) : null,
  ]);
  const rows = (q) => (q ? q.docs.map((d) => ({id: d.id, ...(d.data() || {})})) : []);
  const today = sched.jakartaDate(Date.now());
  const futureOneOffs = (list) => list.filter((x) => !x.scheduleId &&
    String(x.sessionDate || "") >= today);
  return {
    teacher,
    ctx: {
      teacherName: teacher ? latinName(teacher) : "",
      teacherSchedules: rows(tSched),
      roomSchedules: rows(rSched),
      teacherSessions: futureOneOffs(rows(tSess)),
      roomSessions: futureOneOffs(rows(rSess)),
      availability: teacher && teacher.availability ? teacher.availability : null,
      gapMinutes: settings.minGapMinutes,
    },
  };
}

function checkResult(s, teacher, ctx, settings) {
  const reasons = [...sched.validate(s, teacher ?
    {name: latinName(teacher), levels: teacher.levels || []} : null)];
  if (!teacher || teacher.role !== "teacher" || teacher.active === false) {
    if (s.teacherId) reasons.push({code: "teacher", text: "Pick an active teacher."});
  }
  if (!reasons.length) reasons.push(...sched.conflicts(s, ctx));
  const warnings = [];
  const mine = ctx.teacherSchedules.filter((x) => x.id !== s.id);
  const hours = sched.weeklyHours([...mine, s]);
  if (hours > settings.weeklyHoursWarning) {
    warnings.push({code: "hours", text: `${ctx.teacherName || "The teacher"} would teach ` +
      `${hours} hours a week (more than ${settings.weeklyHoursWarning}).`});
  }
  const length = Math.max(30, (s.endMinutes - s.startMinutes) || 90);
  // One-off sessions in the period count too (seen 2026-11-23: a free time
  // was offered that a one-off class then blocked).
  const inPeriod = (d) => (!s.validFrom || d >= s.validFrom) && (!s.validTo || d <= s.validTo);
  const oneOffs = [...ctx.teacherSessions, ...ctx.roomSessions]
      .filter((x) => !(x.scheduleId && x.scheduleId === s.id) && inPeriod(String(x.sessionDate || "")))
      .map((x) => ({...x, weekday: sched.weekdayOf(x.sessionDate)}));
  const busy = [...mine, ...ctx.roomSchedules.filter((x) => x.id !== s.id), ...oneOffs];
  const suggestions = reasons.length && ctx.availability ?
    sched.suggestFreeSlots(ctx.availability, busy, s.weekday, length,
        settings.minGapMinutes, 5) : [];
  return {ok: reasons.length === 0, reasons, warnings, suggestions};
}

async function requireAdmin(request) {
  const caller = await requireCaller(request);
  if (caller.profile.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins manage the timetable.");
  }
  return caller;
}

/** Admin: the reasons, warnings and free slots of a schedule as it is typed. */
exports.checkScheduleConflict = onCall(async (request) => {
  await requireAdmin(request);
  const settings = await schedulingSettings();
  const s = scheduleFromInput(request.data || {}, settings);
  const {teacher, ctx} = await scheduleContext(s, settings);
  return checkResult(s, teacher, ctx, settings);
});

/**
 * Admin: save a schedule. The check runs inside a transaction that reads
 * and bumps `schedule_locks/{teacherId}` and `schedule_locks/room_{room}`,
 * so two saves for the same teacher or room at the same time end with one
 * schedule (JD-02: the second retries, sees the first and is refused).
 */
exports.saveSchedule = onCall(async (request) => {
  const {uid, profile} = await requireAdmin(request);
  const settings = await schedulingSettings();
  const s = scheduleFromInput(request.data || {}, settings);
  const ref = s.id ? db.collection(SCHEDULES).doc(s.id) : db.collection(SCHEDULES).doc();
  const out = await db.runTransaction(async (tx) => {
    const tLock = db.collection(SCHEDULE_LOCKS).doc(s.teacherId || "none");
    const rLock = db.collection(SCHEDULE_LOCKS).doc(`room_${s.room.replace(/\//g, "_") || "none"}`);
    const [tl, rl] = [await tx.get(tLock), await tx.get(rLock)];
    const {teacher, ctx} = await scheduleContext({...s, id: ref.id}, settings, (q) => tx.get(q));
    const result = checkResult({...s, id: ref.id}, teacher, ctx, settings);
    if (!result.ok) return result;
    tx.set(tLock, {version: (Number((tl.data() || {}).version) || 0) + 1,
      updatedAt: FieldValue.serverTimestamp()});
    tx.set(rLock, {version: (Number((rl.data() || {}).version) || 0) + 1,
      updatedAt: FieldValue.serverTimestamp()});
    const {id, ...rest} = s;
    tx.set(ref, {
      ...rest,
      teacherName: teacher ? latinName(teacher) : "",
      status: "unconfirmed",
      createdBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
      ...(id ? {} : {createdAt: FieldValue.serverTimestamp()}),
    }, {merge: true});
    return {...result, scheduleId: ref.id};
  });
  if (!out.ok) {
    throw new HttpsError("failed-precondition", out.reasons.map((r) => r.text).join(" "),
        {reason: "conflict", reasons: out.reasons, suggestions: out.suggestions});
  }
  await writeAudit({action: s.id ? "schedule.update" : "schedule.create", actorId: uid,
    actorName: latinName(profile), targetType: "schedule", targetId: out.scheduleId,
    detail: `${s.className} · ${sched.WEEKDAY_NAMES[s.weekday]} ` +
      `${sched.clock(s.startMinutes)}–${sched.clock(s.endMinutes)} · ${s.room}`});
  const generated = await generateSessionsNow({scheduleIds: [out.scheduleId]});
  // Build 7: switching a schedule off cancels its future sessions.
  const cancelled = s.active === false ? await cancelFutureSessions(out.scheduleId) : 0;
  return {ok: true, scheduleId: out.scheduleId, warnings: out.warnings, ...generated, cancelled};
});

/**
 * Admin (owner 2026-11-23): delete a weekly schedule. Its future sessions
 * are cancelled first (bookings and voucher sessions come back, students
 * are told), vouchers that used it as their class day lose that day, then
 * the schedule is removed. Past and finished sessions stay for the reports.
 */
exports.deleteSchedule = onCall(async (request) => {
  const {uid, profile} = await requireAdmin(request);
  const id = String((request.data || {}).scheduleId || "").trim();
  if (!id) throw new HttpsError("invalid-argument", "scheduleId is required.");
  const ref = db.collection(SCHEDULES).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Schedule not found.");
  const s = snap.data() || {};
  const cancelled = await cancelFutureSessions(id);
  const terms = await db.collection(CLASS_TERMS).where("classDay", "==", id).get();
  const batch = db.batch();
  for (const t of terms.docs) {
    batch.update(t.ref, {classDay: FieldValue.delete(), updatedAt: FieldValue.serverTimestamp()});
  }
  batch.delete(ref);
  await batch.commit();
  await writeAudit({action: "schedule.delete", actorId: uid, actorName: latinName(profile),
    targetType: "schedule", targetId: id,
    detail: `${s.className || ""} · ${sched.WEEKDAY_NAMES[s.weekday] || ""} ` +
      `${sched.clock(s.startMinutes)}–${sched.clock(s.endMinutes)} · ${s.room || ""} · ` +
      `${cancelled} sessions cancelled, ${terms.size} class days cleared`});
  return {deleted: true, cancelled, classDaysCleared: terms.size};
});

/**
 * Creates the next 14 days of sessions of every active schedule (or of
 * [scheduleIds]); deterministic ids, so a second run creates nothing. A
 * session on the teacher's day off is `needs_teacher`. A future session
 * with no bookings follows its schedule's edits; one with bookings is
 * flagged for the admin. Then books the students whose voucher has that
 * schedule as its class day.
 */
async function generateSessionsNow({scheduleIds = null, nowMs = Date.now()} = {}) {
  const today = sched.jakartaDate(nowMs);
  const snap = scheduleIds ?
    await Promise.all(scheduleIds.map((id) => db.collection(SCHEDULES).doc(id).get())) :
    (await db.collection(SCHEDULES).where("active", "==", true).get()).docs;
  let created = 0;
  let updated = 0;
  let booked = 0;
  for (const doc of snap) {
    if (!doc.exists) continue;
    const s = {id: doc.id, ...(doc.data() || {})};
    if (s.active === false) continue;
    const daysOff = new Set((await db.collection(DAYS_OFF)
        .where("teacherId", "==", s.teacherId).get()).docs
        .map((d) => (d.data() || {}).date));
    for (const date of sched.sessionDates(s, today, 14)) {
      const ref = db.collection(CLASS_SESSIONS).doc(sched.sessionIdFor(s.id, date));
      const res = await db.runTransaction(async (tx) => {
        const cur = await tx.get(ref);
        const fields = {
          scheduleId: s.id, teacherId: s.teacherId, teacherName: s.teacherName || "",
          sessionDate: date, sessionTitle: s.className, startMinutes: s.startMinutes,
          endMinutes: s.endMinutes, capacity: s.capacity, room: s.room, level: s.level || "",
          mode: "offline",
        };
        if (!cur.exists) {
          tx.set(ref, {...fields, status: daysOff.has(date) ? "needs_teacher" : "scheduled",
            // Students and parents read generated sessions of every teacher.
            generated: true,
            bookedCount: 0, isOpen: true, isConcluded: false, registrationState: "open",
            createdAt: FieldValue.serverTimestamp()});
          return "created";
        }
        const c = cur.data() || {};
        const changed = ["startMinutes", "endMinutes", "room", "capacity", "level",
          "teacherId", "sessionTitle"].some((k) => c[k] !== fields[k]);
        if (!changed) return "same";
        if ((Number(c.bookedCount) || 0) === 0) {
          tx.update(ref, {...fields, updatedAt: FieldValue.serverTimestamp()});
          return "updated";
        }
        tx.update(ref, {scheduleChanged: true, updatedAt: FieldValue.serverTimestamp()});
        return "flagged";
      });
      if (res === "created") created += 1;
      if (res === "updated") updated += 1;
      if (res === "created") booked += await bookClassDayStudents(s.id, ref.id, nowMs);
    }
  }
  logger.info(`generateSessions: ${created} created, ${updated} updated, ${booked} booked`);
  return {created, updated, booked};
}

exports.generateSessions = onSchedule(
    {schedule: "every sunday 20:00", timeZone: "Asia/Jakarta", timeoutSeconds: 540},
    async () => {
      await generateSessionsNow();
    },
);

/**
 * Books one student into the upcoming generated sessions of [scheduleId]
 * (a voucher just got that class day). A refusal (full, no sessions left,
 * already booked) skips that session.
 */
async function bookClassDayForStudent(studentId, scheduleId, nowMs = Date.now()) {
  const today = sched.jakartaDate(nowMs);
  const snap = await db.collection(CLASS_SESSIONS).where("scheduleId", "==", scheduleId).get();
  const upcoming = snap.docs.filter((d) => {
    const x = d.data() || {};
    return String(x.sessionDate || "") >= today && (x.status || "scheduled") === "scheduled" &&
      nowMs < tday.atMs(x.sessionDate, x.startMinutes);
  }).sort((a, b) => String(a.data().sessionDate).localeCompare(String(b.data().sessionDate)));
  let n = 0;
  for (const d of upcoming) {
    try {
      await bookSessionTx(studentId, d.id, nowMs, "class_day");
      n += 1;
    } catch (err) {
      logger.info(`class day booking refused: ${studentId} ${d.id}: ${err.message}`);
    }
  }
  return n;
}

/** Books the students whose active voucher has [scheduleId] as class day. */
async function bookClassDayStudents(scheduleId, sessionId, nowMs) {
  const terms = await db.collection(CLASS_TERMS).where("classDay", "==", scheduleId)
      .where("status", "==", "active").get();
  let n = 0;
  for (const t of terms.docs) {
    const studentId = (t.data() || {}).studentId;
    if (!studentId) continue;
    try {
      await bookSessionTx(studentId, sessionId, nowMs, "class_day");
      n += 1;
    } catch (err) {
      logger.info(`class day booking refused: ${studentId} ${sessionId}: ${err.message}`);
    }
  }
  return n;
}

/**
 * One booking, in one transaction: the checks of `bookingRefusal`, then the
 * attendance doc, the seat and the voucher's booked count.
 */
async function bookSessionTx(studentId, sessionId, nowMs, via) {
  const sessionRef = db.collection(CLASS_SESSIONS).doc(sessionId);
  const attRef = db.collection("attendance").doc(`${sessionId}_${studentId}`);
  const [userSnap, termsSnap, mineSnap] = await Promise.all([
    db.collection(USERS).doc(studentId).get(),
    db.collection(CLASS_TERMS).where("studentId", "==", studentId).get(),
    db.collection("attendance").where("studentId", "==", studentId)
        .where("booked", "==", true).get(),
  ]);
  const user = userSnap.exists ? userSnap.data() || {} : {};
  return db.runTransaction(async (tx) => {
    const sSnap = await tx.get(sessionRef);
    if (!sSnap.exists) throw new HttpsError("not-found", "Session not found.");
    const session = sSnap.data() || {};
    const att = await tx.get(attRef);
    if (att.exists) {
      throw new HttpsError("already-exists", "Already booked.", {reason: "already"});
    }
    const terms = termsSnap.docs.map((d) => ({id: d.id, ...(d.data() || {})}));
    const term = sched.termForBooking(terms, session.sessionDate);
    const termSnap = term ? await tx.get(db.collection(CLASS_TERMS).doc(term.id)) : null;
    const freshTerm = termSnap && termSnap.exists ? {id: term.id, ...termSnap.data()} : null;
    const others = mineSnap.docs.map((d) => d.data() || {})
        .filter((a) => a.sessionDate === session.sessionDate);
    const refusal = sched.bookingRefusal(session, freshTerm || terms.find(
        (t) => (t.status || "active") === "active") || null, others, nowMs,
    {studentLevel: user.level || ""});
    if (refusal) {
      throw new HttpsError("failed-precondition", `Cannot book: ${refusal}.`, {reason: refusal});
    }
    tx.set(attRef, {
      sessionId, studentId, teacherId: session.teacherId || "",
      sessionDate: session.sessionDate, sessionTitle: session.sessionTitle || "",
      startMinutes: session.startMinutes, endMinutes: session.endMinutes,
      attended: false, booked: true, joinedBy: "student", bookedVia: via,
      ...(nowMs >= tday.atMs(session.sessionDate, session.startMinutes) ? {lateJoin: true} : {}),
      studentName: latinName(user), classTermId: freshTerm.id, sessionCredited: false,
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.update(sessionRef, {bookedCount: FieldValue.increment(1)});
    tx.update(termSnap.ref, {sessionsBooked: FieldValue.increment(1)});
    tx.set(db.collection(NOTIFICATIONS).doc(), {
      kind: "session", title: "Class booked",
      body: `${session.sessionTitle || "Class"} · ${session.sessionDate} ` +
        `${sched.clock(session.startMinutes)}`,
      forRole: "student", userId: studentId, targetRoute: "/student",
      read: false, createdAt: FieldValue.serverTimestamp(),
    });
    return {booked: true, termId: freshTerm.id};
  });
}

/** Who may book or cancel for [studentId]: the student or a linked parent. */
async function requireBookingCaller(request, studentId) {
  const {uid, profile} = await requireCaller(request);
  const target = String(studentId || "").trim() || uid;
  const role = profile.role || "student";
  if (role === "student" && target === uid) return target;
  if (role === "parent" && (profile.studentIds || []).includes(target)) return target;
  throw new HttpsError("permission-denied", "You can only book for yourself or your child.",
      {reason: "not-yours"});
}

exports.bookSession = onCall(async (request) => {
  const data = request.data || {};
  const studentId = await requireBookingCaller(request, data.studentId);
  const sessionId = String(data.sessionId || "").trim();
  if (!sessionId || sessionId.includes("/")) {
    throw new HttpsError("invalid-argument", "sessionId is required.");
  }
  return bookSessionTx(studentId, sessionId, Date.now(), "student");
});

/** Cancel a booking before the session starts: the seat and the voucher's
 * booked count come back. */
exports.cancelBooking = onCall(async (request) => {
  const data = request.data || {};
  const studentId = await requireBookingCaller(request, data.studentId);
  const sessionId = String(data.sessionId || "").trim();
  if (!sessionId || sessionId.includes("/")) {
    throw new HttpsError("invalid-argument", "sessionId is required.");
  }
  const sessionRef = db.collection(CLASS_SESSIONS).doc(sessionId);
  const attRef = db.collection("attendance").doc(`${sessionId}_${studentId}`);
  return db.runTransaction(async (tx) => {
    const [sSnap, aSnap] = [await tx.get(sessionRef), await tx.get(attRef)];
    if (!aSnap.exists || (aSnap.data() || {}).booked !== true) {
      throw new HttpsError("not-found", "No booking to cancel.", {reason: "no_booking"});
    }
    const session = sSnap.data() || {};
    if (sched.startMs(session.sessionDate, session.startMinutes) <= Date.now()) {
      throw new HttpsError("failed-precondition", "The class has started.",
          {reason: "too_late"});
    }
    const a = aSnap.data() || {};
    const termRef = a.classTermId ? db.collection(CLASS_TERMS).doc(a.classTermId) : null;
    const tSnap = termRef ? await tx.get(termRef) : null;
    tx.delete(attRef);
    tx.update(sessionRef, {bookedCount: FieldValue.increment(-1)});
    if (tSnap && tSnap.exists && (Number((tSnap.data() || {}).sessionsBooked) || 0) > 0) {
      tx.update(termRef, {sessionsBooked: FieldValue.increment(-1)});
    }
    return {cancelled: true};
  });
});

// ---------------------------------------------------------------------------
// Build 7 (docs/PLAN.md §4): the teaching day. Confirmation and change
// requests, check-in with server time, the close in ONE idempotent
// transaction that writes the voucher ledger (VC-01, VC-02, VC-03),
// substitutes and cancellations, reminders and late / unclosed flags, the
// monthly recap and reconciliation (VC-05). Pure logic in teaching_day.js.
// ---------------------------------------------------------------------------
const tday = require("./teaching_day");
const CHANGE_REQUESTS = "schedule_change_requests";
const TEACHER_RECAPS = "teacher_recaps";

async function requireSessionStaff(request, session) {
  const caller = await requireStaff(request);
  if (caller.profile.role !== "admin" && session.teacherId !== caller.uid) {
    throw new HttpsError("permission-denied", "This is another teacher's session.",
        {reason: "not-yours"});
  }
  return caller;
}

async function loadSession(id) {
  const sid = String(id || "").trim();
  if (!sid || sid.includes("/")) throw new HttpsError("invalid-argument", "sessionId is required.");
  const ref = db.collection(CLASS_SESSIONS).doc(sid);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Session not found.");
  return {ref, session: snap.data() || {}};
}

/** Teacher: confirm their own schedule. */
exports.confirmSchedule = onCall(async (request) => {
  const {uid} = await requireStaff(request);
  const ref = db.collection(SCHEDULES).doc(String((request.data || {}).scheduleId || ""));
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Schedule not found.");
  if ((snap.data() || {}).teacherId !== uid) {
    throw new HttpsError("permission-denied", "Not your schedule.", {reason: "not-yours"});
  }
  await ref.update({status: "confirmed", confirmedAt: FieldValue.serverTimestamp()});
  return {status: "confirmed"};
});

/** Teacher: ask the admin for a change to a schedule. */
exports.requestScheduleChange = onCall(async (request) => {
  const {uid, profile} = await requireStaff(request);
  const data = request.data || {};
  const scheduleId = String(data.scheduleId || "");
  const reason = String(data.reason || "").trim().slice(0, 500);
  const wanted = String(data.wanted || "").trim().slice(0, 500);
  if (!reason) throw new HttpsError("invalid-argument", "Give a reason.", {reason: "reason-required"});
  const s = await db.collection(SCHEDULES).doc(scheduleId).get();
  if (!s.exists || (s.data() || {}).teacherId !== uid) {
    throw new HttpsError("permission-denied", "Not your schedule.", {reason: "not-yours"});
  }
  const ref = await db.collection(CHANGE_REQUESTS).add({scheduleId, teacherId: uid,
    teacherName: latinName(profile), className: (s.data() || {}).className || "", reason, wanted,
    status: "open", createdAt: FieldValue.serverTimestamp()});
  await db.collection(NOTIFICATIONS).add({kind: "session", title: "Schedule change request",
    body: `${latinName(profile)}: ${(s.data() || {}).className || ""} — ${reason}`,
    forRole: "admin", userId: "", targetRoute: "/admin/timetable", read: false,
    createdAt: FieldValue.serverTimestamp()});
  return {requestId: ref.id};
});

/** Admin: resolve a change request (done or declined with a note). */
exports.resolveScheduleChange = onCall(async (request) => {
  await requireAdmin(request);
  const data = request.data || {};
  const ref = db.collection(CHANGE_REQUESTS).doc(String(data.requestId || ""));
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Request not found.");
  const status = data.accept === true ? "done" : "declined";
  const note = String(data.note || "").trim().slice(0, 500);
  await ref.update({status, note, resolvedAt: FieldValue.serverTimestamp()});
  const r = snap.data() || {};
  await db.collection(NOTIFICATIONS).add({kind: "session",
    title: status === "done" ? "Schedule change done" : "Schedule change declined",
    body: `${r.className || ""}${note ? ` — ${note}` : ""}`, forRole: "teacher",
    userId: r.teacherId || "", targetRoute: "/teacher", read: false,
    createdAt: FieldValue.serverTimestamp()});
  return {status};
});

/** Teacher of the session or admin: check in with the server's time. */
exports.checkInSession = onCall(async (request) => {
  const {ref, session} = await loadSession((request.data || {}).sessionId);
  await requireSessionStaff(request, session);
  const st = session.status || "scheduled";
  if ((st !== "scheduled" && st !== "ongoing") || session.isConcluded === true) {
    throw new HttpsError("failed-precondition", "This session cannot start.",
        {reason: session.status || "closed"});
  }
  if (session.checkInAt) return {status: "ongoing", lateMinutes: Number(session.lateMinutes) || 0};
  const d = tday.checkInDecision(session, Date.now());
  if (!d.ok) throw new HttpsError("failed-precondition", "Not inside the check-in window.", {reason: d.reason});
  await ref.update({status: "ongoing", checkInAt: FieldValue.serverTimestamp(),
    lateMinutes: d.lateMinutes, ...(d.lateMinutes ? {lateCheckIn: true} : {})});
  return {status: "ongoing", lateMinutes: d.lateMinutes};
});

/**
 * Close a session in ONE transaction, idempotent (VC-02): every booked
 * student's attendance status, the term counters (hadir / alpa use a
 * session, izin returns the booking), one ledger doc per student with a
 * fixed id, the session `done`, the teacher's month recap.
 * data: {sessionId, statuses: {studentId: 'hadir'|'izin'|'alpa'}}
 */
exports.closeSession = onCall(async (request) => {
  const data = request.data || {};
  const {ref, session} = await loadSession(data.sessionId);
  const {profile} = await requireSessionStaff(request, session);
  const byAdmin = profile.role === "admin";
  const statuses = data.statuses && typeof data.statuses === "object" ? data.statuses : {};
  const attSnap = await db.collection("attendance").where("sessionId", "==", ref.id).get();
  // Students added by the teacher (no booking) are charged from their
  // oldest usable term, as the old client-side close did.
  const legacyIds = [...new Set(attSnap.docs.map((d) => d.data() || {})
      .filter((a) => a.booked !== true && a.attended === true && !a.classTermId)
      .map((a) => a.studentId).filter(Boolean))];
  const legacyTerms = {};
  for (const sid of legacyIds) {
    const q = await db.collection(CLASS_TERMS).where("studentId", "==", sid).get();
    const t = sched.termForBooking(q.docs.map((d) => ({id: d.id, ...(d.data() || {})})),
        session.sessionDate);
    if (t) legacyTerms[sid] = t.id;
  }
  return db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    const s = cur.data() || {};
    // Owner 2026-11-23: a session past its start counts as started.
    const status = tday.effectiveStatus(s, Date.now());
    // A one-off session made by a teacher has no check-in step.
    const decision = tday.closeDecision(status, byAdmin || s.generated !== true);
    if (decision === "already-done") {
      return {status: "done", already: true, credited: 0, excused: 0, failed: []};
    }
    // A timetable session that has not started yet is not closed by anyone.
    const early = s.generated === true && status === "scheduled" &&
      Date.now() < tday.atMs(s.sessionDate, s.startMinutes);
    if (decision !== "close" || early) {
      throw new HttpsError("failed-precondition", "Start the session first.",
          {reason: early ? "not-started" : decision});
    }
    const atts = [];
    for (const d of attSnap.docs) {
      const a = (await tx.get(d.ref)).data() || {};
      if (a.sessionCredited === true || a.closed === true || a.status === "cancelled") continue;
      if (a.booked !== true && a.attended !== true) continue;
      atts.push({ref: d.ref, a, termId: a.classTermId || legacyTerms[a.studentId] || ""});
    }
    const termIds = [...new Set(atts.map((x) => x.termId).filter(Boolean))];
    const terms = {};
    for (const id of termIds) {
      const snap = await tx.get(db.collection(CLASS_TERMS).doc(id));
      if (snap.exists) {
        const t = snap.data() || {};
        terms[id] = {ref: snap.ref, t, base: t.ledgerBaseUsed === undefined ?
          Number(t.sessionsUsed) || 0 : null};
      }
    }
    const recapRef = db.collection(TEACHER_RECAPS)
        .doc(`${s.teacherId}_${tday.monthKey(s.sessionDate)}`);
    const recap = await tx.get(recapRef);
    let credited = 0;
    let excused = 0;
    const failed = [];
    for (const {ref: aRef, a, termId} of atts) {
      const st = ["hadir", "izin", "alpa"].includes(statuses[a.studentId]) ?
        statuses[a.studentId] : (["hadir", "izin", "alpa"].includes(a.attendanceStatus) ?
          a.attendanceStatus : (a.booked === true ? "alpa" : "hadir"));
      const raw = tday.closeEffect(st);
      // Only a booking holds a reserved session to give back.
      const eff = {...raw, booked: a.booked === true ? raw.booked : 0};
      const entry = terms[termId];
      const usable = Boolean(entry) && (eff.used === 0 ||
        (Number(entry.t.sessionsRemaining) || 0) + eff.remaining >= 0);
      if (usable) {
        const t = entry.t;
        entry.t = {...t,
          sessionsBooked: Math.max(0, (Number(t.sessionsBooked) || 0) + eff.booked),
          sessionsUsed: (Number(t.sessionsUsed) || 0) + eff.used,
          sessionsRemaining: Math.max(0, (Number(t.sessionsRemaining) || 0) + eff.remaining)};
      }
      const charged = usable && eff.used > 0;
      if (st === "izin") excused += 1;
      else if (charged) credited += 1;
      else failed.push(a.studentName || a.studentId);
      tx.set(db.collection(VOUCHER_HISTORY).doc(`${ref.id}_${a.studentId}`), {
        kind: "session", studentId: a.studentId, termId: usable ? termId : "",
        sessionId: ref.id, sessionDate: s.sessionDate || "", status: st,
        sessions: charged ? eff.delta : 0, ...(st !== "izin" && !charged ? {noVoucher: true} : {}),
        date: FieldValue.serverTimestamp(),
      });
      tx.update(aRef, {attendanceStatus: st, sessionCredited: charged, closed: true,
        ...(usable ? {classTermId: termId} : {})});
    }
    for (const {ref: tRef, t, base} of Object.values(terms)) {
      // The first ledger entry remembers what was used before the ledger.
      tx.update(tRef, {...(base !== null ? {ledgerBaseUsed: base} : {}),
        sessionsBooked: Number(t.sessionsBooked) || 0,
        sessionsUsed: Number(t.sessionsUsed) || 0,
        sessionsRemaining: Number(t.sessionsRemaining) || 0,
        ...((Number(t.sessionsRemaining) || 0) <= 0 ? {status: "depleted"} : {})});
    }
    tx.update(ref, {status: "done", isConcluded: true, isOpen: false,
      concludedAt: FieldValue.serverTimestamp()});
    const r = recap.exists ? recap.data() || {} : {};
    tx.set(recapRef, {teacherId: s.teacherId || "", teacherName: s.teacherName || "",
      month: tday.monthKey(s.sessionDate),
      held: (Number(r.held) || 0) + 1,
      hours: Math.round(((Number(r.hours) || 0) + tday.sessionHours(s)) * 10) / 10,
      lateCheckIns: (Number(r.lateCheckIns) || 0) + (s.lateCheckIn ? 1 : 0),
      students: (Number(r.students) || 0) + credited,
      updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    return {status: "done", credited, excused, failed};
  });
});

/** Admin: the teachers who could take a session (available, level, no clash). */
exports.substituteCandidates = onCall(async (request) => {
  await requireAdmin(request);
  const {session} = await loadSession((request.data || {}).sessionId);
  const settings = await schedulingSettings();
  const teachers = await db.collection(USERS).where("role", "==", "teacher").get();
  const out = [];
  for (const d of teachers.docs) {
    const t = d.data() || {};
    if (d.id === session.teacherId || t.active === false) continue;
    const s = {id: "", className: session.sessionTitle || "", weekday: sched.weekdayOf(session.sessionDate),
      startMinutes: session.startMinutes, endMinutes: session.endMinutes,
      room: session.room || "", teacherId: d.id, capacity: 1, level: session.level || "",
      validFrom: session.sessionDate, validTo: session.sessionDate};
    const {teacher, ctx} = await scheduleContext(s, settings);
    const result = checkResult(s, teacher, {...ctx, roomSchedules: [], roomSessions: []}, settings);
    if (result.ok) out.push({uid: d.id, name: latinName(t)});
  }
  return {candidates: out};
});

/** Admin: give a session to another teacher (everyone is told). */
exports.assignSubstitute = onCall(async (request) => {
  await requireAdmin(request);
  const data = request.data || {};
  const {ref, session} = await loadSession(data.sessionId);
  const subId = String(data.teacherId || "");
  const sub = await db.collection(USERS).doc(subId).get();
  if (!sub.exists || (sub.data() || {}).role !== "teacher") {
    throw new HttpsError("invalid-argument", "Pick a teacher.", {reason: "teacher"});
  }
  const subName = latinName(sub.data() || {});
  const atts = await db.collection("attendance").where("sessionId", "==", ref.id).get();
  await db.runTransaction(async (tx) => {
    const cur = (await tx.get(ref)).data() || {};
    if (["done", "cancelled"].includes(cur.status) || cur.isConcluded === true) {
      throw new HttpsError("failed-precondition", "This session is closed.", {reason: "done"});
    }
    tx.update(ref, {teacherId: subId, teacherName: subName,
      substituteFor: cur.substituteFor || cur.teacherId || "",
      status: cur.status === "needs_teacher" ? "scheduled" : cur.status || "scheduled"});
    // The substitute's lists read attendance by teacher.
    for (const d of atts.docs) tx.update(d.ref, {teacherId: subId});
  });
  const batch = db.batch();
  const base = {kind: "session", title: "Substitute teacher", read: false,
    createdAt: FieldValue.serverTimestamp(),
    body: `${session.sessionTitle || "Class"} ${session.sessionDate} ` +
      `${sched.clock(session.startMinutes)}: ${subName} teaches.`};
  batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "teacher", userId: subId,
    targetRoute: "/teacher"});
  if (session.teacherId) {
    batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "teacher",
      userId: session.teacherId, targetRoute: "/teacher"});
  }
  for (const d of atts.docs) {
    if ((d.data() || {}).status === "cancelled") continue;
    batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "student",
      userId: (d.data() || {}).studentId || "", targetRoute: "/student"});
  }
  await batch.commit();
  return {teacherId: subId};
});

/**
 * Cancels one session in a transaction: every open booking comes back
 * (`sessionsBooked - 1`, the attendance doc `cancelled`), the teacher's
 * month recap counts it, the students are told to pick another session.
 * @return {Promise<number>} how many bookings were returned
 */
async function cancelSessionCore(ref, session) {
  const atts = await db.collection("attendance").where("sessionId", "==", ref.id).get();
  const told = await db.runTransaction(async (tx) => {
    const cur = (await tx.get(ref)).data() || {};
    if (cur.status === "cancelled" || cur.status === "done" || cur.isConcluded === true) {
      return null;
    }
    const rows = [];
    for (const d of atts.docs) {
      const a = (await tx.get(d.ref)).data() || {};
      if (a.booked !== true || a.sessionCredited === true || a.closed === true ||
        a.status === "cancelled") continue;
      const tRef = a.classTermId ? db.collection(CLASS_TERMS).doc(a.classTermId) : null;
      rows.push({d, a, t: tRef ? await tx.get(tRef) : null});
    }
    const recapRef = db.collection(TEACHER_RECAPS)
        .doc(`${cur.teacherId || ""}_${tday.monthKey(cur.sessionDate)}`);
    const recap = await tx.get(recapRef);
    const minus = {};
    for (const {d, a, t} of rows) {
      tx.update(d.ref, {status: "cancelled", booked: false});
      if (t && t.exists) minus[a.classTermId] = {ref: t.ref, t: t.data() || {}, n: (minus[a.classTermId] || {n: 0}).n + 1};
    }
    for (const {ref: tRef, t, n} of Object.values(minus)) {
      tx.update(tRef, {sessionsBooked: Math.max(0, (Number(t.sessionsBooked) || 0) - n)});
    }
    tx.update(ref, {status: "cancelled", isOpen: false, bookedCount: 0,
      cancelledAt: FieldValue.serverTimestamp()});
    const r = recap.exists ? recap.data() || {} : {};
    tx.set(recapRef, {teacherId: cur.teacherId || "", teacherName: cur.teacherName || "",
      month: tday.monthKey(cur.sessionDate), cancelled: (Number(r.cancelled) || 0) + 1,
      updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    return rows.map((x) => x.a.studentId);
  });
  if (told === null) return 0;
  const batch = db.batch();
  for (const sid of told) {
    batch.set(db.collection(NOTIFICATIONS).doc(), {kind: "session", title: "Class cancelled",
      body: `${session.sessionTitle || "Class"} ${session.sessionDate} ` +
        `${sched.clock(session.startMinutes)} is cancelled. Your session is back; book another.`,
      forRole: "student", userId: sid, targetRoute: "/student", read: false,
      createdAt: FieldValue.serverTimestamp()});
  }
  if (told.length) await batch.commit();
  return told.length;
}

/** Admin (or the teacher of a one-off): cancel; every booking comes back. */
exports.cancelSession = onCall(async (request) => {
  const data = request.data || {};
  const {ref, session} = await loadSession(data.sessionId);
  const {profile} = await requireSessionStaff(request, session);
  if (profile.role !== "admin" && session.scheduleId) {
    throw new HttpsError("permission-denied", "Ask the admin to cancel a timetable session.",
        {reason: "admin-only"});
  }
  if (session.status === "done" || session.isConcluded === true) {
    throw new HttpsError("failed-precondition", "This session is closed.", {reason: "done"});
  }
  const returned = await cancelSessionCore(ref, session);
  return {cancelled: true, returned};
});

/** A schedule switched off: its future sessions are cancelled the same way. */
async function cancelFutureSessions(scheduleId, nowMs = Date.now()) {
  const today = sched.jakartaDate(nowMs);
  const snap = await db.collection(CLASS_SESSIONS).where("scheduleId", "==", scheduleId).get();
  let n = 0;
  for (const d of snap.docs) {
    const s = d.data() || {};
    if (String(s.sessionDate || "") < today) continue;
    // A class that has already started today (owner 2026-11-23) is left alone.
    if (!["scheduled", "needs_teacher"].includes(tday.effectiveStatus(s, nowMs))) continue;
    await cancelSessionCore(d.ref, s);
    n += 1;
  }
  return n;
}

/**
 * The teaching-day pass over yesterday's and today's sessions: reminders
 * an hour before (once), late check-in (once, one admin notice), unclosed
 * two hours after the end.
 */
async function teachingDayPass({nowMs = Date.now(), reminders = true, flags = true} = {}) {
  const today = sched.jakartaDate(nowMs);
  const yesterday = sched.addDays(today, -1);
  const snap = await db.collection(CLASS_SESSIONS)
      .where("sessionDate", "in", [yesterday, today]).get();
  const out = {reminders: 0, started: 0, late: 0, unclosed: 0};
  for (const d of snap.docs) {
    const s = d.data() || {};
    if (flags && s.generated === true && tday.autoStartDue(s, nowMs)) {
      // Owner 2026-11-23: the session starts by itself at its start time.
      const started = await db.runTransaction(async (tx) => {
        const cur = (await tx.get(d.ref)).data() || {};
        if (!tday.autoStartDue(cur, nowMs)) return false;
        tx.update(d.ref, {status: "ongoing", autoStartedAt: FieldValue.serverTimestamp()});
        return true;
      });
      if (started) {
        out.started += 1;
        s.status = "ongoing";
      }
    }
    if (reminders && tday.reminderDue(s, nowMs)) {
      // Claim the reminder in a transaction so two runs send it once.
      const claimed = await db.runTransaction(async (tx) => {
        const cur = (await tx.get(d.ref)).data() || {};
        if (!tday.reminderDue(cur, nowMs)) return false;
        tx.update(d.ref, {reminderSentAt: FieldValue.serverTimestamp()});
        return true;
      });
      if (claimed) {
        const atts = await db.collection("attendance").where("sessionId", "==", d.id).get();
        const batch = db.batch();
        const body = `${s.sessionTitle || "Class"} at ${sched.clock(s.startMinutes)}` +
          `${s.room ? ` in ${s.room}` : ""}.`;
        const base = {kind: "reminder", title: "Class in an hour", body, read: false,
          createdAt: FieldValue.serverTimestamp()};
        if (s.teacherId) {
          batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "teacher",
            userId: s.teacherId, targetRoute: "/teacher"});
        }
        for (const a of atts.docs) {
          const ad = a.data() || {};
          if (ad.booked !== true || ad.status === "cancelled") continue;
          batch.set(db.collection(NOTIFICATIONS).doc(), {...base, forRole: "student",
            userId: ad.studentId || "", targetRoute: "/student"});
        }
        await batch.commit();
        out.reminders += 1;
      }
    }
    if (flags && tday.lateCheckInDue(s, nowMs)) {
      const flagged = await db.runTransaction(async (tx) => {
        const cur = (await tx.get(d.ref)).data() || {};
        if (!tday.lateCheckInDue(cur, nowMs)) return false;
        tx.update(d.ref, {lateCheckIn: true});
        return true;
      });
      if (flagged) {
        await db.collection(NOTIFICATIONS).add({kind: "session", title: "Late check-in",
          body: `${s.teacherName || "A teacher"} has not checked in for ${s.sessionTitle || "a class"} ` +
            `(${s.sessionDate} ${sched.clock(s.startMinutes)}).`, forRole: "admin", userId: "",
          targetRoute: "/admin/timetable", read: false, createdAt: FieldValue.serverTimestamp()});
        out.late += 1;
      }
    }
    if (flags && tday.unclosedDue(s, nowMs)) {
      await d.ref.update({unclosed: true});
      out.unclosed += 1;
    }
  }
  logger.info(`teachingDayPass: ${JSON.stringify(out)}`);
  return out;
}

/**
 * Build 2A leftover: a one-attempt exam the student opened and never
 * submitted closes itself once its clock (plus grace, plus 10 minutes) has
 * run out; an exam without a clock after 24 hours. No score is written.
 */
async function closeForgottenAttempts(nowMs = Date.now()) {
  const snap = await db.collection(EXERCISE_ATTEMPTS).get();
  let closed = 0;
  for (const d of snap.docs) {
    const a = d.data() || {};
    if (a.finishedAt) continue;
    const started = millisOf(a.startedAt);
    if (!started) continue;
    const limit = Number(a.timeLimitSeconds) || 0;
    const until = limit ? started + (limit + LATE_GRACE_SECONDS + 600) * 1000 :
      started + 24 * 3600 * 1000;
    if (nowMs < until) continue;
    // Close it once (a transaction, so a submit at the same moment wins or loses cleanly).
    const won = await db.runTransaction(async (tx) => {
      const cur = (await tx.get(d.ref)).data() || {};
      if (cur.finishedAt) return false;
      tx.update(d.ref, {finishedAt: FieldValue.serverTimestamp(), closedBy: "system",
        late: true});
      return true;
    });
    if (!won) continue;
    // Build 8: a zero result, the way a late test gets 0, so it shows in
    // the student's history and the teacher's lists.
    try {
      const exSnap = await db.collection(EXERCISES).doc(String(a.exerciseId || "")).get();
      const exercise = exSnap.exists ? exSnap.data() || {} : {};
      const items = exSnap.exists ? await loadPackageItems(exercise) : [];
      const scored = play.scoreAttempt(items, {});
      await db.collection(EXERCISE_RESULTS).doc(`${d.id}_closed`).set({
        studentId: a.studentId || "",
        exerciseId: a.exerciseId || "",
        exerciseTitle: exercise.title || "",
        category: a.category || "",
        score: 0, correct: 0, total: scored.total, earned: 0, possible: scored.possible,
        points: Object.fromEntries(Object.entries(scored.points).map(
            ([id, p]) => [id, {...p, earned: 0, review: false}])),
        status: "final",
        openMarking: 0,
        bySkill: Object.fromEntries(Object.entries(scored.bySkill).map(
            ([skill, b]) => [skill, {correct: 0, total: b.total}])),
        late: true,
        closedBy: "system",
        scoredBy: "server",
        submittedAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`closeForgottenAttempts: zero result for ${d.id}`, err);
    }
    closed += 1;
  }
  if (closed) logger.info(`closeForgottenAttempts: closed ${closed}`);
  return closed;
}

exports.sessionReminders = onSchedule(
    {schedule: "every 60 minutes", timeZone: "Asia/Jakarta"},
    async () => {
      await teachingDayPass({reminders: true, flags: false});
      await closeForgottenAttempts();
    },
);

exports.checkTeacherCheckIn = onSchedule(
    {schedule: "every 5 minutes", timeZone: "Asia/Jakarta"},
    async () => {
      await teachingDayPass({reminders: false, flags: true});
    },
);

/**
 * Admin (VC-05): every term's `sessionsUsed` against the ledger's session
 * entries that deducted, and `sessionsBooked` against the open bookings.
 */
exports.reconcileVouchers = onCall({timeoutSeconds: 300}, async (request) => {
  await requireAdmin(request);
  const [terms, ledger, atts] = await Promise.all([
    db.collection(CLASS_TERMS).get(),
    db.collection(VOUCHER_HISTORY).where("kind", "==", "session").get(),
    db.collection("attendance").where("booked", "==", true).get(),
  ]);
  const used = {};
  for (const d of ledger.docs) {
    const e = d.data() || {};
    if (Number(e.sessions) < 0 && e.termId) used[e.termId] = (used[e.termId] || 0) + 1;
  }
  const open = {};
  for (const d of atts.docs) {
    const a = d.data() || {};
    if (a.sessionCredited !== true && a.closed !== true && a.status !== "cancelled" &&
      a.classTermId) {
      open[a.classTermId] = (open[a.classTermId] || 0) + 1;
    }
  }
  const mismatches = [];
  for (const d of terms.docs) {
    const t = d.data() || {};
    // Only vouchers that go through the ledger (Build 7 onward) are checked.
    if (!used[d.id] && !open[d.id] && !(Number(t.sessionsBooked) > 0)) continue;
    // Usage from before the ledger (Build 7) is not checked.
    const base = t.ledgerBaseUsed === undefined ?
      (used[d.id] ? 0 : Number(t.sessionsUsed) || 0) : Number(t.ledgerBaseUsed) || 0;
    const m = tday.reconcileTerm({...t, sessionsUsed: (Number(t.sessionsUsed) || 0) - base},
        used[d.id] || 0, open[d.id] || 0);
    if (m.length) mismatches.push({termId: d.id, studentId: t.studentId || "", problems: m});
  }
  return {checked: terms.size, mismatches};
});

/** Admin: one row per teacher for a month (data only, no pay). */
exports.teacherRecap = onCall(async (request) => {
  await requireAdmin(request);
  const month = String((request.data || {}).month || "").replace(/\D/g, "").slice(0, 6);
  if (month.length !== 6) throw new HttpsError("invalid-argument", "month is yyyyMM.");
  const from = `${month.slice(0, 4)}-${month.slice(4)}-01`;
  const to = `${month.slice(0, 4)}-${month.slice(4)}-31`;
  const [recaps, sessions] = await Promise.all([
    db.collection(TEACHER_RECAPS).where("month", "==", month).get(),
    db.collection(CLASS_SESSIONS).where("sessionDate", ">=", from)
        .where("sessionDate", "<=", to).get(),
  ]);
  return {month, rows: tday.recapRows(recaps.docs.map((d) => d.data() || {}),
      sessions.docs.map((d) => d.data() || {}))};
});

/**
 * Admin, emulator only with a chosen time: runs the teaching-day pass now
 * (the flow test uses it; on live it uses the real clock).
 */
exports.runTeachingDayPass = onCall(async (request) => {
  await requireAdmin(request);
  const data = request.data || {};
  const emulator = process.env.FUNCTIONS_EMULATOR === "true";
  const nowMs = emulator && Number(data.nowMs) > 0 ? Number(data.nowMs) : Date.now();
  const out = await teachingDayPass({nowMs});
  if (data.attempts === true) out.attempts = await closeForgottenAttempts(nowMs);
  return out;
});

// ---------------------------------------------------------------------------
// Build 8 (docs/PLAN.md §4, Must 2): the monthly centre report, written to
// `reports/{yyyyMM}` on the 1st at 01:00 Jakarta for the month before, and
// rebuilt by an admin for any month. Pure logic in reports.js.
// ---------------------------------------------------------------------------
const reportsLogic = require("./reports");
const REPORTS = "reports";

async function buildMonthlyReport(month) {
  const range = reportsLogic.monthRange(month);
  const from = Timestamp.fromMillis(range.fromMs);
  const to = Timestamp.fromMillis(range.toMs);
  const [users, invoices, attendance, exResults, testResults, recaps] = await Promise.all([
    db.collection(USERS).where("role", "==", "student").get(),
    db.collection("invoices").where("status", "==", "paid").get(),
    db.collection("attendance").where("sessionDate", ">=", range.fromDate)
        .where("sessionDate", "<=", range.toDate).get(),
    db.collection(EXERCISE_RESULTS).where("submittedAt", ">=", from)
        .where("submittedAt", "<", to).get(),
    db.collection(TEST_RESULTS).where("createdAt", ">=", from)
        .where("createdAt", "<", to).get(),
    db.collection(TEACHER_RECAPS).where("month", "==", month).get(),
  ]);
  const rows = (snap) => snap.docs.map((d) => ({id: d.id, ...(d.data() || {})}));
  const report = reportsLogic.buildReport({
    month,
    students: rows(users).map((u) => ({uid: u.id, createdAtMs: millisOf(u.createdAt),
      level: u.level || "", status: u.status || "", active: u.active})),
    invoices: rows(invoices).map((i) => ({status: i.status, amount: i.amount,
      paidAtMs: millisOf(i.paidAt)})),
    attendance: rows(attendance).map((a) => ({studentId: a.studentId,
      sessionDate: a.sessionDate, booked: a.booked, attendanceStatus: a.attendanceStatus,
      status: a.status})),
    exerciseResults: rows(exResults).map((x) => ({studentId: x.studentId,
      submittedAtMs: millisOf(x.submittedAt)})),
    testResults: rows(testResults).map((x) => ({studentId: x.studentId,
      createdAtMs: millisOf(x.createdAt)})),
    recaps: rows(recaps),
  });
  await db.collection(REPORTS).doc(month).set({...report,
    builtAt: FieldValue.serverTimestamp()});
  return report;
}

exports.monthlyReport = onSchedule(
    {schedule: "0 1 1 * *", timeZone: "Asia/Jakarta", timeoutSeconds: 300},
    async () => {
      const month = reportsLogic.previousMonth(Date.now());
      await buildMonthlyReport(month);
      logger.info(`monthlyReport: ${month} written`);
    },
);

/** Admin: (re)build the report of any month. */
exports.rebuildMonthlyReport = onCall({timeoutSeconds: 300}, async (request) => {
  await requireAdmin(request);
  const month = String((request.data || {}).month || "");
  try {
    reportsLogic.monthRange(month);
  } catch (e) {
    throw new HttpsError("invalid-argument", e.message, {reason: "month"});
  }
  return buildMonthlyReport(month);
});
