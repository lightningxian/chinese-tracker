// Firestore security rules tests. Runs against the Firestore emulator:
//   npm --prefix rules-tests run test:emulator      (from the repo root)
// Each test seeds a small set of users with rules disabled, then checks what
// each role can do. Keep these in sync with firestore.rules.
import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, it } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  Timestamp,
} from "firebase/firestore";

const PROJECT_ID = "demo-chinese-tracker";
let env;

const USERS = {
  admin1: { role: "admin", email: "admin@test", name: "Admin", active: true },
  teacher1: { role: "teacher", email: "t1@test", name: "Guru Satu", active: true },
  teacher2: { role: "teacher", email: "t2@test", name: "Guru Nonaktif", active: false },
  teacher3: { role: "teacher", email: "t3@test", name: "Guru Tiga", active: true },
  student1: { role: "student", email: "s1@test", name: "Murid", active: true, teacherId: "teacher1", level: "HSK 1", termSize: 8 },
  student2: { role: "student", email: "s2@test", name: "Murid Dua", active: true, teacherId: "teacher3", level: "HSK 2", termSize: 8 },
  parent1: { role: "parent", email: "p1@test", name: "Orang Tua", active: true, studentIds: ["student1"], teacherIds: ["teacher1"] },
};

const NOTIFICATIONS = {
  n_student_direct: { userId: "student1", forRole: "student", title: "a", body: "", kind: "grading", read: false },
  n_student_bcast: { userId: "", forRole: "student", title: "b", body: "", kind: "session", read: false },
  n_admin_bcast: { userId: "", forRole: "admin", title: "c", body: "", kind: "registration", read: false },
  n_all_bcast: { userId: "", forRole: "all", title: "d", body: "", kind: "session", read: false },
  n_teacher_direct: { userId: "teacher1", forRole: "teacher", title: "e", body: "", kind: "grading", read: false },
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8") },
  });
});
after(async () => { await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [uid, data] of Object.entries(USERS)) await setDoc(doc(db, "users", uid), data);
    for (const [id, data] of Object.entries(NOTIFICATIONS)) await setDoc(doc(db, "notifications", id), data);
    await setDoc(doc(db, "question_bank", "q1"), { type: "multiple_choice", level: "HSK 1", createdBy: "teacher1" });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

describe("self-registration", () => {
  it("lets a student create their own profile with a teacher", async () => {
    await assertSucceeds(setDoc(doc(as("newstudent"), "users", "newstudent"), {
      role: "student", email: "n@test", name: "Baru", active: true,
      teacherId: "teacher1", level: "", termSize: 8, status: "pending",
      placementChoice: "hsk1", placementTarget: "", placementResultCode: "",
    }));
  });

  it("lets a parent create their own profile with no children linked", async () => {
    await assertSucceeds(setDoc(doc(as("newparent"), "users", "newparent"), {
      role: "parent", email: "np@test", name: "Ortu", active: true, studentIds: [], teacherIds: [],
    }));
  });

  it("refuses a self-created TEACHER profile", async () => {
    await assertFails(setDoc(doc(as("sneaky"), "users", "sneaky"), {
      role: "teacher", email: "x@test", name: "Sneaky", active: true,
    }));
  });

  it("refuses a self-created ADMIN profile", async () => {
    await assertFails(setDoc(doc(as("sneaky"), "users", "sneaky"), {
      role: "admin", email: "x@test", name: "Sneaky", active: true,
    }));
  });

  it("still lets an admin create a teacher", async () => {
    await assertSucceeds(setDoc(doc(as("admin1"), "users", "newteacher"), {
      role: "teacher", email: "nt@test", name: "Guru Baru", active: true,
    }));
  });
});

describe("deactivated accounts", () => {
  it("active teacher can read the question bank", async () => {
    await assertSucceeds(getDoc(doc(as("teacher1"), "question_bank", "q1")));
  });
  it("deactivated teacher cannot read the question bank", async () => {
    await assertFails(getDoc(doc(as("teacher2"), "question_bank", "q1")));
  });
  it("deactivated teacher cannot create a notification (staff-only write)", async () => {
    await assertFails(setDoc(doc(as("teacher2"), "notifications", "x"), {
      userId: "", forRole: "teacher", title: "t", body: "", kind: "session", read: false,
    }));
  });
  it("student still cannot read the question bank", async () => {
    await assertFails(getDoc(doc(as("student1"), "question_bank", "q1")));
  });
});

describe("settings/pricing", () => {
  it("is readable without signing in (landing page)", async () => {
    await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), "settings", "pricing")));
  });
  it("admin can write it", async () => {
    await assertSucceeds(setDoc(doc(as("admin1"), "settings", "pricing"), { package8: 2450000, package16: 3950000 }));
  });
  it("teacher and student cannot write it", async () => {
    await assertFails(setDoc(doc(as("teacher1"), "settings", "pricing"), { package8: 1 }));
    await assertFails(setDoc(doc(as("student1"), "settings", "pricing"), { package8: 1 }));
  });
});

describe("invoices", () => {
  const manual = (by) => ({
    invoiceNumber: "ES-INV-1-M1", studentId: "student1", studentName: "S", teacherId: "teacher1",
    item: "package", description: "8 class sessions", packageSize: 8, priceItemId: "package8",
    kind: "sessions", sessions: 8, amount: 2450000, currency: "IDR", status: "pending",
    paymentMethod: "manual", dueDate: "2026-11-30", createdBy: by, createdAt: Timestamp.now(),
  });
  it("staff can record a pending cash/transfer invoice", async () => {
    await assertSucceeds(setDoc(doc(as("teacher1"), "invoices", "inv_m1"), manual("teacher1")));
    await assertSucceeds(setDoc(doc(as("admin1"), "invoices", "inv_m2"), manual("admin1")));
  });
  it("a client can never create a paid or online invoice, nor settle one", async () => {
    await assertFails(setDoc(doc(as("admin1"), "invoices", "inv_m3"), { ...manual("admin1"), status: "paid" }));
    await assertFails(setDoc(doc(as("admin1"), "invoices", "inv_m4"), { ...manual("admin1"), paymentMethod: "midtrans" }));
    await assertFails(updateDoc(doc(as("admin1"), "invoices", "inv_m1"), { status: "paid" }));
  });
  it("students cannot create invoices; only admin deletes a pending one", async () => {
    await assertFails(setDoc(doc(as("student1"), "invoices", "inv_m5"), manual("student1")));
    await assertSucceeds(setDoc(doc(as("teacher1"), "invoices", "inv_m6"), manual("teacher1")));
    await assertFails(deleteDoc(doc(as("teacher1"), "invoices", "inv_m6")));
    await assertSucceeds(deleteDoc(doc(as("admin1"), "invoices", "inv_m6")));
  });
});

describe("exercise levels", () => {
  const lvl = { name: "HSK 1 · Term 1", exerciseIds: ["ex_1"], studentIds: ["student1"] };
  it("teacher and admin can write", async () => {
    await assertSucceeds(setDoc(doc(as("teacher1"), "exercise_levels", "l1"), lvl));
    await assertSucceeds(setDoc(doc(as("admin1"), "exercise_levels", "l2"), lvl));
  });
  it("student cannot read or write", async () => {
    await assertFails(getDoc(doc(as("student1"), "exercise_levels", "l1")));
    await assertFails(setDoc(doc(as("student1"), "exercise_levels", "l3"), lvl));
  });
});

describe("teacher link codes", () => {
  const codeDoc = (uid) => ({ teacherId: uid, expiresAt: Timestamp.fromMillis(Date.now() + 900000), createdAt: Timestamp.now() });
  it("a teacher can mint a code for themselves", async () => {
    await assertSucceeds(setDoc(doc(as("teacher1"), "teacher_link_codes", "ABC123"), codeDoc("teacher1")));
  });
  it("a student cannot mint a code pointing at themselves", async () => {
    await assertFails(setDoc(doc(as("student1"), "teacher_link_codes", "ZZZ999"), codeDoc("student1")));
  });
  it("a deactivated teacher cannot mint a code", async () => {
    await assertFails(setDoc(doc(as("teacher2"), "teacher_link_codes", "OLD000"), codeDoc("teacher2")));
  });
});

describe("notifications queries (must be provable by the rules)", () => {
  const col = (uid) => collection(as(uid), "notifications");

  it("student: own notifications", async () => {
    const snap = await assertSucceeds(getDocs(query(col("student1"), where("userId", "==", "student1"))));
    if (snap.size !== 1) throw new Error(`expected 1, got ${snap.size}`);
  });
  it("student: broadcasts for student + all", async () => {
    const snap = await assertSucceeds(getDocs(query(col("student1"),
      where("userId", "==", ""), where("forRole", "in", ["student", "all"]))));
    if (snap.size !== 2) throw new Error(`expected 2, got ${snap.size}`);
  });
  // Production refuses this (rules are not filters), but the emulator checks
  // list queries against the actual documents, so it passes here. Skipped.
  it.skip("student: the old broad query is refused (production only)", async () => {
    await assertFails(getDocs(col("student1")));
  });
  it("student: cannot query admin broadcasts", async () => {
    await assertFails(getDocs(query(col("student1"), where("userId", "==", ""), where("forRole", "in", ["admin"]))));
  });
  it("admin: broadcasts for admin + all", async () => {
    const snap = await assertSucceeds(getDocs(query(col("admin1"),
      where("userId", "==", ""), where("forRole", "in", ["admin", "all"]))));
    if (snap.size !== 2) throw new Error(`expected 2, got ${snap.size}`);
  });
  it("parent: 'all' broadcasts", async () => {
    const snap = await assertSucceeds(getDocs(query(col("parent1"),
      where("userId", "==", ""), where("forRole", "in", ["all"]))));
    if (snap.size !== 1) throw new Error(`expected 1, got ${snap.size}`);
  });
  it("teacher: own notifications", async () => {
    const snap = await assertSucceeds(getDocs(query(col("teacher1"), where("userId", "==", "teacher1"))));
    if (snap.size !== 1) throw new Error(`expected 1, got ${snap.size}`);
  });
});

describe("exercise results (written by finishExercise only)", () => {
  const seed = async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "exercise_results", "r_own"), { studentId: "student1", exerciseId: "e1", score: 80 });
      await setDoc(doc(db, "exercise_results", "r_other"), { studentId: "student9", exerciseId: "e1", score: 80 });
    });
  };
  it("a student cannot create a result, even for themselves", async () => {
    await assertFails(setDoc(doc(as("student1"), "exercise_results", "r_new"),
      { studentId: "student1", exerciseId: "e1", score: 100 }));
  });
  it("a student cannot change or delete a result", async () => {
    await seed();
    await assertFails(updateDoc(doc(as("student1"), "exercise_results", "r_own"), { score: 100 }));
    await assertFails(deleteDoc(doc(as("student1"), "exercise_results", "r_own")));
  });
  it("staff cannot create a result from the app either", async () => {
    await assertFails(setDoc(doc(as("teacher1"), "exercise_results", "r_t"),
      { studentId: "student1", exerciseId: "e1", score: 100 }));
    await assertFails(setDoc(doc(as("admin1"), "exercise_results", "r_a"),
      { studentId: "student1", exerciseId: "e1", score: 100 }));
  });
  it("a student, their parent and staff read it; another student cannot", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("student1"), "exercise_results", "r_own")));
    await assertSucceeds(getDoc(doc(as("parent1"), "exercise_results", "r_own")));
    await assertSucceeds(getDoc(doc(as("teacher1"), "exercise_results", "r_own")));
    await assertFails(getDoc(doc(as("student1"), "exercise_results", "r_other")));
  });
});

describe("teacher packages (2026-11-13)", () => {
  const pkg = (teacherId, extra = {}) => ({
    title: "HSK 1 A", instructions: "", teacherId, order: 0, type: "multiple_choice", level: "HSK 1",
    skillCategory: "reading", isPublished: true, questions: [], bankSheets: ["310001-RDG"],
    bankQuestionIds: [], createdAt: Timestamp.now(), ...extra,
  });
  const seed = () => env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "exercises", "own"), pkg("teacher1"));
    await setDoc(doc(db, "exercises", "other"), pkg("teacherX"));
    await setDoc(doc(db, "exercises", "legacy"), pkg("teacher1", { questions: [{ prompt: "q", options: ["a", "b"], correctIndex: 0 }], bankSheets: [] }));
  });

  it("a teacher creates a package only under their own uid, never an old-format exercise", async () => {
    await assertSucceeds(setDoc(doc(as("teacher1"), "exercises", "p1"), pkg("teacher1")));
    await assertFails(setDoc(doc(as("teacher1"), "exercises", "p2"), pkg("admin1")));
    await assertFails(setDoc(doc(as("teacher1"), "exercises", "p3"), pkg("teacher1", { questions: [{ prompt: "q" }], bankSheets: [] })));
    await assertFails(setDoc(doc(as("teacher1"), "exercises", "p4"), pkg("teacher1", { bankSheets: [], bankQuestionIds: [] })));
    await assertFails(setDoc(doc(as("teacher2"), "exercises", "p5"), pkg("teacher2")));
    await assertFails(setDoc(doc(as("student1"), "exercises", "p6"), pkg("student1")));
    await assertSucceeds(setDoc(doc(as("admin1"), "exercises", "p7"), pkg("teacherX")));
  });
  it("a teacher edits and deletes only their own packages; admins any exercise", async () => {
    await seed();
    await assertSucceeds(updateDoc(doc(as("teacher1"), "exercises", "own"), { title: "Renamed", isPublished: false }));
    await assertFails(updateDoc(doc(as("teacher1"), "exercises", "own"), { teacherId: "teacherX" }));
    await assertFails(updateDoc(doc(as("teacher1"), "exercises", "own"), { questions: [{ prompt: "q" }] }));
    await assertFails(updateDoc(doc(as("teacher1"), "exercises", "other"), { title: "x" }));
    await assertFails(updateDoc(doc(as("teacher1"), "exercises", "legacy"), { title: "x" }));
    await assertFails(deleteDoc(doc(as("teacher1"), "exercises", "other")));
    await assertFails(deleteDoc(doc(as("teacher1"), "exercises", "legacy")));
    await assertFails(deleteDoc(doc(as("student1"), "exercises", "own")));
    await assertSucceeds(deleteDoc(doc(as("teacher1"), "exercises", "own")));
    await assertSucceeds(updateDoc(doc(as("admin1"), "exercises", "other"), { title: "x" }));
    await assertSucceeds(updateDoc(doc(as("admin1"), "exercises", "legacy"), { title: "x" }));
    await assertSucceeds(deleteDoc(doc(as("admin1"), "exercises", "other")));
  });
});

describe("hardening 2026-11-12 (registration, invoices, attendance, quizzes)", () => {
  const seedSession = (id, extra = {}) => env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "class_sessions", id), {
      teacherId: "teacher1", isOpen: true, isConcluded: false, sessionDate: "2026-11-12",
      sessionTitle: "HSK 1", startMinutes: 600, endMinutes: 690, capacity: 8, ...extra,
    });
  });
  const record = (sessionId, extra = {}) => ({
    sessionId, studentId: "student1", teacherId: "teacher1", sessionDate: "2026-11-12",
    sessionTitle: "HSK 1", startMinutes: 600, endMinutes: 690, attended: true, joinedBy: "student",
    studentName: "Murid", sessionCredited: false, joinedAt: Timestamp.now(), ...extra,
  });
  const manual = {
    invoiceNumber: "ES-INV-2-M1", studentId: "student1", studentName: "S", teacherId: "teacher1",
    item: "package", description: "8 class sessions", packageSize: 8, priceItemId: "package8",
    kind: "sessions", sessions: 8, amount: 2450000, currency: "IDR", status: "pending",
    paymentMethod: "manual", dueDate: "2026-11-30", createdBy: "admin1", createdAt: Timestamp.now(),
  };

  it("a student cannot register under a made-up or deactivated teacher", async () => {
    const base = { role: "student", email: "x@test", name: "X", active: true, level: "", termSize: 8,
      status: "pending", placementChoice: "hsk1", placementTarget: "", placementResultCode: "" };
    await assertFails(setDoc(doc(as("newstudent"), "users", "newstudent"), { ...base, teacherId: "nobody" }));
    await assertFails(setDoc(doc(as("newstudent"), "users", "newstudent"), { ...base, teacherId: "teacher2" }));
    await assertSucceeds(setDoc(doc(as("newstudent"), "users", "newstudent"), { ...base, teacherId: "teacher1" }));
  });
  it("a student sets the child code once and cannot change it afterwards", async () => {
    await assertSucceeds(updateDoc(doc(as("student1"), "users", "student1"), { parentCode: "ABCDEF" }));
    await assertFails(updateDoc(doc(as("student1"), "users", "student1"), { parentCode: "AAAAAA" }));
  });
  it("a manual invoice cannot carry extra fields, inflated sessions or another student's voucher", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "student_class_terms", "t_own"), { studentId: "student1", packageSize: 8, sessionsRemaining: 8, status: "active" });
      await setDoc(doc(db, "student_class_terms", "t_other"), { studentId: "student9", packageSize: 8, sessionsRemaining: 8, status: "active" });
    });
    await assertFails(setDoc(doc(as("admin1"), "invoices", "h1"), { ...manual, midtransOrderId: "ES-INV-real" }));
    await assertFails(setDoc(doc(as("admin1"), "invoices", "h2"), { ...manual, sessions: 999, packageSize: 999 }));
    await assertFails(setDoc(doc(as("admin1"), "invoices", "h3"), { ...manual, classTermId: "t_other" }));
    await assertFails(setDoc(doc(as("admin1"), "invoices", "h4"), { ...manual, classTermId: "t_missing" }));
    await assertSucceeds(setDoc(doc(as("admin1"), "invoices", "h5"), { ...manual, classTermId: "t_own" }));
    await assertSucceeds(setDoc(doc(as("admin1"), "invoices", "h6"), { ...manual, kind: "book", item: "book", sessions: 0, packageSize: 0 }));
  });
  it("a student joins a class only as sessionId_uid, without status or voucher fields", async () => {
    await seedSession("s_open");
    await assertFails(setDoc(doc(as("student1"), "attendance", "s_open_student1"), record("s_open", { attendanceStatus: "izin" })));
    await assertFails(setDoc(doc(as("student1"), "attendance", "s_open_student1"), record("s_open", { classTermId: "t_own" })));
    await assertFails(setDoc(doc(as("student1"), "attendance", "wrong_id"), record("s_open")));
    // Build 6: students book through bookSession; no direct create any more.
    await assertFails(setDoc(doc(as("student1"), "attendance", "s_open_student1"), record("s_open")));
  });
  it("a student can leave an open class but not a concluded one", async () => {
    await seedSession("s_open");
    await seedSession("s_done", { isOpen: false, isConcluded: true });
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "attendance", "s_open_student1"), record("s_open"));
      await setDoc(doc(db, "attendance", "s_done_student1"), record("s_done", { sessionCredited: true, classTermId: "t_own" }));
    });
    // Build 6: students cancel through cancelBooking; no direct delete.
    await assertFails(deleteDoc(doc(as("student1"), "attendance", "s_open_student1")));
    await assertFails(deleteDoc(doc(as("student1"), "attendance", "s_done_student1")));
    await assertSucceeds(deleteDoc(doc(as("teacher1"), "attendance", "s_open_student1")));
  });
  it("exam attempts are readable by the student, parent and staff, never written", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "exercise_attempts", "e1_student1"), { studentId: "student1", exerciseId: "e1", category: "exam" });
    });
    await assertSucceeds(getDoc(doc(as("student1"), "exercise_attempts", "e1_student1")));
    await assertSucceeds(getDoc(doc(as("parent1"), "exercise_attempts", "e1_student1")));
    await assertSucceeds(getDoc(doc(as("teacher1"), "exercise_attempts", "e1_student1")));
    await assertFails(getDoc(doc(as("student9"), "exercise_attempts", "e1_student1")));
    await assertFails(updateDoc(doc(as("student1"), "exercise_attempts", "e1_student1"), { finishedAt: null }));
    await assertFails(setDoc(doc(as("student1"), "exercise_attempts", "e2_student1"), { studentId: "student1", exerciseId: "e2" }));
    await assertFails(getDoc(doc(as("student1"), "rate_limits", "abc")));
  });
  it("quiz results cannot be written from the app any more", async () => {
    await assertFails(setDoc(doc(as("student1"), "quiz_results", "q1"), { studentId: "student1", score: 100 }));
  });
});

describe("push tokens 2026-11-13", () => {
  const token = (uid, extra = {}) => ({ uid, platform: "web", updatedAt: Timestamp.now(), ...extra });

  it("a device registers, reads and removes its own user's token only", async () => {
    await assertSucceeds(setDoc(doc(as("student1"), "push_tokens", "tok1"), token("student1")));
    await assertSucceeds(getDoc(doc(as("student1"), "push_tokens", "tok1")));
    await assertSucceeds(updateDoc(doc(as("student1"), "push_tokens", "tok1"), { platform: "android", updatedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(as("teacher1"), "push_tokens", "tok1")));
    await assertFails(getDoc(doc(as("admin1"), "push_tokens", "tok1")));
    await assertFails(setDoc(doc(as("teacher1"), "push_tokens", "tok1"), token("teacher1")));
    await assertFails(deleteDoc(doc(as("teacher1"), "push_tokens", "tok1")));
    await assertSucceeds(deleteDoc(doc(as("student1"), "push_tokens", "tok1")));
  });
  it("a token cannot name another user, an unknown platform or extra fields", async () => {
    await assertFails(setDoc(doc(as("student1"), "push_tokens", "tok2"), token("teacher1")));
    await assertFails(setDoc(doc(as("student1"), "push_tokens", "tok3"), token("student1", { platform: "ios" })));
    await assertFails(setDoc(doc(as("student1"), "push_tokens", "tok4"), token("student1", { role: "admin" })));
  });
});

describe("supervised tests (Build 1, 2026-11-16)", () => {
  const FORMAT = { family: "hsk", level: "HSK 3", passMark: 180, provisional: false,
    parts: [{ skill: "listening", questions: 40, minutes: 40, maxScore: 100 }] };
  const CODE = { code: "H31005", family: "hsk", level: "HSK 3", releaseYear: 2021,
    sheetKey: "310001-RDG", format: { parts: FORMAT.parts, passMark: 180 },
    active: true, countsForPromotion: true };
  const seed = async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "test_formats", "hsk-3"), FORMAT);
      await setDoc(doc(db, "test_codes", "H31005"), CODE);
      await setDoc(doc(db, "test_sessions", "ts1"), { codeId: "H31005", token: "ABC234",
        openedBy: "teacher1", status: "open" });
      await setDoc(doc(db, "test_attempts", "H31005_student1"), { codeId: "H31005",
        studentId: "student1", sessionId: "ts1", partIndex: 0, answers: {} });
      await setDoc(doc(db, "test_attempts", "H31005_student9"), { codeId: "H31005",
        studentId: "student9", sessionId: "ts1", partIndex: 1, answers: {} });
      await setDoc(doc(db, "test_results", "H31005_student1"), { codeId: "H31005",
        studentId: "student1", total: 200, passMark: 180, passed: true, valid: true });
      await setDoc(doc(db, "test_results", "H31005_student9"), { codeId: "H31005",
        studentId: "student9", total: 100, passMark: 180, passed: false, valid: true });
    });
  };

  it("only admins write formats; staff read them; students cannot", async () => {
    await seed();
    await assertSucceeds(setDoc(doc(as("admin1"), "test_formats", "hsk-4"), FORMAT));
    await assertSucceeds(updateDoc(doc(as("admin1"), "test_formats", "hsk-3"), { passMark: 170 }));
    await assertFails(setDoc(doc(as("teacher1"), "test_formats", "hsk-5"), FORMAT));
    await assertFails(updateDoc(doc(as("teacher1"), "test_formats", "hsk-3"), { passMark: 1 }));
    await assertSucceeds(getDoc(doc(as("teacher1"), "test_formats", "hsk-3")));
    await assertFails(getDoc(doc(as("student1"), "test_formats", "hsk-3")));
    await assertFails(setDoc(doc(as("student1"), "test_formats", "x"), FORMAT));
  });

  it("only admins write codes; the id is the code; codes are never deleted", async () => {
    await seed();
    await assertSucceeds(setDoc(doc(as("admin1"), "test_codes", "H40001"), { ...CODE, code: "H40001" }));
    await assertFails(setDoc(doc(as("admin1"), "test_codes", "H40002"), { ...CODE, code: "OTHER" }));
    await assertFails(setDoc(doc(as("admin1"), "test_codes", "H40003"), { ...CODE, code: "H40003", sheetKey: "" }));
    await assertSucceeds(updateDoc(doc(as("admin1"), "test_codes", "H31005"), { active: false }));
    await assertFails(updateDoc(doc(as("admin1"), "test_codes", "H31005"), { sheetKey: "other" }));
    await assertFails(deleteDoc(doc(as("admin1"), "test_codes", "H31005")));
    await assertFails(setDoc(doc(as("teacher1"), "test_codes", "T1"), { ...CODE, code: "T1" }));
    await assertFails(updateDoc(doc(as("teacher1"), "test_codes", "H31005"), { active: false }));
  });

  it("PN-04 students cannot read codes (keys and worksheet stay out of reach); staff can", async () => {
    await seed();
    await assertFails(getDoc(doc(as("student1"), "test_codes", "H31005")));
    await assertFails(getDocs(collection(as("student1"), "test_codes")));
    await assertFails(getDoc(doc(as("parent1"), "test_codes", "H31005")));
    await assertSucceeds(getDoc(doc(as("teacher1"), "test_codes", "H31005")));
    await assertSucceeds(getDocs(collection(as("teacher1"), "test_codes")));
  });

  it("sessions: staff read; nobody writes from the app (tokens stay with staff)", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("teacher1"), "test_sessions", "ts1")));
    await assertSucceeds(getDoc(doc(as("admin1"), "test_sessions", "ts1")));
    await assertFails(getDoc(doc(as("student1"), "test_sessions", "ts1")));
    await assertFails(getDocs(query(collection(as("student1"), "test_sessions"), where("token", "==", "ABC234"))));
    await assertFails(setDoc(doc(as("teacher1"), "test_sessions", "ts2"), { codeId: "H31005", token: "ZZZ999" }));
    await assertFails(updateDoc(doc(as("admin1"), "test_sessions", "ts1"), { status: "closed" }));
    await assertFails(setDoc(doc(as("student1"), "test_sessions", "ts3"), { codeId: "H31005" }));
  });

  it("TS-02 attempts: a student reads only their own; staff read all; nobody writes (left-page count is server-only)", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("student1"), "test_attempts", "H31005_student1")));
    await assertFails(getDoc(doc(as("student1"), "test_attempts", "H31005_student9")));
    await assertSucceeds(getDocs(query(collection(as("student1"), "test_attempts"),
      where("studentId", "==", "student1"))));
    await assertFails(getDocs(collection(as("student1"), "test_attempts")));
    await assertSucceeds(getDocs(query(collection(as("teacher1"), "test_attempts"),
      where("sessionId", "==", "ts1"))));
    await assertFails(updateDoc(doc(as("student1"), "test_attempts", "H31005_student1"), { partIndex: 0 }));
    await assertFails(setDoc(doc(as("student1"), "test_attempts", "H40001_student1"),
      { codeId: "H40001", studentId: "student1" }));
    await assertFails(updateDoc(doc(as("teacher1"), "test_attempts", "H31005_student1"), { leftCount: 0 }));
  });

  it("PN-04 results: own, parent and staff read; another student cannot; nobody writes a score", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("student1"), "test_results", "H31005_student1")));
    await assertSucceeds(getDoc(doc(as("parent1"), "test_results", "H31005_student1")));
    await assertSucceeds(getDoc(doc(as("teacher1"), "test_results", "H31005_student9")));
    await assertFails(getDoc(doc(as("student1"), "test_results", "H31005_student9")));
    await assertFails(getDoc(doc(as("parent1"), "test_results", "H31005_student9")));
    await assertSucceeds(getDocs(query(collection(as("student1"), "test_results"),
      where("studentId", "==", "student1"))));
    await assertFails(updateDoc(doc(as("student1"), "test_results", "H31005_student1"), { total: 300 }));
    await assertFails(setDoc(doc(as("student1"), "test_results", "H40001_student1"),
      { studentId: "student1", total: 300, passed: true }));
    await assertFails(updateDoc(doc(as("teacher1"), "test_results", "H31005_student9"), { valid: false }));
    await assertFails(updateDoc(doc(as("admin1"), "test_results", "H31005_student9"), { valid: false }));
  });

  it("a deactivated teacher loses staff reads", async () => {
    await seed();
    await assertFails(getDoc(doc(as("teacher2"), "test_sessions", "ts1")));
    await assertFails(getDoc(doc(as("teacher2"), "test_attempts", "H31005_student1")));
  });
});

describe("marking queue (Build 2A)", () => {
  const item = (teacherIds) => ({
    source: "test", resultId: "H31005_student1", studentId: "student1",
    teacherIds, questionId: "q1", accepted: ["key"], status: "open",
  });
  const seed = async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "marking_items", "m_t1"), item(["teacher1"]));
      await setDoc(doc(db, "marking_items", "m_other"), item(["someone_else"]));
    });
  };

  it("PN-04 students and parents never read the queue (it holds the keys)", async () => {
    await seed();
    await assertFails(getDoc(doc(as("student1"), "marking_items", "m_t1")));
    await assertFails(getDoc(doc(as("parent1"), "marking_items", "m_t1")));
    await assertFails(getDocs(query(collection(as("student1"), "marking_items"),
      where("studentId", "==", "student1"))));
  });

  it("a teacher reads only their own queue; an admin reads all", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("teacher1"), "marking_items", "m_t1")));
    await assertFails(getDoc(doc(as("teacher1"), "marking_items", "m_other")));
    await assertSucceeds(getDocs(query(collection(as("teacher1"), "marking_items"),
      where("teacherIds", "array-contains", "teacher1"), where("status", "==", "open"))));
    await assertFails(getDocs(query(collection(as("teacher1"), "marking_items"),
      where("status", "==", "open"))));
    await assertSucceeds(getDoc(doc(as("admin1"), "marking_items", "m_other")));
    await assertFails(getDoc(doc(as("teacher2"), "marking_items", "m_t1")));
  });

  it("Build 1C: a test item is read by the session's teacher and the student's own teacher", async () => {
    await seed();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "marking_items", "m_both"),
        item(["teacher3", "teacher1"]));
    });
    // teacher3 opened the session, teacher1 is the student's own teacher.
    await assertSucceeds(getDoc(doc(as("teacher3"), "marking_items", "m_both")));
    await assertSucceeds(getDoc(doc(as("teacher1"), "marking_items", "m_both")));
    await assertSucceeds(getDocs(query(collection(as("teacher1"), "marking_items"),
      where("teacherIds", "array-contains", "teacher1"), where("status", "==", "open"))));
    await assertFails(getDoc(doc(as("teacher3"), "marking_items", "m_t1")));
  });

  it("nobody writes a mark from the app (markAnswer does)", async () => {
    await seed();
    await assertFails(updateDoc(doc(as("teacher1"), "marking_items", "m_t1"),
      { status: "marked", mark: 1 }));
    await assertFails(updateDoc(doc(as("admin1"), "marking_items", "m_t1"),
      { status: "marked", mark: 1 }));
    await assertFails(setDoc(doc(as("student1"), "marking_items", "m_new"), item(["teacher1"])));
  });
});

describe("leaderboard, promotion, level, teacher bank (Build 2B)", () => {
  const entry = { name: "陈美琳", total: 250, max: 300, passed: true };
  const seedBoard = async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "test_results", "H3A_student1"), { codeId: "H3A", studentId: "student1", total: 250 });
      await setDoc(doc(db, "leaderboards", "H3A"), { codeId: "H3A" });
      await setDoc(doc(db, "leaderboards", "H3A", "entries", "student1"), entry);
      await setDoc(doc(db, "leaderboards", "H3B"), { codeId: "H3B" });
      await setDoc(doc(db, "leaderboards", "H3B", "entries", "student2"), entry);
      await setDoc(doc(db, "level_promotions", "student1_1"),
        { studentId: "student1", status: "waiting", fromKey: "1", toKey: "2" });
      await setDoc(doc(db, "users", "student1", "level_history", "h1"), { from: "HSK 1", to: "HSK 2" });
      await setDoc(doc(db, "promotion_progress", "student1"), { count: 2, minCodes: 3 });
    });
  };

  it("LB-01 a student reads the board of a code they sat, not of another code", async () => {
    await seedBoard();
    await assertSucceeds(getDocs(collection(as("student1"), "leaderboards", "H3A", "entries")));
    await assertSucceeds(getDoc(doc(as("student1"), "leaderboards", "H3A")));
    await assertFails(getDocs(collection(as("student1"), "leaderboards", "H3B", "entries")));
    await assertFails(getDocs(collection(as("student2"), "leaderboards", "H3A", "entries")));
    await assertSucceeds(getDocs(collection(as("teacher1"), "leaderboards", "H3B", "entries")));
    await assertSucceeds(getDocs(collection(as("admin1"), "leaderboards", "H3A", "entries")));
    // A student still cannot read another student's result.
    await assertFails(getDoc(doc(as("student2"), "test_results", "H3A_student1")));
  });

  it("nobody writes a board, a recommendation or the level history from the app", async () => {
    await seedBoard();
    await assertFails(setDoc(doc(as("student1"), "leaderboards", "H3A", "entries", "student1"), entry));
    await assertFails(setDoc(doc(as("admin1"), "leaderboards", "H3A", "entries", "x"), entry));
    await assertFails(updateDoc(doc(as("admin1"), "level_promotions", "student1_1"), { status: "approved" }));
    await assertFails(setDoc(doc(as("student1"), "users", "student1", "level_history", "h2"), { to: "HSK 6" }));
  });

  it("a recommendation and the level history: own and staff only", async () => {
    await seedBoard();
    await assertSucceeds(getDoc(doc(as("student1"), "level_promotions", "student1_1")));
    await assertFails(getDoc(doc(as("student2"), "level_promotions", "student1_1")));
    await assertSucceeds(getDoc(doc(as("admin1"), "level_promotions", "student1_1")));
    await assertSucceeds(getDocs(collection(as("student1"), "users", "student1", "level_history")));
    await assertSucceeds(getDocs(collection(as("parent1"), "users", "student1", "level_history")));
    await assertFails(getDocs(collection(as("student2"), "users", "student1", "level_history")));
    await assertSucceeds(getDoc(doc(as("student1"), "promotion_progress", "student1")));
    await assertSucceeds(getDoc(doc(as("parent1"), "promotion_progress", "student1")));
    await assertFails(getDoc(doc(as("student2"), "promotion_progress", "student1")));
    await assertFails(setDoc(doc(as("student1"), "promotion_progress", "student1"), { count: 3 }));
  });

  it("the level is the admin's: a student cannot change their own", async () => {
    await assertFails(updateDoc(doc(as("student1"), "users", "student1"), { level: "HSK 6" }));
    await assertSucceeds(updateDoc(doc(as("student1"), "users", "student1"), { phone: "0812" }));
    await assertSucceeds(updateDoc(doc(as("admin1"), "users", "student1"), { level: "HSK 2" }));
  });

  it("a teacher writes only their own bank questions", async () => {
    const q = { type: "multiple_choice", level: "HSK 1" };
    await assertSucceeds(setDoc(doc(as("teacher3"), "question_bank", "t3q"), { ...q, createdBy: "teacher3" }));
    await assertFails(setDoc(doc(as("teacher3"), "question_bank", "t3x"), { ...q, createdBy: "teacher1" }));
    await assertFails(setDoc(doc(as("teacher3"), "question_bank", "t3y"), q));
    // q1 belongs to teacher1.
    await assertSucceeds(updateDoc(doc(as("teacher1"), "question_bank", "q1"), { level: "HSK 2" }));
    await assertFails(updateDoc(doc(as("teacher3"), "question_bank", "q1"), { level: "HSK 3" }));
    await assertFails(updateDoc(doc(as("teacher1"), "question_bank", "q1"), { createdBy: "teacher3" }));
    await assertSucceeds(updateDoc(doc(as("teacher3"), "question_bank", "q1"), { usageCount: 1 }));
    await assertFails(deleteDoc(doc(as("teacher3"), "question_bank", "q1")));
    await assertSucceeds(deleteDoc(doc(as("teacher1"), "question_bank", "q1")));
    await assertSucceeds(setDoc(doc(as("admin1"), "question_bank", "a1"), { ...q, createdBy: "someone" }));
    await assertFails(setDoc(doc(as("student1"), "question_bank", "s1"), { ...q, createdBy: "student1" }));
  });
});

// Build 3: pending registrations, placement results, rooms, teacher levels.
describe("registration approval and placement (Build 3)", () => {
  const pendingBase = {
    role: "student", email: "w@test", name: "Menunggu", active: true, status: "pending",
    teacherId: "", level: "", termSize: 8, placementChoice: "test",
    placementTarget: "HSK 4", placementResultCode: "",
  };
  const seedPending = async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "users", "pending1"), pendingBase);
      await setDoc(doc(db, "users", "rejected1"), { ...pendingBase, status: "rejected", rejectReason: "x" });
      await setDoc(doc(db, "exercises", "e1"), { title: "E", bankSheets: ["s"] });
      await setDoc(doc(db, "class_sessions", "c1"), { teacherId: "teacher1", isOpen: true });
      await setDoc(doc(db, "test_results", "C_pending1"), { studentId: "pending1", total: 1 });
      await setDoc(doc(db, "test_attempts", "sess_visitor"), { studentId: "", visitor: true, keyHash: "h" });
      await setDoc(doc(db, "placement_results", "sess_visitor"), { name: "V", whatsapp: "0812", resultCode: "ABCDEF" });
      await setDoc(doc(db, "notifications", "n_pending"), { userId: "pending1", forRole: "student", title: "w", body: "", kind: "registration", read: false });
    });
  };

  it("a student registers as pending with no level and no teacher", async () => {
    await assertSucceeds(setDoc(doc(as("newstudent"), "users", "newstudent"), pendingBase));
  });
  it("a student cannot register approved, with a level, or with teacher levels", async () => {
    const write = (extra) => setDoc(doc(as("newstudent"), "users", "newstudent"), { ...pendingBase, ...extra });
    await assertFails(write({ status: "active" }));
    const { status, ...noStatus } = pendingBase;
    await assertFails(setDoc(doc(as("newstudent"), "users", "newstudent"), noStatus));
    await assertFails(write({ level: "HSK 4" }));
    await assertFails(write({ levels: ["HSK 1"] }));
    await assertFails(write({ placementChoice: "skip" }));
    await assertFails(write({ approvedBy: "admin1" }));
  });
  it("a pending student reads only their own profile and their notices", async () => {
    await seedPending();
    await assertSucceeds(getDoc(doc(as("pending1"), "users", "pending1")));
    await assertSucceeds(getDoc(doc(as("pending1"), "notifications", "n_pending")));
    await assertFails(getDoc(doc(as("pending1"), "exercises", "e1")));
    await assertFails(getDoc(doc(as("pending1"), "class_sessions", "c1")));
    await assertFails(getDoc(doc(as("pending1"), "test_results", "C_pending1")));
    await assertFails(getDoc(doc(as("pending1"), "users", "teacher1")));
    await assertFails(getDoc(doc(as("pending1"), "settings", "rooms")));
    await assertFails(getDoc(doc(as("rejected1"), "exercises", "e1")));
    // An approved student (no status field) still reads them.
    await assertSucceeds(getDoc(doc(as("student1"), "exercises", "e1")));
  });
  it("a student cannot approve themselves or change their choice, level, levels or teacher", async () => {
    await seedPending();
    const self = (data) => updateDoc(doc(as("pending1"), "users", "pending1"), data);
    await assertFails(self({ status: "active" }));
    await assertFails(self({ level: "HSK 4" }));
    await assertFails(self({ levels: ["HSK 4"] }));
    await assertFails(self({ teacherId: "teacher1" }));
    await assertFails(self({ placementTarget: "HSK 6" }));
    await assertFails(self({ placementResultCode: "ZZZZZZ" }));
    await assertSucceeds(self({ whatsapp: "0812" }));
    await assertFails(updateDoc(doc(as("student1"), "users", "student1"), { status: "pending" }));
    await assertFails(updateDoc(doc(as("teacher1"), "users", "teacher1"), { levels: ["HSK 1"] }));
    await assertSucceeds(updateDoc(doc(as("admin1"), "users", "teacher1"), { levels: ["HSK 1", "HSK 2"] }));
  });
  it("placement results and visitor attempts: staff only, no client writes", async () => {
    await seedPending();
    await assertSucceeds(getDoc(doc(as("teacher1"), "placement_results", "sess_visitor")));
    await assertSucceeds(getDoc(doc(as("admin1"), "placement_results", "sess_visitor")));
    await assertFails(getDoc(doc(as("student1"), "placement_results", "sess_visitor")));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "placement_results", "sess_visitor")));
    await assertFails(setDoc(doc(as("admin1"), "placement_results", "x"), { resultCode: "AAAAAA" }));
    await assertSucceeds(getDoc(doc(as("teacher1"), "test_attempts", "sess_visitor")));
    await assertFails(getDoc(doc(as("student1"), "test_attempts", "sess_visitor")));
  });
  it("settings/rooms: everyone signed in reads, only the admin writes", async () => {
    await assertSucceeds(setDoc(doc(as("admin1"), "settings", "rooms"), { names: ["Main", "Sub Room"] }));
    await assertSucceeds(getDoc(doc(as("teacher1"), "settings", "rooms")));
    await assertSucceeds(getDoc(doc(as("student1"), "settings", "rooms")));
    await assertFails(setDoc(doc(as("teacher1"), "settings", "rooms"), { names: ["Room 9"] }));
  });
});

// Build 4: the progress summary and teachers' follow-up notes.
describe("progress summary and notes (Build 4)", () => {
  const seed = async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "progress_summary", "student1"), { status: "good", warnings: [] });
      await setDoc(doc(db, "progress_summary", "student2"), { status: "attention", warnings: [] });
      await setDoc(doc(db, "progress_notes", "n1"), { studentId: "student1", teacherId: "teacher1", teacherName: "Guru", text: "Bagus" });
    });
  };
  const note = (extra = {}) => ({ studentId: "student1", teacherId: "teacher1", teacherName: "Guru", text: "Rajin", ...extra });

  it("the student, staff and the linked parent read a summary; nobody writes it", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("student1"), "progress_summary", "student1")));
    await assertFails(getDoc(doc(as("student1"), "progress_summary", "student2")));
    await assertSucceeds(getDoc(doc(as("parent1"), "progress_summary", "student1")));
    await assertFails(getDoc(doc(as("parent1"), "progress_summary", "student2")));
    await assertSucceeds(getDoc(doc(as("teacher3"), "progress_summary", "student1")));
    await assertSucceeds(getDoc(doc(as("admin1"), "progress_summary", "student2")));
    await assertFails(setDoc(doc(as("admin1"), "progress_summary", "student1"), { status: "good" }));
    await assertFails(setDoc(doc(as("student1"), "progress_summary", "student1"), { status: "good" }));
  });
  it("a teacher adds notes for their own students only; a student never", async () => {
    await assertSucceeds(setDoc(doc(as("teacher1"), "progress_notes", "a"), note()));
    await assertFails(setDoc(doc(as("teacher3"), "progress_notes", "b"), note({ teacherId: "teacher3" })),
      "student1 belongs to teacher1");
    await assertFails(setDoc(doc(as("teacher1"), "progress_notes", "c"), note({ teacherId: "teacher3" })));
    await assertFails(setDoc(doc(as("teacher1"), "progress_notes", "d"), note({ text: "x".repeat(501) })));
    await assertFails(setDoc(doc(as("student1"), "progress_notes", "e"), note({ teacherId: "student1" })));
    await assertSucceeds(setDoc(doc(as("admin1"), "progress_notes", "f"), note({ teacherId: "admin1", studentId: "student2" })));
  });
  it("notes: the student and the parent read; the author or an admin edits; another teacher cannot", async () => {
    await seed();
    await assertSucceeds(getDoc(doc(as("student1"), "progress_notes", "n1")));
    await assertSucceeds(getDoc(doc(as("parent1"), "progress_notes", "n1")));
    await assertFails(getDoc(doc(as("student2"), "progress_notes", "n1")));
    await assertSucceeds(updateDoc(doc(as("teacher1"), "progress_notes", "n1"), { text: "Lebih baik" }));
    await assertFails(updateDoc(doc(as("teacher3"), "progress_notes", "n1"), { text: "Bukan saya" }));
    await assertFails(updateDoc(doc(as("teacher1"), "progress_notes", "n1"), { studentId: "student2" }));
    await assertFails(deleteDoc(doc(as("teacher3"), "progress_notes", "n1")));
    await assertSucceeds(deleteDoc(doc(as("admin1"), "progress_notes", "n1")));
  });
});

// Build 5: the voucher ledger; invoices stay closed to client writes.
describe("voucher ledger (Build 5)", () => {
  it("the student, staff and the linked parent read an entry; nobody writes", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "voucher_history", "inv1_purchase"), { kind: "purchase", studentId: "student1", sessions: 8 });
    });
    await assertSucceeds(getDoc(doc(as("student1"), "voucher_history", "inv1_purchase")));
    await assertSucceeds(getDoc(doc(as("parent1"), "voucher_history", "inv1_purchase")));
    await assertSucceeds(getDoc(doc(as("teacher3"), "voucher_history", "inv1_purchase")));
    await assertFails(getDoc(doc(as("student2"), "voucher_history", "inv1_purchase")));
    await assertFails(setDoc(doc(as("admin1"), "voucher_history", "x"), { kind: "purchase", studentId: "student1" }));
    await assertFails(setDoc(doc(as("student1"), "voucher_history", "y"), { kind: "purchase", studentId: "student1" }));
  });
  it("a student cannot create or flip an invoice", async () => {
    await assertFails(setDoc(doc(as("student1"), "invoices", "self"), {
      invoiceNumber: "X", studentId: "student1", amount: 1, status: "pending", paymentMethod: "manual",
      kind: "sessions", sessions: 8, packageSize: 8, createdBy: "student1" }));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "invoices", "inv2"), { studentId: "student1", status: "pending", amount: 1 });
    });
    await assertFails(updateDoc(doc(as("student1"), "invoices", "inv2"), { status: "paid" }));
    await assertFails(updateDoc(doc(as("admin1"), "invoices", "inv2"), { status: "paid" }));
  });
});

// Build 6: the timetable is written by functions; days off by the teacher.
describe("timetable (Build 6)", () => {
  it("schedules: approved users read, nobody writes; locks closed", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "schedules", "sc1"), { className: "A", teacherId: "teacher1", weekday: 1 });
      await setDoc(doc(ctx.firestore(), "schedule_locks", "teacher1"), { version: 1 });
    });
    await assertSucceeds(getDoc(doc(as("student1"), "schedules", "sc1")));
    await assertSucceeds(getDoc(doc(as("teacher3"), "schedules", "sc1")));
    await assertFails(setDoc(doc(as("admin1"), "schedules", "sc2"), { className: "B" }));
    await assertFails(getDoc(doc(as("admin1"), "schedule_locks", "teacher1")));
    await assertFails(setDoc(doc(as("admin1"), "schedule_locks", "teacher1"), { version: 9 }));
  });
  it("days off: the teacher writes their own, the admin any; staff read", async () => {
    await assertSucceeds(setDoc(doc(as("teacher1"), "teacher_days_off", "d1"), { teacherId: "teacher1", date: "2026-12-01", reason: "x" }));
    await assertFails(setDoc(doc(as("teacher3"), "teacher_days_off", "d2"), { teacherId: "teacher1", date: "2026-12-01" }));
    await assertSucceeds(setDoc(doc(as("admin1"), "teacher_days_off", "d3"), { teacherId: "teacher3", date: "2026-12-02" }));
    await assertSucceeds(getDoc(doc(as("teacher3"), "teacher_days_off", "d1")));
    await assertFails(getDoc(doc(as("student1"), "teacher_days_off", "d1")));
    await assertFails(deleteDoc(doc(as("teacher3"), "teacher_days_off", "d1")));
    await assertSucceeds(deleteDoc(doc(as("teacher1"), "teacher_days_off", "d1")));
  });
  it("a client cannot set scheduleId on a session; a teacher edits their availability", async () => {
    await assertFails(setDoc(doc(as("teacher1"), "class_sessions", "gen"), { teacherId: "teacher1", scheduleId: "sc1", sessionDate: "2026-12-01" }));
    await assertSucceeds(setDoc(doc(as("teacher1"), "class_sessions", "own"), { teacherId: "teacher1", sessionDate: "2026-12-01" }));
    await assertSucceeds(updateDoc(doc(as("teacher1"), "users", "teacher1"), { availability: { "1": [{ startMinutes: 900, endMinutes: 1200 }] } }));
  });
});

describe("generated sessions (Build 6)", () => {
  it("students and parents read the generated timetable of every teacher", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "class_sessions", "sch_x_20270105"), { teacherId: "teacher3", scheduleId: "sch_x", generated: true, sessionDate: "2027-01-05" });
      await setDoc(doc(ctx.firestore(), "class_sessions", "oneoff_t3"), { teacherId: "teacher3", sessionDate: "2027-01-05" });
    });
    await assertSucceeds(getDoc(doc(as("student1"), "class_sessions", "sch_x_20270105")));
    await assertSucceeds(getDoc(doc(as("parent1"), "class_sessions", "sch_x_20270105")));
    await assertFails(getDoc(doc(as("student1"), "class_sessions", "oneoff_t3")), "another teacher's one-off");
    await assertFails(setDoc(doc(as("teacher3"), "class_sessions", "fake"), { teacherId: "teacher3", generated: true, sessionDate: "2027-01-06" }));
  });
});

// Build 7: the session's life and the voucher counters are written by
// functions; staff keep only the attendance notes.
describe("teaching day (Build 7)", () => {
  it("session status fields are closed to clients; the teacher still edits a one-off", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "class_sessions", "o7"), { teacherId: "teacher1", sessionDate: "2027-01-05", isOpen: true, isConcluded: false });
      await setDoc(doc(ctx.firestore(), "class_sessions", "g7"), { teacherId: "teacher1", scheduleId: "sc", generated: true, sessionDate: "2027-01-05", status: "scheduled" });
    });
    await assertSucceeds(updateDoc(doc(as("teacher1"), "class_sessions", "o7"), { sessionTitle: "New title", isOpen: false }));
    for (const f of [{ status: "done" }, { isConcluded: true }, { checkInAt: 1 }, { lateCheckIn: false }, { teacherId: "teacher3" }, { bookedCount: 0 }]) {
      await assertFails(updateDoc(doc(as("teacher1"), "class_sessions", "o7"), f));
      await assertFails(updateDoc(doc(as("admin1"), "class_sessions", "g7"), f));
    }
    await assertFails(setDoc(doc(as("teacher1"), "class_sessions", "x7"), { teacherId: "teacher1", sessionDate: "2027-01-06", status: "done" }));
    await assertFails(deleteDoc(doc(as("admin1"), "class_sessions", "g7")), "generated: cancel instead");
    await assertSucceeds(deleteDoc(doc(as("teacher1"), "class_sessions", "o7")));
  });
  it("attendance: staff change notes only; a booking is not deleted by hand", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "attendance", "g7_student1"), { sessionId: "g7", studentId: "student1", teacherId: "teacher1", booked: true, classTermId: "t1", sessionCredited: false });
      await setDoc(doc(ctx.firestore(), "attendance", "o7_student2"), { sessionId: "o7", studentId: "student2", teacherId: "teacher1", attended: true, joinedBy: "teacher", sessionCredited: false });
    });
    await assertSucceeds(updateDoc(doc(as("teacher1"), "attendance", "g7_student1"), { notes: "came late" }));
    await assertFails(updateDoc(doc(as("teacher1"), "attendance", "g7_student1"), { attendanceStatus: "hadir" }));
    await assertFails(updateDoc(doc(as("admin1"), "attendance", "g7_student1"), { sessionCredited: true }));
    await assertFails(deleteDoc(doc(as("teacher1"), "attendance", "g7_student1")));
    await assertSucceeds(deleteDoc(doc(as("teacher1"), "attendance", "o7_student2")), "a walk-in before the close");
  });
  it("change requests and recaps: functions write; the teacher reads their own", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "schedule_change_requests", "r1"), { teacherId: "teacher1", status: "open" });
      await setDoc(doc(ctx.firestore(), "teacher_recaps", "teacher1_202701"), { teacherId: "teacher1", held: 1 });
    });
    await assertSucceeds(getDoc(doc(as("teacher1"), "schedule_change_requests", "r1")));
    await assertFails(getDoc(doc(as("teacher3"), "schedule_change_requests", "r1")));
    await assertSucceeds(getDoc(doc(as("admin1"), "schedule_change_requests", "r1")));
    await assertFails(setDoc(doc(as("teacher1"), "schedule_change_requests", "r2"), { teacherId: "teacher1", status: "open" }));
    await assertFails(updateDoc(doc(as("admin1"), "schedule_change_requests", "r1"), { status: "done" }));
    await assertSucceeds(getDoc(doc(as("teacher1"), "teacher_recaps", "teacher1_202701")));
    await assertFails(getDoc(doc(as("student1"), "teacher_recaps", "teacher1_202701")));
    await assertFails(setDoc(doc(as("admin1"), "teacher_recaps", "teacher1_202701"), { held: 9 }));
  });
});
