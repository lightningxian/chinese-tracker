// End-to-end check of the supervised test track against the local emulator
// suite (auth 9099, firestore 8080, functions 5001), using the seeded data
// (scripts/seed_emulator.py: test code H3DEMO1, packages pkg_practice and
// pkg_exam). Run after seeding:
//   node functions/test_supervised_flow.mjs
// Thesis scenario IDs (docs/THESIS_FEATURE_BACKLOG.md §13) are in the step
// names: TS-01, TS-02, PN-02..05, LV-01..03, LB-01, PL-01, PL-02 (Build 4: progress).
import assert from "node:assert/strict";

const PROJECT = "chinese-tracker";
const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1";
const FS = `http://127.0.0.1:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const FN = `http://127.0.0.1:5001/${PROJECT}/us-central1`;
const PASSWORD = "emulator-only-7"; // scripts/seed_emulator.py (not the live one)
const CODE = "H3DEMO1";

let passed = 0;
const step = async (name, fn) => {
  await fn();
  passed += 1;
  console.log(`ok - ${name}`);
};

async function signIn(email) {
  const r = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: "POST", headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password: PASSWORD, returnSecureToken: true}),
  });
  const j = await r.json();
  assert.ok(j.idToken, `sign in ${email}: ${JSON.stringify(j).slice(0, 200)}`);
  return {token: j.idToken, uid: j.localId};
}

/** Calls a callable; resolves {data} or {error: {status, details}}. */
async function call(user, name, data) {
  const r = await fetch(`${FN}/${name}`, {
    method: "POST",
    headers: {"Content-Type": "application/json", Authorization: `Bearer ${user.token}`},
    body: JSON.stringify({data}),
  });
  const j = await r.json();
  return j.error ? {error: j.error} : {data: j.result};
}

const reasonOf = (res) => res.error && res.error.details && res.error.details.reason;

/** Reads a doc with rules bypassed ("Bearer owner"), plain JS values. */
async function readDoc(path) {
  const r = await fetch(`${FS}/${path}`, {headers: {Authorization: "Bearer owner"}});
  if (r.status === 404) return null;
  const j = await r.json();
  const val = (v) => {
    if ("integerValue" in v) return Number(v.integerValue);
    if ("doubleValue" in v) return v.doubleValue;
    if ("booleanValue" in v) return v.booleanValue;
    if ("stringValue" in v) return v.stringValue;
    if ("timestampValue" in v) return new Date(v.timestampValue);
    if ("nullValue" in v) return null;
    if ("arrayValue" in v) return (v.arrayValue.values || []).map(val);
    if ("mapValue" in v) {
      return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, val(x)]));
    }
    return v;
  };
  return Object.fromEntries(Object.entries(j.fields || {}).map(([k, v]) => [k, val(v)]));
}

async function patchDoc(path, fields) {
  const mask = Object.keys(fields).map((k) => `updateMask.fieldPaths=${k}`).join("&");
  const r = await fetch(`${FS}/${path}?${mask}`, {
    method: "PATCH",
    headers: {"Content-Type": "application/json", Authorization: "Bearer owner"},
    body: JSON.stringify({fields}),
  });
  assert.ok(r.ok, `patch ${path}: ${r.status}`);
}

async function deleteDoc(path) {
  await fetch(`${FS}/${path}`, {method: "DELETE", headers: {Authorization: "Bearer owner"}});
}

const ts = (ms) => ({timestampValue: new Date(ms).toISOString()});

// ---------------------------------------------------------------------------
const teacher = await signIn("teacher@test.chinesetracker");
const admin = await signIn("admin@test.chinesetracker");
const s1 = await signIn("student1@test.chinesetracker");
const s2 = await signIn("student2@test.chinesetracker");
const s3 = await signIn("student3@test.chinesetracker");

// Start clean so the flow can run again after a re-seed.
for (const s of [s1, s2, s3]) {
  await deleteDoc(`test_attempts/${CODE}_${s.uid}`);
  await deleteDoc(`test_results/${CODE}_${s.uid}`);
}

let session;
await step("open a session: 6-character token without 0/O/1/I, 15-minute window", async () => {
  const r = await call(teacher, "openTestSession", {codeId: CODE});
  assert.ok(r.data, JSON.stringify(r.error));
  session = r.data;
  assert.match(session.token, /^[A-HJ-NP-Z2-9]{6}$/);
  const left = (session.joinUntilMillis - Date.now()) / 1000;
  assert.ok(left > 890 && left <= 900, `join window ${left}s`);
});

await step("a student cannot open a session", async () => {
  const r = await call(s1, "openTestSession", {codeId: CODE});
  assert.equal(r.error.status, "PERMISSION_DENIED");
});

await step("TS-01 no token is refused", async () => {
  const r = await call(s1, "startTest", {});
  assert.equal(reasonOf(r), "bad-token");
});

await step("TS-01 a wrong token is refused", async () => {
  const r = await call(s1, "startTest", {token: "ZZZZZZ"});
  assert.equal(reasonOf(r), "bad-token");
});

await step("TS-01 a token older than 15 minutes is refused", async () => {
  const old = await call(teacher, "openTestSession", {codeId: CODE});
  await patchDoc(`test_sessions/${old.data.sessionId}`, {joinUntil: ts(Date.now() - 1000)});
  const r = await call(s1, "startTest", {token: old.data.token});
  assert.equal(reasonOf(r), "join-closed");
  await call(teacher, "closeTestSession", {sessionId: old.data.sessionId});
});

await step("TS-01 many wrong tokens are blocked for a while (per student)", async () => {
  let last;
  for (let i = 0; i < 9; i++) last = await call(s3, "startTest", {token: "YYYYYY"});
  assert.equal(reasonOf(last), "token-blocked");
  // Another student on the same Wi-Fi is not blocked.
  const other = await call(s2, "startTest", {token: "YYYYYY"});
  assert.equal(reasonOf(other), "bad-token");
});

let part;
await step("peek shows the start screen facts only (no questions, no clock)", async () => {
  const r = await call(s1, "startTest", {token: session.token, peek: true});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.code, CODE);
  assert.equal(r.data.parts.length, 3);
  assert.equal(r.data.questions, undefined);
  assert.equal(await readDoc(`test_attempts/${CODE}_${s1.uid}`), null);
});

await step("PN-04 start: part 1 only, questions without keys or explanations", async () => {
  const r = await call(s1, "startTest", {token: session.token});
  assert.ok(r.data, JSON.stringify(r.error));
  part = r.data;
  assert.equal(part.partIndex, 0);
  assert.equal(part.skill, "listening");
  assert.equal(part.questions.length, 4);
  assert.ok(part.secondsLeft > 110 && part.secondsLeft <= 120);
  assert.ok(part.recordingUrl.endsWith("hsk3_listening.wav"));
  for (const q of part.questions) {
    assert.ok(!("correctIndex" in q) && !("explanation" in q), "no key leaves the server");
  }
});

await step("reload: the same part and clock come back (resume by code)", async () => {
  const r = await call(s1, "startTest", {codeId: CODE});
  assert.equal(r.data.partIndex, 0);
  assert.ok(Math.abs(r.data.secondsLeft - part.secondsLeft) <= 3);
  assert.ok(r.data.elapsedSeconds >= 0);
});

await step("TS-02 leaving the page and coming back is saved for the teacher", async () => {
  await call(s1, "reportTestEvent", {codeId: CODE, type: "left"});
  await call(s1, "reportTestEvent", {codeId: CODE, type: "back"});
  // A repeat within 2 seconds is throttled.
  const again = await call(s1, "reportTestEvent", {codeId: CODE, type: "back"});
  assert.equal(again.data.recorded, false);
  const a = await readDoc(`test_attempts/${CODE}_${s1.uid}`);
  assert.equal(a.leftCount, 1);
  assert.deepEqual(a.events.map((e) => e.type), ["left", "back"]);
});

await step("submit part 1 → part 2 opens with its own clock", async () => {
  const r = await call(s1, "submitTestPart", {codeId: CODE, partIndex: 0, answers: {
    tq_l1: {index: 0}, tq_l2: {index: 2}, tq_l3: {index: 0}, tq_l4: {index: 1},
  }});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.partIndex, 1);
  assert.equal(r.data.skill, "reading");
  assert.equal(r.data.codeId, CODE, "the next part carries the test facts too");
  assert.equal(r.data.partClocks, true);
  assert.equal(r.data.recordingUrl, "", "no recording outside listening");
});

await step("going back to a closed part is refused by the function", async () => {
  const r = await call(s1, "submitTestPart", {codeId: CODE, partIndex: 0, answers: {}});
  assert.equal(reasonOf(r), "part-closed");
});

await step("PN-05 answers after the server deadline are not counted", async () => {
  // Part 2 started 10 minutes ago: past its 2-minute clock plus 3 minutes grace.
  const a = await readDoc(`test_attempts/${CODE}_${s1.uid}`);
  await patchDoc(`test_attempts/${CODE}_${s1.uid}`, {partStartedAt: {arrayValue: {values: [
    ts(a.partStartedAt[0].getTime()), ts(Date.now() - 10 * 60 * 1000)]}}});
  const r = await call(s1, "submitTestPart", {codeId: CODE, partIndex: 1, answers: {
    tq_r1: {index: 0}, tq_r2: {index: 0}, tq_r3: {index: 0}, tq_r4: {index: 0},
  }});
  assert.equal(r.data.partIndex, 2);
  const after = await readDoc(`test_attempts/${CODE}_${s1.uid}`);
  assert.deepEqual(after.answers["1"], {}, "late answers stored as empty");
  assert.deepEqual(after.lateParts, [1]);
});

let result;
await step("finish: the result has marks per part, total, pass mark, duration", async () => {
  const r = await call(s1, "submitTestPart", {codeId: CODE, partIndex: 2, answers: {
    tq_w1: {text: "刚"}, tq_w2: {text: "等"}, tq_w3: {order: ["经理的", "办公室在", "二楼"]},
  }});
  assert.equal(r.data.finished, true);
  result = await readDoc(`test_results/${r.data.resultId}`);
  assert.deepEqual(result.parts.map((p) => p.mark), [100, 0, 100]);
  assert.equal(result.total, 200);
  assert.equal(result.max, 300);
  assert.equal(result.passMark, 180);
  assert.equal(result.passed, true);
  assert.equal(result.valid, true);
  assert.equal(result.levelKey, "3");
  assert.match(result.resultNumber, /^ES-\d{8}-[A-Z2-9]{6}$/);
  assert.ok(Number.isInteger(result.durationSeconds) && result.durationSeconds >= 0);
  assert.equal(result.supervisorName, "Test Teacher");
});

await step("LV-02 the same code a second time is refused, even with a fresh token", async () => {
  const fresh = await call(teacher, "openTestSession", {sessionId: session.sessionId});
  assert.notEqual(fresh.data.token, session.token);
  const r = await call(s1, "startTest", {token: fresh.data.token});
  assert.equal(reasonOf(r), "already-attempted");
  session = {...session, token: fresh.data.token};
});

await step("the review is refused while the session is open", async () => {
  const r = await call(s1, "getTestReview", {codeId: CODE});
  assert.equal(reasonOf(r), "session-open");
});

await step("End test for everyone: a student who stopped after part 1 gets 0 for later parts", async () => {
  const st = await call(s2, "startTest", {token: session.token});
  assert.ok(st.data, JSON.stringify(st.error));
  await call(s2, "submitTestPart", {codeId: CODE, partIndex: 0, answers: {tq_l1: {index: 0}}});
  const closed = await call(teacher, "closeTestSession", {sessionId: session.sessionId});
  assert.equal(closed.data.finished, 1);
  const r2 = await readDoc(`test_results/${CODE}_${s2.uid}`);
  assert.deepEqual(r2.parts.map((p) => p.mark), [25, 0, 0]);
  const sess = await readDoc(`test_sessions/${session.sessionId}`);
  assert.equal(sess.status, "closed");
});

await step("once the session is closed the review opens: answers, keys, explanations", async () => {
  const r = await call(s1, "getTestReview", {codeId: CODE});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.items.length, 11);
  const first = r.data.items[0];
  assert.equal(first.review.correctAnswer.index, 0);
  assert.ok(first.review.explanation.length > 0);
  assert.deepEqual(first.answer, {index: 0});
  assert.ok(r.data.recordings["0"].endsWith("hsk3_listening.wav"));
});

await step("mark invalid needs a reason; invalid never passes; valid again restores", async () => {
  const id = `${CODE}_${s1.uid}`;
  const noReason = await call(teacher, "setTestResultValidity", {resultId: id, valid: false});
  assert.equal(reasonOf(noReason), "reason-required");
  await call(teacher, "setTestResultValidity", {resultId: id, valid: false, reason: "HP dibuka"});
  let r = await readDoc(`test_results/${id}`);
  assert.equal(r.valid, false);
  assert.equal(r.passed, false);
  assert.equal(r.invalidReason, "HP dibuka");
  await call(admin, "setTestResultValidity", {resultId: id, valid: true});
  r = await readDoc(`test_results/${id}`);
  assert.equal(r.valid, true);
  assert.equal(r.passed, true);
});

await step("another teacher cannot change a result of this session", async () => {
  const other = await signIn("andrea@test.chinesetracker");
  const r = await call(other, "setTestResultValidity",
      {resultId: `${CODE}_${s1.uid}`, valid: false, reason: "x"});
  assert.equal(r.error.status, "PERMISSION_DENIED");
});

await step("session option: one clock for the whole paper, every question, one submit", async () => {
  const s4 = await signIn("student4@test.chinesetracker");
  await deleteDoc(`test_attempts/${CODE}_${s4.uid}`);
  await deleteDoc(`test_results/${CODE}_${s4.uid}`);
  const open = await call(teacher, "openTestSession", {codeId: CODE, partClocks: false});
  const st = await call(s4, "startTest", {token: open.data.token});
  assert.ok(st.data, JSON.stringify(st.error));
  assert.equal(st.data.partClocks, false);
  assert.equal(st.data.partCount, 1);
  assert.equal(st.data.questions.length, 11);
  assert.ok(st.data.secondsLeft > 350 && st.data.secondsLeft <= 360, "2 + 2 + 2 minutes");
  assert.ok(st.data.recordingUrl.endsWith("hsk3_listening.wav"));
  const fin = await call(s4, "submitTestPart", {codeId: CODE, partIndex: 0, answers: {
    tq_l1: {index: 0}, tq_r1: {index: 0}, tq_r2: {index: 0}, tq_w1: {text: "刚"},
  }});
  assert.equal(fin.data.finished, true);
  const r = await readDoc(`test_results/${CODE}_${s4.uid}`);
  assert.deepEqual(r.parts.map((p) => p.mark), [25, 50, 33]);
  await call(teacher, "closeTestSession", {sessionId: open.data.sessionId});
});

await step("HSK simulation packages are refused and point to Tests", async () => {
  await patchDoc("exercises/pkg_hsk_sim", {
    title: {stringValue: "HSK sim as package"}, isPublished: {booleanValue: true},
    bankSheets: {arrayValue: {values: [{stringValue: "310901-KK"}]}},
    teacherId: {stringValue: admin.uid},
  });
  await patchDoc(`exercise_assignments/pkg_hsk_sim_${s1.uid}`, {
    exerciseId: {stringValue: "pkg_hsk_sim"}, studentId: {stringValue: s1.uid},
  });
  const r = await call(s1, "startExercise", {exerciseId: "pkg_hsk_sim"});
  assert.equal(reasonOf(r), "hsk-simulation-in-tests");
  const f = await call(s1, "finishExercise", {exerciseId: "pkg_hsk_sim", answers: {}});
  assert.equal(reasonOf(f), "hsk-simulation-in-tests");
  await deleteDoc("exercises/pkg_hsk_sim");
  await deleteDoc(`exercise_assignments/pkg_hsk_sim_${s1.uid}`);
});

await step("regression: a practice package still plays end to end", async () => {
  const st = await call(s1, "startExercise", {exerciseId: "pkg_practice"});
  assert.ok(st.data, JSON.stringify(st.error));
  assert.equal(st.data.oneAttempt, false);
  const fin = await call(s1, "finishExercise", {exerciseId: "pkg_practice",
    answers: {pq_1: {index: 0}, pq_2: {index: 1}}});
  assert.equal(fin.data.score, 100);
});

await step("regression: an exam package is still one attempt with a server clock", async () => {
  await deleteDoc(`exercise_attempts/pkg_exam_${s2.uid}`);
  const peek = await call(s2, "startExercise", {exerciseId: "pkg_exam", peek: true});
  assert.equal(peek.data.oneAttempt, true);
  const st = await call(s2, "startExercise", {exerciseId: "pkg_exam"});
  assert.ok(st.data.remainingSeconds > 590);
  const fin = await call(s2, "finishExercise", {exerciseId: "pkg_exam",
    answers: {eq_1: {index: 0}, eq_2: {index: 1}}});
  assert.equal(fin.data.score, 50);
  const again = await call(s2, "startExercise", {exerciseId: "pkg_exam"});
  assert.equal(reasonOf(again), "already-attempted");
});

// ---------------------------------------------------------------------------
// Build 2A: typing matcher, marking queue, end-session keeps typed work,
// the hourly job, Reset attempt. Seed: package pkg_typing, code H3ESSAY.
// ---------------------------------------------------------------------------
const ESSAY = "H3ESSAY";

/** Docs of a collection where field == value (rules bypassed). */
async function queryDocs(collection, field, value) {
  const r = await fetch(`${FS}:runQuery`, {
    method: "POST",
    headers: {"Content-Type": "application/json", Authorization: "Bearer owner"},
    body: JSON.stringify({structuredQuery: {from: [{collectionId: collection}],
      where: {fieldFilter: {field: {fieldPath: field}, op: "EQUAL",
        value: {stringValue: value}}}}}),
  });
  const rows = await r.json();
  return rows.filter((x) => x.document).map((x) => ({
    id: x.document.name.split("/").pop(),
    fields: x.document.fields || {},
  }));
}
const str = (f, k) => (f[k] && f[k].stringValue) || "";

const s5 = await signIn("student5@test.chinesetracker");
const s6 = await signIn("student6@test.chinesetracker");
for (const s of [s5, s6]) {
  await deleteDoc(`test_attempts/${ESSAY}_${s.uid}`);
  await deleteDoc(`test_results/${ESSAY}_${s.uid}`);
}

let typingResultId;
await step("PN-02/PN-03 package typing: pinyin with tone numbers is full, a homophone is half and queued, word order swapped is zero", async () => {
  const st = await call(s1, "startExercise", {exerciseId: "pkg_typing"});
  assert.ok(st.data, JSON.stringify(st.error));
  const py = st.data.questions.find((q) => q.id === "ty_2");
  assert.equal(py.type, "type_pinyin");
  assert.ok(!("options" in py), "pinyin keys stay on the server");
  const fin = await call(s1, "finishExercise", {exerciseId: "pkg_typing", answers: {
    ty_1: {text: "我很喜欢和茶"}, ty_2: {text: "ni3 hao3"},
    ty_3: {order: ["放在", "把书", "桌子上"]},
  }});
  assert.ok(fin.data, JSON.stringify(fin.error));
  assert.equal(fin.data.status, "pending_marking");
  assert.deepEqual(fin.data.review.map((r) => r.credit), [0.5, 1, 0]);
  assert.deepEqual(fin.data.review.map((r) => r.needsMarking), [true, false, false]);
  assert.equal(fin.data.score, 50, "1.5 of 3 points");
  typingResultId = fin.data.resultId;
  const item = await readDoc(`marking_items/${typingResultId}_ty_1`);
  assert.equal(item.status, "open");
  assert.equal(item.reason, "one_character");
  assert.equal(item.machinePoints, 0.5);
  assert.ok(item.teacherIds.includes(teacher.uid), "the package's teacher sees it");
  assert.equal(await readDoc(`marking_items/${typingResultId}_ty_3`), null,
      "word order is never queued");
});

await step("only the queue's teacher or an admin can mark; a student cannot", async () => {
  const other = await signIn("andrea@test.chinesetracker");
  const byOther = await call(other, "markAnswer",
      {itemId: `${typingResultId}_ty_1`, decision: "full"});
  assert.equal(byOther.error.status, "PERMISSION_DENIED");
  const byStudent = await call(s1, "markAnswer",
      {itemId: `${typingResultId}_ty_1`, decision: "full"});
  assert.equal(byStudent.error.status, "PERMISSION_DENIED");
});

await step("the teacher turns the half into full: the score changes, the result is final, the student is told", async () => {
  const r = await call(teacher, "markAnswer", {itemId: `${typingResultId}_ty_1`, decision: "full"});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.final, true);
  const res = await readDoc(`exercise_results/${typingResultId}`);
  assert.equal(res.status, "final");
  assert.equal(res.score, 67, "2 of 3 points");
  const notes = await queryDocs("notifications", "userId", s1.uid);
  assert.ok(notes.some((n) => str(n.fields, "title") === "Marked"), "a notification arrived");
});

let essaySession;
await step("free writing in a test: pending with no pass or fail, then the rubric makes it final", async () => {
  essaySession = (await call(teacher, "openTestSession", {codeId: ESSAY})).data;
  let part = (await call(s5, "startTest", {token: essaySession.token})).data;
  part = (await call(s5, "submitTestPart", {codeId: ESSAY, partIndex: 0,
    answers: {es_l1: {index: 0}}})).data;
  part = (await call(s5, "submitTestPart", {codeId: ESSAY, partIndex: 1,
    answers: {es_r1: {index: 0}}})).data;
  const essayQ = part.questions.find((q) => q.id === "es_w2");
  assert.deepEqual(essayQ.keywords, ["周末", "公园"]);
  const fin = await call(s5, "submitTestPart", {codeId: ESSAY, partIndex: 2, answers: {
    es_w1: {text: "刚"}, es_w2: {text: "这个周末我和朋友去公园散步。"}}});
  assert.equal(fin.data.finished, true);
  let res = await readDoc(`test_results/${ESSAY}_${s5.uid}`);
  assert.equal(res.status, "pending_marking");
  assert.equal(res.passed, false, "no pass or fail while pending");
  assert.equal(res.openMarking, 1);
  const item = await readDoc(`marking_items/${ESSAY}_${s5.uid}_es_w2`);
  assert.equal(item.reason, "free_writing");
  assert.equal(item.maxPoints, 10);
  // Build 1C Must 8: the session's teacher and the student's own teacher.
  const s5Profile = await readDoc(`users/${s5.uid}`);
  assert.ok(item.teacherIds.includes(teacher.uid), "the session's teacher");
  assert.ok(s5Profile.teacherId, "the seed gives student5 a teacher");
  assert.ok(item.teacherIds.includes(s5Profile.teacherId), "the student's own teacher");
  const m = await call(teacher, "markAnswer", {itemId: `${ESSAY}_${s5.uid}_es_w2`,
    rubric: {grammar: 40, vocabulary: 30, content: 30}});
  assert.ok(m.data, JSON.stringify(m.error));
  res = await readDoc(`test_results/${ESSAY}_${s5.uid}`);
  assert.equal(res.status, "final");
  assert.deepEqual(res.parts.map((p) => p.mark), [100, 100, 100]);
  assert.equal(res.total, 300);
  assert.equal(res.passed, true);
});

await step("End test for everyone keeps what a student was typing", async () => {
  const st = await call(s6, "startTest", {token: essaySession.token});
  assert.ok(st.data, JSON.stringify(st.error));
  const closing = call(teacher, "closeTestSession", {sessionId: essaySession.sessionId});
  // The player listens to its attempt and sends the open part when asked.
  let asked = false;
  for (let i = 0; i < 40 && !asked; i++) {
    await new Promise((r) => setTimeout(r, 250));
    asked = (await readDoc(`test_attempts/${ESSAY}_${s6.uid}`)).submitRequested === true;
  }
  assert.ok(asked, "the attempt is asked to submit");
  const sent = await call(s6, "submitTestPart", {codeId: ESSAY, partIndex: 0,
    answers: {es_l1: {index: 0}}});
  assert.equal(sent.data.finished, true, "no next part opens");
  const closed = await closing;
  assert.ok(closed.data, JSON.stringify(closed.error));
  const res = await readDoc(`test_results/${ESSAY}_${s6.uid}`);
  assert.deepEqual(res.parts.map((p) => p.mark), [100, 0, 0], "the typed part counts");
});

await step("the review shows the teacher's mark", async () => {
  const r = await call(s5, "getTestReview", {codeId: ESSAY});
  assert.ok(r.data, JSON.stringify(r.error));
  const essayItem = r.data.items.find((x) => x.question.id === "es_w2");
  assert.deepEqual(essayItem.review.marking, {status: "marked", points: 10});
});

await step("a forgotten session is closed by the hourly job, then the review opens", async () => {
  const s7 = await signIn("student7@test.chinesetracker");
  await deleteDoc(`test_attempts/${ESSAY}_${s7.uid}`);
  await deleteDoc(`test_results/${ESSAY}_${s7.uid}`);
  const open = (await call(teacher, "openTestSession", {codeId: ESSAY})).data;
  await call(s7, "startTest", {token: open.token});
  // Its last possible end (join + 9 minutes + grace) was long ago.
  await patchDoc(`test_sessions/${open.sessionId}`, {joinUntil: ts(Date.now() - 2 * 3600 * 1000)});
  const refused = await call(s7, "getTestReview", {codeId: ESSAY});
  assert.equal(reasonOf(refused), "not-finished");
  // The emulator registers a scheduled function only when the Pub/Sub
  // emulator runs (firebase.json, port 8085), under the id `<name>-0`; a
  // POST there runs it once.
  const job = await fetch(`${FN}/closeForgottenTestSessions-0`, {
    method: "POST", headers: {"Content-Type": "application/json"}, body: "{}",
  });
  assert.ok(job.ok, `job trigger: ${job.status}`);
  let sess;
  for (let i = 0; i < 40; i++) {
    await new Promise((r) => setTimeout(r, 250));
    sess = await readDoc(`test_sessions/${open.sessionId}`);
    if (sess.status === "closed") break;
  }
  assert.equal(sess.status, "closed");
  const r = await call(s7, "getTestReview", {codeId: ESSAY});
  assert.ok(r.data, JSON.stringify(r.error));
});

await step("admin resets an attempt: audit-logged, the student can sit the code again", async () => {
  const id = `${ESSAY}_${s6.uid}`;
  const byTeacher = await call(teacher, "resetTestAttempt", {resultId: id});
  assert.equal(byTeacher.error.status, "PERMISSION_DENIED");
  const r = await call(admin, "resetTestAttempt", {resultId: id, reason: "listrik mati"});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(await readDoc(`test_results/${id}`), null);
  assert.equal(await readDoc(`test_attempts/${id}`), null);
  const logs = await queryDocs("audit_logs", "targetId", id);
  assert.ok(logs.some((l) => str(l.fields, "action") === "test.attempt.reset"));
  const again = (await call(teacher, "openTestSession", {codeId: ESSAY})).data;
  const st = await call(s6, "startTest", {token: again.token});
  assert.ok(st.data, JSON.stringify(st.error));
  await call(teacher, "closeTestSession", {sessionId: again.sessionId});
});

// ---------------------------------------------------------------------------
// Build 2B: leaderboard and promotion (LB-01, LV-01, LV-03). The trigger
// onTestResultWritten runs after each write, so the checks wait for it.
// ---------------------------------------------------------------------------
async function waitFor(check, what, ms = 15000) {
  const end = Date.now() + ms;
  for (;;) {
    const v = await check();
    if (v) return v;
    if (Date.now() > end) assert.fail(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 300));
  }
}

function toValue(v) {
  if (v === null || v === undefined) return {nullValue: null};
  if (v instanceof Date) return {timestampValue: v.toISOString()};
  if (typeof v === "boolean") return {booleanValue: v};
  if (typeof v === "number") return Number.isInteger(v) ? {integerValue: String(v)} : {doubleValue: v};
  if (typeof v === "string") return {stringValue: v};
  if (Array.isArray(v)) return {arrayValue: {values: v.map(toValue)}};
  return {mapValue: {fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)]))}};
}

async function setDocRaw(path, obj) {
  const r = await fetch(`${FS}/${path}`, {
    method: "PATCH",
    headers: {"Content-Type": "application/json", Authorization: "Bearer owner"},
    body: JSON.stringify({fields: Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, toValue(v)]))}),
  });
  assert.ok(r.ok, `set ${path}: ${r.status}`);
}

async function listDocs(path) {
  const r = await fetch(`${FS}/${path}`, {headers: {Authorization: "Bearer owner"}});
  const j = await r.json();
  return j.documents || [];
}

const entryPath = (codeId, uid) => `leaderboards/${codeId}/entries/${uid}`;

await step("LB-01 a final result is on the board of its code with the peer label, never the Latin full name", async () => {
  const res = await readDoc(`test_results/${CODE}_${s1.uid}`);
  assert.ok(res, "student1 sat the code earlier in the flow");
  const e = await waitFor(() => readDoc(entryPath(CODE, s1.uid)), "student1's board entry");
  assert.equal(e.total, res.total);
  assert.ok(e.name && !e.name.includes(" "), `peer label, got "${e.name}"`);
  assert.ok(!JSON.stringify(e).includes(res.studentName) || !res.studentName.includes(" "));
  // The essay marked with the rubric above is final: on the board too.
  await waitFor(() => readDoc(entryPath(ESSAY, s5.uid)), "the marked essay's entry");
});

await step("a pending result is on no board until it is marked", async () => {
  const uid = "flow_pending";
  await setDocRaw(`test_results/${CODE}_${uid}`, {
    codeId: CODE, studentId: uid, family: "hsk", levelKey: "3", total: 250, max: 300,
    passed: false, valid: true, status: "pending_marking", studentName: "Flow Pending",
    studentNameChinese: "", finishedAt: new Date()});
  await new Promise((r) => setTimeout(r, 2500));
  assert.equal(await readDoc(entryPath(CODE, uid)), null);
  await patchDoc(`test_results/${CODE}_${uid}`, {status: {stringValue: "final"},
    passed: {booleanValue: true}});
  const e = await waitFor(() => readDoc(entryPath(CODE, uid)), "the entry once final");
  assert.equal(e.name, "Flow", "no Chinese name: the first word only");
  await deleteDoc(`test_results/${CODE}_${uid}`);
  await waitFor(async () => (await readDoc(entryPath(CODE, uid))) === null, "removal");
});

await step("a result marked invalid leaves the board at once and comes back when valid", async () => {
  const id = `${CODE}_${s1.uid}`;
  const off = await call(teacher, "setTestResultValidity", {resultId: id, valid: false, reason: "flow"});
  assert.ok(off.data, JSON.stringify(off.error));
  await waitFor(async () => (await readDoc(entryPath(CODE, s1.uid))) === null, "invalid → off the board");
  const on = await call(teacher, "setTestResultValidity", {resultId: id, valid: true});
  assert.ok(on.data, JSON.stringify(on.error));
  await waitFor(() => readDoc(entryPath(CODE, s1.uid)), "valid → back on the board");
});

await step("Reset attempt takes the result off the board", async () => {
  // student6 sat the essay code again after the reset above; reset again.
  const id = `${ESSAY}_${s6.uid}`;
  await waitFor(() => readDoc(entryPath(ESSAY, s6.uid)), "the second sitting on the board");
  const r = await call(admin, "resetTestAttempt", {resultId: id, reason: "flow"});
  assert.ok(r.data, JSON.stringify(r.error));
  await waitFor(async () => (await readDoc(entryPath(ESSAY, s6.uid))) === null, "no entry after reset");
});

const s9 = await signIn("student9@test.chinesetracker");
const s10 = await signIn("student10@test.chinesetracker");
const PCODES = ["FLOWP1", "FLOWP2", "FLOWP3", "FLOWP4"];
for (const c of PCODES) {
  await setDocRaw(`test_codes/${c}`, {code: c, family: "hsk", level: "HSK 3", levelKey: "3",
    countsForPromotion: true, active: true});
}
const passResult = (c, s, total) => setDocRaw(`test_results/${c}_${s.uid}`, {
  codeId: c, code: c, studentId: s.uid, family: "hsk", level: "HSK 3", levelKey: "3",
  total, max: 300, passMark: 180, passed: total >= 180, valid: true, status: "final",
  studentName: "Flow Student", studentNameChinese: "测试", durationSeconds: 3000,
  finishedAt: new Date(), parts: [{skill: "listening", mark: Math.round(total / 3), maxScore: 100}]});
for (const s of [s9, s10]) {
  await patchDoc(`users/${s.uid}`, {level: {stringValue: "HSK 3"}});
  for (const c of PCODES) await deleteDoc(`test_results/${c}_${s.uid}`);
  await deleteDoc(`level_promotions/${s.uid}_3`);
}
const promoPath = (s) => `level_promotions/${s.uid}_3`;

await step("LV-03 two passes and one fail: no recommendation", async () => {
  await passResult("FLOWP1", s9, 170);
  await passResult("FLOWP2", s9, 195);
  await passResult("FLOWP3", s9, 200);
  await waitFor(async () => (await readDoc(`promotion_progress/${s9.uid}`) || {}).count === 2,
      "progress 2 of 3");
  const progress = await readDoc(`promotion_progress/${s9.uid}`);
  assert.equal(progress.minCodes, 3);
  assert.equal(progress.next, "HSK 4");
  assert.equal(await readDoc(promoPath(s9)), null);
});

await step("LV-01 a third different code passed: a waiting recommendation for HSK 4 and the admins are told", async () => {
  await passResult("FLOWP4", s9, 205);
  const p = await waitFor(async () => {
    const d = await readDoc(promoPath(s9));
    return d && d.status === "waiting" ? d : null;
  }, "the recommendation");
  assert.equal(p.toLevel, "HSK 4");
  assert.deepEqual(p.codes.map((c) => c.codeId), ["FLOWP2", "FLOWP3", "FLOWP4"]);
  const notes = await queryDocs("notifications", "kind", "promotion");
  assert.ok(notes.some((n) => str(n.fields, "forRole") === "admin"));
});

await step("a result turning invalid withdraws a waiting recommendation; valid again brings it back", async () => {
  await patchDoc(`test_results/FLOWP4_${s9.uid}`, {valid: {booleanValue: false}});
  await waitFor(async () => (await readDoc(promoPath(s9)) || {}).status === "withdrawn", "withdrawn");
  await patchDoc(`test_results/FLOWP4_${s9.uid}`, {valid: {booleanValue: true}});
  await waitFor(async () => (await readDoc(promoPath(s9)) || {}).status === "waiting", "waiting again");
});

await step("Approve: admin only; the level goes up, the history is written, the student is told", async () => {
  const byTeacher = await call(teacher, "decidePromotion", {promotionId: `${s9.uid}_3`, approve: true});
  assert.equal(byTeacher.error.status, "PERMISSION_DENIED");
  const r = await call(admin, "decidePromotion", {promotionId: `${s9.uid}_3`, approve: true});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal((await readDoc(`users/${s9.uid}`)).level, "HSK 4");
  const fresh = await readDoc(`promotion_progress/${s9.uid}`);
  assert.equal(fresh.level, "HSK 4");
  assert.equal(fresh.count, 0, "the count starts again at the new level");
  assert.equal((await readDoc(promoPath(s9))).status, "approved");
  const history = await listDocs(`users/${s9.uid}/level_history`);
  assert.equal(history.length >= 1, true);
  const notes = await queryDocs("notifications", "userId", s9.uid);
  assert.ok(notes.some((n) => str(n.fields, "kind") === "promotion"));
  const again = await call(admin, "decidePromotion", {promotionId: `${s9.uid}_3`, approve: true});
  assert.equal(reasonOf(again), "not-waiting");
});

await step("Decline needs a reason and keeps the level", async () => {
  for (const [c, t] of [["FLOWP2", 190], ["FLOWP3", 200], ["FLOWP4", 210]]) {
    await passResult(c, s10, t);
  }
  await waitFor(async () => (await readDoc(promoPath(s10)) || {}).status === "waiting", "s10 waiting");
  const bare = await call(admin, "decidePromotion", {promotionId: `${s10.uid}_3`, approve: false});
  assert.equal(bare.error.status, "INVALID_ARGUMENT");
  const r = await call(admin, "decidePromotion",
      {promotionId: `${s10.uid}_3`, approve: false, reason: "wait for the speaking test"});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal((await readDoc(`users/${s10.uid}`)).level, "HSK 3");
  assert.equal((await readDoc(promoPath(s10))).declineReason, "wait for the speaking test");
  // The student's card stops saying "waiting", also after another result.
  assert.equal((await readDoc(`promotion_progress/${s10.uid}`)).decision, "declined");
  await passResult("FLOWP1", s10, 220);
  await waitFor(async () => (await readDoc(`promotion_progress/${s10.uid}`) || {}).count === 4,
      "s10 count 4");
  assert.equal((await readDoc(`promotion_progress/${s10.uid}`)).decision, "declined");
  assert.equal((await readDoc(promoPath(s10))).status, "declined");
});


// ---------------------------------------------------------------------------
// Build 3: registration approval, placement sessions, the visitor path.
// New accounts register through the rules (a student's own token), like the
// app's register form.
const RUN = Date.now().toString(36);
async function registerStudent(tag, extra = {}) {
  const email = `flow_${tag}_${RUN}@test.chinesetracker`;
  const r = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: "POST", headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password: PASSWORD, returnSecureToken: true}),
  });
  const j = await r.json();
  assert.ok(j.idToken, JSON.stringify(j).slice(0, 200));
  const user = {token: j.idToken, uid: j.localId};
  const doc = {role: "student", email, name: `Flow ${tag}`, nameIndonesian: `Flow ${tag}`,
    active: true, status: "pending", teacherId: "", level: "", termSize: 8,
    placementChoice: "hsk1", placementTarget: "", placementResultCode: "", ...extra};
  const w = await fetch(`${FS}/users/${user.uid}`, {
    method: "PATCH",
    headers: {"Content-Type": "application/json", Authorization: `Bearer ${user.token}`},
    body: JSON.stringify({fields: Object.fromEntries(
        Object.entries(doc).map(([k, v]) => [k, toValue(v)]))}),
  });
  assert.ok(w.ok, `register ${tag}: ${w.status} ${await w.text()}`);
  return user;
}

/** A callable with no sign-in (the visitor). */
async function callPublic(name, data) {
  const r = await fetch(`${FN}/${name}`, {
    method: "POST", headers: {"Content-Type": "application/json"},
    body: JSON.stringify({data}),
  });
  const j = await r.json();
  return j.error ? {error: j.error} : {data: j.result};
}

const andrea = await signIn("andrea@test.chinesetracker");
const H3_ALL_RIGHT = [
  {tq_l1: {index: 0}, tq_l2: {index: 2}, tq_l3: {index: 0}, tq_l4: {index: 1}},
  {tq_r1: {index: 0}, tq_r2: {index: 0}, tq_r3: {index: 0}, tq_r4: {index: 0}},
  {tq_w1: {text: "刚"}, tq_w2: {text: "等"}, tq_w3: {order: ["经理的", "办公室在", "二楼"]}},
];

let pl02;
await step("a self-registered student is pending: the admins are told, the functions refuse them", async () => {
  pl02 = await registerStudent("pl02");
  const u = await readDoc(`users/${pl02.uid}`);
  assert.equal(u.status, "pending");
  const notes = await waitFor(async () => {
    const all = await queryDocs("notifications", "targetRoute", "/admin/users/approval");
    return all.some((n) => str(n.fields, "body").includes("Flow pl02")) ? all : null;
  }, "the admin's approval notice");
  assert.ok(notes.length >= 1);
  const r = await call(pl02, "startTest", {token: "ABCDEF"});
  assert.equal(reasonOf(r), "not-approved");
});

await step("decideRegistration: admin only, a teacher and a level are required", async () => {
  const byTeacher = await call(teacher, "decideRegistration",
      {studentId: pl02.uid, approve: true, level: "HSK 1", teacherId: andrea.uid});
  assert.equal(byTeacher.error.status, "PERMISSION_DENIED");
  const noTeacher = await call(admin, "decideRegistration",
      {studentId: pl02.uid, approve: true, level: "HSK 1"});
  assert.equal(reasonOf(noTeacher), "teacher");
  const badLevel = await call(admin, "decideRegistration",
      {studentId: pl02.uid, approve: true, level: "HSK 9", teacherId: andrea.uid});
  assert.equal(reasonOf(badLevel), "level");
});

await step("PL-02 approve a 'Mulai dari HSK 1' student: level HSK 1, status active, student and teacher told", async () => {
  const r = await call(admin, "decideRegistration",
      {studentId: pl02.uid, approve: true, level: "HSK 1", teacherId: andrea.uid});
  assert.ok(r.data, JSON.stringify(r.error));
  const u = await readDoc(`users/${pl02.uid}`);
  assert.equal(u.status, "active");
  assert.equal(u.level, "HSK 1");
  assert.equal(u.teacherId, andrea.uid);
  assert.equal(u.approvedBy, admin.uid);
  const mine = await queryDocs("notifications", "userId", pl02.uid);
  assert.ok(mine.some((n) => str(n.fields, "kind") === "registration" &&
    str(n.fields, "targetRoute") === "/student"));
  const theirs = await queryDocs("notifications", "userId", andrea.uid);
  assert.ok(theirs.some((n) => str(n.fields, "body").includes("Flow pl02")));
  const again = await call(admin, "decideRegistration",
      {studentId: pl02.uid, approve: true, level: "HSK 1", teacherId: andrea.uid});
  assert.equal(reasonOf(again), "not-pending");
});

await step("reject needs a reason; a rejected account may be approved later", async () => {
  const s = await registerStudent("reject");
  const bare = await call(admin, "decideRegistration", {studentId: s.uid, approve: false});
  assert.equal(reasonOf(bare), "reason-required");
  const r = await call(admin, "decideRegistration",
      {studentId: s.uid, approve: false, reason: "Please register with your own email."});
  assert.ok(r.data, JSON.stringify(r.error));
  let u = await readDoc(`users/${s.uid}`);
  assert.equal(u.status, "rejected");
  assert.equal(u.rejectReason, "Please register with your own email.");
  const ok = await call(admin, "decideRegistration",
      {studentId: s.uid, approve: true, level: "HSK 2", teacherId: andrea.uid});
  assert.ok(ok.data, JSON.stringify(ok.error));
  u = await readDoc(`users/${s.uid}`);
  assert.equal(u.status, "active");
  assert.equal(u.rejectReason, undefined);
});

let plSession;
let pl01;
await step("PL-01 a target-HSK-4 student is approved at HSK 1 and sits a placement session on H3DEMO1", async () => {
  pl01 = await registerStudent("pl01", {placementChoice: "test", placementTarget: "HSK 4"});
  const ok = await call(admin, "decideRegistration",
      {studentId: pl01.uid, approve: true, level: "HSK 1", teacherId: teacher.uid});
  assert.ok(ok.data, JSON.stringify(ok.error));
  const open = await call(teacher, "openTestSession", {codeId: CODE, placement: true});
  assert.ok(open.data, JSON.stringify(open.error));
  assert.equal(open.data.placement, true);
  plSession = open.data;
  const peek = await call(pl01, "startTest", {token: plSession.token, peek: true});
  assert.equal(peek.data.placement, true, "the start screen says Placement test");
  let r = await call(pl01, "startTest", {token: plSession.token});
  assert.ok(r.data, JSON.stringify(r.error));
  for (let i = 0; i < 3; i++) {
    r = await call(pl01, "submitTestPart", {codeId: CODE, partIndex: i, answers: H3_ALL_RIGHT[i]});
    assert.ok(r.data, JSON.stringify(r.error));
  }
  assert.equal(r.data.finished, true);
  const res = await readDoc(`test_results/${CODE}_${pl01.uid}`);
  assert.equal(res.placement, true);
  assert.equal(res.passed, true);
});

await step("PL-01 the pass recommends HSK 1 → HSK 4 for the admin; no board row, no count", async () => {
  const p = await waitFor(async () => {
    const d = await readDoc(`level_promotions/${pl01.uid}_placement`);
    return d && d.status === "waiting" ? d : null;
  }, "the placement recommendation");
  assert.equal(p.kind, "placement");
  assert.equal(p.fromLevel, "HSK 1");
  assert.equal(p.toLevel, "HSK 4");
  const notes = await queryDocs("notifications", "title", "Placement result to check");
  assert.ok(notes.some((n) => str(n.fields, "body").includes("Flow pl01")));
  assert.equal(await readDoc(entryPath(CODE, pl01.uid)), null);
  const progress = await readDoc(`promotion_progress/${pl01.uid}`);
  assert.equal(progress ? progress.count : 0, 0);
});

await step("PL-01 approve: level HSK 4, history kind placement, still no board row, 0 codes toward HSK 5", async () => {
  const r = await call(admin, "decidePromotion",
      {promotionId: `${pl01.uid}_placement`, approve: true});
  assert.ok(r.data, JSON.stringify(r.error));
  const u = await readDoc(`users/${pl01.uid}`);
  assert.equal(u.level, "HSK 4");
  assert.equal(u.placementDone, true);
  const history = await listDocs(`users/${pl01.uid}/level_history`);
  assert.ok(history.some((h) => (h.fields.kind || {}).stringValue === "placement"));
  const progress = await readDoc(`promotion_progress/${pl01.uid}`);
  assert.equal(progress.level, "HSK 4");
  assert.equal(progress.next, "HSK 5");
  assert.equal(progress.count, 0);
  await new Promise((res) => setTimeout(res, 1500));
  assert.equal(await readDoc(entryPath(CODE, pl01.uid)), null);
  assert.equal((await readDoc(`level_promotions/${pl01.uid}_placement`)).status, "approved");
});

await step("a failed placement test recommends the paper's level (HSK 3)", async () => {
  const s = await registerStudent("plfail", {placementChoice: "test", placementTarget: "HSK 4"});
  await call(admin, "decideRegistration",
      {studentId: s.uid, approve: true, level: "HSK 1", teacherId: teacher.uid});
  let r = await call(s, "startTest", {token: plSession.token});
  assert.ok(r.data, JSON.stringify(r.error));
  for (let i = 0; i < 3; i++) {
    r = await call(s, "submitTestPart", {codeId: CODE, partIndex: i, answers: {}});
  }
  const p = await waitFor(async () => {
    const d = await readDoc(`level_promotions/${s.uid}_placement`);
    return d && d.status === "waiting" ? d : null;
  }, "the failed placement's recommendation");
  assert.equal(p.toLevel, "HSK 3");
  await call(teacher, "closeTestSession", {sessionId: plSession.sessionId});
});

// The visitor path (no account).
const PLACE = "H1PLACE";
let visitorSession;
let visitor;
await step("placement menu: public, lists the placement code with its parts and minutes", async () => {
  const r = await callPublic("placementMenu", {});
  assert.ok(r.data, JSON.stringify(r.error));
  const e = r.data.codes.find((c) => c.codeId === PLACE);
  assert.ok(e, "H1PLACE is listed");
  assert.equal(e.level, "HSK 1");
  assert.equal(e.minutes, 4);
  assert.deepEqual(e.parts.map((p) => p.questions), [3, 3]);
  assert.ok(!r.data.codes.some((c) => c.codeId === CODE), "an ordinary code is not listed");
});

await step("a visitor needs a placement session's token, a name and a WhatsApp number", async () => {
  const open = await call(teacher, "openTestSession", {codeId: PLACE});
  assert.ok(open.data, JSON.stringify(open.error));
  assert.equal(open.data.placement, true, "a placement code always opens a placement session");
  visitorSession = open.data;
  const wrong = await callPublic("startPlacement", {token: "ZZZZZZ", name: "Visitor", whatsapp: "081234567890"});
  assert.equal(reasonOf(wrong), "bad-token");
  // An ordinary session's token is not valid for a visitor.
  const ordinary = await call(teacher, "openTestSession", {codeId: CODE});
  const notPlacement = await callPublic("startPlacement",
      {token: ordinary.data.token, name: "Visitor", whatsapp: "081234567890"});
  assert.equal(reasonOf(notPlacement), "bad-token");
  await call(teacher, "closeTestSession", {sessionId: ordinary.data.sessionId});
  const noName = await callPublic("startPlacement", {token: visitorSession.token, name: "", whatsapp: "0812"});
  assert.equal(reasonOf(noName), "visitor-details");
});

await step("a visitor starts: a key once, part 1 without keys; a reload resumes the same part", async () => {
  const r = await callPublic("startPlacement",
      {token: visitorSession.token, name: "Flow Visitor", whatsapp: "+62 812 0000 1111"});
  assert.ok(r.data, JSON.stringify(r.error));
  visitor = {attemptId: r.data.attemptId, key: r.data.key};
  assert.match(visitor.key, /^[0-9a-f]{32}$/);
  assert.equal(r.data.placement, true);
  assert.equal(r.data.partIndex, 0);
  assert.equal(r.data.questions.length, 3);
  assert.ok(!JSON.stringify(r.data).includes("correctIndex"), "no key leaves the server");
  const a = await readDoc(`test_attempts/${visitor.attemptId}`);
  assert.equal(a.visitor, true);
  assert.equal(a.studentId, "");
  assert.equal(a.visitorWhatsapp, "+6281200001111");
  assert.ok(a.keyHash && a.keyHash !== visitor.key, "only the hash is stored");
  const again = await callPublic("startPlacement", visitor);
  assert.equal(again.data.partIndex, 0);
  assert.equal(again.data.key, undefined, "the key is never sent again");
});

await step("a wrong key is refused; a visitor cannot use the student functions", async () => {
  const bad = await callPublic("submitPlacementPart",
      {attemptId: visitor.attemptId, key: "0".repeat(32), partIndex: 0, answers: {}});
  assert.equal(reasonOf(bad), "bad-key");
  const st = await callPublic("startTest", {token: visitorSession.token});
  assert.equal(st.error.status, "UNAUTHENTICATED");
  const rv = await callPublic("getTestReview", {resultId: visitor.attemptId});
  assert.equal(rv.error.status, "UNAUTHENTICATED");
});

let resultCode;
await step("two parts → marks per part and a result code; no review, no test_results", async () => {
  let r = await callPublic("submitPlacementPart", {...visitor, partIndex: 0,
    answers: {pl_l1: {index: 0}, pl_l2: {index: 1}, pl_l3: {index: 2}}});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.partIndex, 1);
  r = await callPublic("submitPlacementPart", {...visitor, partIndex: 1,
    answers: {pl_r1: {index: 0}, pl_r2: {index: 1}, pl_r3: {index: 1}}});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.finished, true);
  assert.deepEqual(r.data.parts.map((p) => p.mark), [100, 67]);
  assert.equal(r.data.passed, true);
  assert.equal(r.data.recommendedLevel, "HSK 2");
  assert.match(r.data.resultCode, /^[A-HJ-NP-Z2-9]{6}$/);
  assert.ok(!JSON.stringify(r.data).match(/correctIndex|answer|transcript|explanation/));
  resultCode = r.data.resultCode;
  const pr = await readDoc(`placement_results/${visitor.attemptId}`);
  assert.equal(pr.name, "Flow Visitor");
  assert.equal(pr.claimedBy, "");
  assert.equal(await readDoc(`test_results/${visitor.attemptId}`), null);
  // A reload after the end shows the result again.
  const again = await callPublic("startPlacement", visitor);
  assert.equal(again.data.resultCode, resultCode);
});

await step("resolve the result code; the first student who registers with it claims it", async () => {
  const r = await callPublic("resolvePlacementResult", {resultCode: resultCode.toLowerCase()});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.level, "HSK 1");
  assert.equal(r.data.recommendedLevel, "HSK 2");
  assert.equal(r.data.claimed, false);
  assert.equal(r.data.name, undefined, "no name or number for the public");
  const bad = await callPublic("resolvePlacementResult", {resultCode: "ZZZZZZ"});
  assert.equal(reasonOf(bad), "bad-result-code");
  const first = await registerStudent("claim1", {placementChoice: "test",
    placementTarget: "HSK 2", placementResultCode: resultCode});
  const card = await call(admin, "registrationPlacement", {resultCode});
  assert.equal(card.data.recommendedLevel, "HSK 2");
  const ok = await call(admin, "decideRegistration",
      {studentId: first.uid, approve: true, level: "HSK 2", teacherId: teacher.uid});
  assert.ok(ok.data, JSON.stringify(ok.error));
  assert.equal((await readDoc(`placement_results/${visitor.attemptId}`)).claimedBy, first.uid);
  const second = await registerStudent("claim2", {placementChoice: "test",
    placementTarget: "HSK 2", placementResultCode: resultCode});
  const refused = await call(admin, "decideRegistration",
      {studentId: second.uid, approve: true, level: "HSK 2", teacherId: teacher.uid});
  assert.equal(reasonOf(refused), "claimed");
  const after = await callPublic("resolvePlacementResult", {resultCode});
  assert.equal(after.data.claimed, true);
});

await step("closing a placement session finishes a sitting visitor into placement_results", async () => {
  const r = await callPublic("startPlacement",
      {token: visitorSession.token, name: "Late Visitor", whatsapp: "081200002222"});
  assert.ok(r.data, JSON.stringify(r.error));
  const c = await call(teacher, "closeTestSession", {sessionId: visitorSession.sessionId});
  assert.ok(c.data, JSON.stringify(c.error));
  const pr = await readDoc(`placement_results/${r.data.attemptId}`);
  assert.ok(pr, "the visitor's result is written");
  assert.equal(pr.total, 0);
  assert.match(pr.resultCode, /^[A-HJ-NP-Z2-9]{6}$/);
  assert.equal(await readDoc(`test_results/${r.data.attemptId}`), null);
});


// ---------------------------------------------------------------------------
// Build 4: the progress summary (seeded: student13 healthy, student18 with
// one voucher session left).
async function readAs(user, path) {
  const r = await fetch(`${FS}/${path}`, {headers: {Authorization: `Bearer ${user.token}`}});
  return r.status;
}
async function writeAs(user, path, obj) {
  const r = await fetch(`${FS}/${path}`, {
    method: "PATCH",
    headers: {"Content-Type": "application/json", Authorization: `Bearer ${user.token}`},
    body: JSON.stringify({fields: Object.fromEntries(
        Object.entries(obj).map(([k, v]) => [k, toValue(v)]))}),
  });
  return r.status;
}
const s13 = await signIn("student13@test.chinesetracker");
const s18 = await signIn("student18@test.chinesetracker");
const parent = await signIn("parent@test.chinesetracker");
const summaryOf = (s) => readDoc(`progress_summary/${s.uid}`);

await step("a new practice result updates the summary within seconds", async () => {
  const before = await summaryOf(s13);
  assert.ok(before, "seeded summary");
  const when = new Date();
  await setDocRaw(`exercise_results/flow_prg_${RUN}`, {studentId: s13.uid,
    exerciseId: "pkg_practice", score: 100, status: "final", category: "exercise",
    bySkill: {reading: {correct: 4, total: 4}}, submittedAt: when});
  const after = await waitFor(async () => {
    const d = await summaryOf(s13);
    return d && d.practice.lastPracticeMs >= when.getTime() - 1000 ? d : null;
  }, "the summary after a practice result");
  assert.equal(after.practice.attempts90, before.practice.attempts90 + 1);
  assert.equal(after.practice.weeks.length, 12);
});

await step("a test result adds a history row with its leaderboard rank", async () => {
  await setDocRaw(`test_results/PRG3_${s13.uid}`, {codeId: "PRG3", code: "PRG3",
    studentId: s13.uid, family: "hsk", level: "HSK 3", levelKey: "3", total: 240, max: 300,
    passMark: 180, passed: true, valid: true, status: "final", studentName: "Flow",
    studentNameChinese: "测", durationSeconds: 3000, finishedAt: new Date(),
    parts: [{skill: "listening", mark: 80, maxScore: 100}]});
  const d = await waitFor(async () => {
    const x = await summaryOf(s13);
    const row = x && x.tests.history.find((h) => h.codeId === "PRG3");
    return row && row.rank !== null ? x : null;
  }, "the PRG3 row with a rank");
  const row = d.tests.history.find((h) => h.codeId === "PRG3");
  assert.equal(row.rank, 1);
  assert.ok(row.boardSize >= 1);
  assert.equal(d.tests.passedAtLevel, 3, "PRG1, PRG2 and PRG3 at HSK 3");
  const prg2 = d.tests.history.find((h) => h.codeId === "PRG2");
  assert.ok(prg2.rank > 1 && prg2.boardSize === 15, `PRG2 rank ${prg2.rank} of ${prg2.boardSize}`);
});

await step("a teacher's note shows for the student and the parent; others cannot write it", async () => {
  const id = `flow_note_${RUN}`;
  const note = {studentId: s1.uid, teacherId: teacher.uid, teacherName: "Test Teacher",
    text: "Flow note: keep reading.", createdAt: new Date()};
  assert.equal(await writeAs(s1, `progress_notes/${id}x`, {...note, teacherId: s1.uid}), 403);
  assert.equal(await writeAs(andrea, `progress_notes/${id}y`, {...note, teacherId: andrea.uid}), 403,
      "student1 is not Andrea's student");
  assert.equal(await writeAs(teacher, `progress_notes/${id}`, note), 200);
  const d = await waitFor(async () => {
    const x = await summaryOf(s1);
    return x && x.latestNote && x.latestNote.text === note.text ? x : null;
  }, "the note on the summary");
  assert.equal(d.latestNote.teacherName, "Test Teacher");
  assert.equal(await readAs(s1, `progress_notes/${id}`), 200);
  assert.equal(await readAs(parent, `progress_notes/${id}`), 200);
  assert.equal(await readAs(parent, `progress_summary/${s1.uid}`), 200);
});

await step("a student cannot read another student's summary", async () => {
  assert.equal(await readAs(s1, `progress_summary/${s13.uid}`), 403);
  assert.equal(await readAs(s13, `progress_summary/${s13.uid}`), 200);
  assert.equal(await readAs(parent, `progress_summary/${s13.uid}`), 403);
});

await step("the daily job sends each warning notice once, and not again within 7 days", async () => {
  await patchDoc(`progress_summary/${s18.uid}`, {notifiedAt: {mapValue: {fields: {}}}});
  const count = async () => (await queryDocs("notifications", "studentId", s18.uid))
      .filter((n) => str(n.fields, "kind") === "progress").length;
  const before = await count();
  const run = async () => {
    const job = await fetch(`${FN}/dailyReminders-0`, {
      method: "POST", headers: {"Content-Type": "application/json"}, body: "{}",
    });
    assert.ok(job.ok, `job trigger: ${job.status}`);
  };
  await run();
  const after = await waitFor(async () => {
    const n = await count();
    return n > before ? n : null;
  }, "the voucher notices", 60000);
  const notes = (await queryDocs("notifications", "studentId", s18.uid))
      .filter((n) => str(n.fields, "kind") === "progress");
  assert.ok(notes.some((n) => str(n.fields, "forRole") === "student"));
  assert.ok(notes.some((n) => str(n.fields, "forRole") === "admin"));
  const s = await summaryOf(s18);
  assert.ok(s.notifiedAt["4"], "notifiedAt stamped for warning 4");
  await run();
  await new Promise((r) => setTimeout(r, 8000));
  assert.equal(await count(), after, "nothing new on the second run");
});

await step("rebuildProgressSummaries is admin-only", async () => {
  const byTeacher = await call(teacher, "rebuildProgressSummaries", {});
  assert.equal(byTeacher.error.status, "PERMISSION_DENIED");
  const r = await call(admin, "rebuildProgressSummaries", {});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.ok(r.data.rebuilt >= 20);
});


// ---------------------------------------------------------------------------
// Build 5: buying a voucher in the app, the Midtrans webhook (MT-01 to
// MT-04 against the emulator) and the expiry job. Snap is answered by a
// local stub (functions/.env.local points the emulator at it); the
// emulator's Midtrans key is in functions/.secret.local (never committed).
const http = await import("node:http");
const fs = await import("node:fs");
const crypto = await import("node:crypto");
const secretFile = new URL("./.secret.local", import.meta.url);
const MT_KEY = fs.readFileSync(secretFile, "utf8").match(/MIDTRANS_SERVER_KEY=(.*)/)[1].trim();
let snapCalls = 0;
const stub = http.createServer((req, res) => {
  snapCalls += 1;
  res.writeHead(201, {"Content-Type": "application/json"});
  res.end(JSON.stringify({token: `stub-token-${snapCalls}`,
    redirect_url: `http://127.0.0.1:5199/pay/${snapCalls}`}));
});
await new Promise((r) => stub.listen(5199, "127.0.0.1", r));

async function notify(orderId, transactionStatus, grossAmount, {badSignature = false} = {}) {
  const statusCode = transactionStatus === "settlement" ? "200" : "202";
  const signature = crypto.createHash("sha512")
      .update(`${orderId}${statusCode}${grossAmount}${badSignature ? "wrong" : MT_KEY}`)
      .digest("hex");
  const r = await fetch(`${FN}/midtransNotification`, {
    method: "POST", headers: {"Content-Type": "application/json"},
    body: JSON.stringify({order_id: orderId, status_code: statusCode,
      gross_amount: grossAmount, signature_key: signature,
      transaction_status: transactionStatus}),
  });
  return r.status;
}
const termsOf = async (invoiceId) => (await queryDocs("student_class_terms",
    "sourceInvoiceId", invoiceId));
const s7 = await signIn("student7@test.chinesetracker");
const s8 = await signIn("student8@test.chinesetracker");
// Start with no open invoice for the buyers.
for (const s of [s7, s1]) {
  for (const d of await queryDocs("invoices", "studentId", s.uid)) {
    if (str(d.fields, "status") === "pending") await deleteDoc(`invoices/${d.id}`);
  }
}
let bought;

await step("a student buys a voucher: the terms must be ticked, Snap opens, the invoice is pending", async () => {
  const noTerms = await call(s7, "createInvoice", {priceItemId: "package8"});
  assert.equal(reasonOf(noTerms), "terms");
  const book = await call(s7, "createInvoice", {priceItemId: "book", acceptedTerms: true});
  assert.equal(reasonOf(book), "not-buyable", "only session packages are sold in the app");
  const r = await call(s7, "createInvoice", {priceItemId: "package8", acceptedTerms: true});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.match(r.data.redirectUrl, /^http:\/\/127\.0\.0\.1:5199\/pay\//);
  bought = r.data;
  const inv = await readDoc(`invoices/${bought.invoiceId}`);
  assert.equal(inv.status, "pending");
  assert.equal(inv.studentId, s7.uid);
  assert.equal(inv.selfPurchase, true);
  assert.equal(inv.acceptedTerms, true);
  assert.equal(inv.createdByRole, "student");
  assert.equal(inv.nameChinese, "8次课程");
  assert.equal(inv.amount, 2450000, "the amount comes from the Price list");
});

await step("a second Buy reuses the open invoice and its payment link", async () => {
  const before = snapCalls;
  const r = await call(s7, "createInvoice", {priceItemId: "package16", acceptedTerms: true});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.reused, true);
  assert.equal(r.data.invoiceId, bought.invoiceId);
  assert.equal(snapCalls, before, "no new Snap transaction");
});

await step("a student cannot buy for another uid; a parent buys only for their own child", async () => {
  const other = await call(s7, "createInvoice", {studentId: s8.uid, priceItemId: "package8",
    acceptedTerms: true});
  assert.equal(reasonOf(other), "not-yours");
  const parent = await signIn("parent@test.chinesetracker");
  const notChild = await call(parent, "createInvoice", {studentId: s8.uid,
    priceItemId: "package8", acceptedTerms: true});
  assert.equal(reasonOf(notChild), "not-yours");
  const child = await call(parent, "createInvoice", {studentId: s1.uid,
    priceItemId: "package8", acceptedTerms: true});
  assert.ok(child.data, JSON.stringify(child.error));
  const inv = await readDoc(`invoices/${child.data.invoiceId}`);
  assert.equal(inv.studentId, s1.uid);
  assert.equal(inv.createdByRole, "parent");
  await deleteDoc(`invoices/${child.data.invoiceId}`);
});

await step("MT-04 a notification with a wrong signature is refused and changes nothing", async () => {
  const inv = await readDoc(`invoices/${bought.invoiceId}`);
  const status = await notify(inv.midtransOrderId, "settlement", "2450000.00", {badSignature: true});
  assert.equal(status, 403);
  assert.equal((await readDoc(`invoices/${bought.invoiceId}`)).status, "pending");
  assert.equal((await termsOf(bought.invoiceId)).length, 0);
});

await step("MT-01 a settlement pays the invoice: one term of 8 sessions, 60 days, a ledger entry", async () => {
  const inv = await readDoc(`invoices/${bought.invoiceId}`);
  assert.equal(await notify(inv.midtransOrderId, "settlement", "2450000.00"), 200);
  assert.equal((await readDoc(`invoices/${bought.invoiceId}`)).status, "paid");
  const terms = await termsOf(bought.invoiceId);
  assert.equal(terms.length, 1);
  const t = await readDoc(`student_class_terms/${terms[0].id}`);
  assert.equal(t.packageSize, 8);
  assert.equal(t.sessionsRemaining, 8);
  assert.equal(t.sessionsBooked, 0);
  assert.equal(t.nameChinese, "8次课程");
  assert.equal(t.source, "app");
  const days = (Date.parse(t.deadlineDate) - Date.parse(t.startDate)) / 86400000;
  assert.equal(days, 60);
  const ledger = await readDoc(`voucher_history/${bought.invoiceId}_purchase`);
  assert.equal(ledger.kind, "purchase");
  assert.equal(ledger.sessions, 8);
  assert.equal(ledger.termId, terms[0].id);
});

await step("MT-03 the same settlement again changes nothing (one credit)", async () => {
  const inv = await readDoc(`invoices/${bought.invoiceId}`);
  assert.equal(await notify(inv.midtransOrderId, "settlement", "2450000.00"), 200);
  assert.equal((await termsOf(bought.invoiceId)).length, 1);
});

await step("MT-02 pending stays pending; an expire notification gives no term", async () => {
  const r = await call(s7, "createInvoice", {priceItemId: "package16", acceptedTerms: true});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.notEqual(r.data.invoiceId, bought.invoiceId, "the paid one is not reused");
  const inv = await readDoc(`invoices/${r.data.invoiceId}`);
  assert.equal(await notify(inv.midtransOrderId, "pending", "3950000.00"), 200);
  assert.equal((await readDoc(`invoices/${r.data.invoiceId}`)).status, "pending");
  assert.equal(await notify(inv.midtransOrderId, "expire", "3950000.00"), 200);
  assert.equal((await readDoc(`invoices/${r.data.invoiceId}`)).status, "expired");
  assert.equal((await termsOf(r.data.invoiceId)).length, 0);
  // A late settlement for the expired invoice is not credited either.
  assert.equal(await notify(inv.midtransOrderId, "settlement", "3950000.00"), 200);
  assert.equal((await termsOf(r.data.invoiceId)).length, 0);
});

await step("the expiry job expires a past-deadline voucher once, with the forfeited sessions", async () => {
  const id = `flow_expire_${RUN}`;
  await setDocRaw(`student_class_terms/${id}`, {studentId: s8.uid, packageSize: 8,
    sessionsRemaining: 3, sessionsUsed: 5, status: "active", startDate: "2026-01-01",
    deadlineDate: "2026-03-01", nameChinese: "8次课程", createdAt: new Date()});
  const run = async () => {
    const job = await fetch(`${FN}/expireVouchers-0`, {
      method: "POST", headers: {"Content-Type": "application/json"}, body: "{}",
    });
    assert.ok(job.ok, `job trigger: ${job.status}`);
  };
  await run();
  const t = await waitFor(async () => {
    const d = await readDoc(`student_class_terms/${id}`);
    return d && d.status === "expired" ? d : null;
  }, "the term to expire", 30000);
  assert.equal(t.sessionsForfeited, 3);
  const ledger = await readDoc(`voucher_history/${id}_expiry`);
  assert.equal(ledger.kind, "expiry");
  assert.equal(ledger.sessions, -3);
  const notes = (await queryDocs("notifications", "userId", s8.uid))
      .filter((n) => str(n.fields, "title") === "Voucher expired");
  assert.equal(notes.length, 1);
  await run();
  await new Promise((r) => setTimeout(r, 4000));
  const again = (await queryDocs("notifications", "userId", s8.uid))
      .filter((n) => str(n.fields, "title") === "Voucher expired");
  assert.equal(again.length, 1, "nothing new on the second run");
});

stub.close();

// ---------------------------------------------------------------------------
// Build 6: the weekly timetable (JD-01, JD-02) and booking (VC-04). The
// test schedules sit in June 2027 so they never meet the seeded timetable.
const budi = await signIn("budi@test.chinesetracker");
const clara = await signIn("clara@test.chinesetracker");
const june = {validFrom: "2027-06-01", validTo: "2027-06-30", capacity: 8, level: ""};
const mon = (extra) => ({className: "Flow Kelas", weekday: 1, startMinutes: 960,
  endMinutes: 1050, room: "Main", ...june, ...extra});

// The thesis steps run with the teacher-readiness switch on (availability,
// confirmation, late check-in, recap) and the minimum-students rule off;
// the owner's 2026-11-23 defaults are checked at the end.
const RULES_THESIS = {minGapMinutes: 0, weeklyHoursWarning: 20, defaultCapacity: 8,
  teacherReadiness: true, minStudents: 0, minStudentsHours: 3};
const RULES_OWNER = {...RULES_THESIS, teacherReadiness: false, minStudents: 3};
await setDocRaw("settings/scheduling", RULES_THESIS);

await step("JD-01 a teacher clash, a room clash, outside availability and a foreign level are refused with the reason", async () => {
  const first = await call(admin, "saveSchedule", mon({teacherId: andrea.uid,
    className: `Flow Dasar ${RUN}`}));
  assert.ok(first.data, JSON.stringify(first.error));
  const clash = await call(admin, "checkScheduleConflict", mon({teacherId: andrea.uid,
    room: "Sub Room", startMinutes: 990, endMinutes: 1080}));
  assert.equal(clash.data.ok, false);
  assert.ok(clash.data.reasons.some((r) => r.code === "teacher" &&
    /already teaches Flow Dasar .* on Monday 16:00–17:30/.test(r.text)), JSON.stringify(clash.data));
  assert.ok(clash.data.suggestions.length >= 1, "free slots are suggested");
  const saved = await call(admin, "saveSchedule", mon({teacherId: andrea.uid, room: "Sub Room",
    startMinutes: 990, endMinutes: 1080}));
  assert.equal(reasonOf(saved), "conflict", "saveSchedule refuses it too");
  const room = await call(admin, "checkScheduleConflict", mon({teacherId: budi.uid}));
  assert.ok(room.data.reasons.some((r) => r.code === "room"));
  const ok = await call(admin, "checkScheduleConflict", mon({teacherId: budi.uid, room: "Sub Room"}));
  assert.equal(ok.data.ok, true, JSON.stringify(ok.data));
  const late = await call(admin, "checkScheduleConflict", mon({teacherId: andrea.uid,
    room: "Sub Room", startMinutes: 1200, endMinutes: 1290}));
  assert.ok(late.data.reasons.some((r) => r.code === "availability"));
  const level = await call(admin, "checkScheduleConflict", mon({teacherId: teacher.uid,
    room: "Sub Room", weekday: 2, level: "HSK 5"}));
  assert.ok(level.data.reasons.some((r) => r.code === "level"));
  const byTeacher = await call(teacher, "saveSchedule", mon({teacherId: teacher.uid}));
  assert.equal(byTeacher.error.status, "PERMISSION_DENIED");
});

await step("JD-02 two admins save the same teacher and time at once: one schedule", async () => {
  const body = {className: `Flow Race ${RUN}`, weekday: 3, startMinutes: 990, endMinutes: 1080,
    room: "Main", teacherId: clara.uid, ...june};
  const [a, b] = await Promise.all([call(admin, "saveSchedule", body),
    call(admin, "saveSchedule", {...body, room: "Sub Room"})]);
  const oks = [a, b].filter((r) => r.data && r.data.ok).length;
  assert.equal(oks, 1, `one wins: ${JSON.stringify([a.error, b.error])}`);
  const saved = (await queryDocs("schedules", "teacherId", clara.uid))
      .filter((d) => str(d.fields, "className") === `Flow Race ${RUN}`);
  assert.equal(saved.length, 1);
});

await step("generating sessions twice creates nothing new (deterministic ids)", async () => {
  const count = async () => (await queryDocs("class_sessions", "scheduleId", "sch_02")).length;
  const before = await count();
  assert.ok(before >= 1, "seeded generation made sessions");
  const job = await fetch(`${FN}/generateSessions-0`, {method: "POST",
    headers: {"Content-Type": "application/json"}, body: "{}"});
  assert.ok(job.ok);
  await new Promise((r) => setTimeout(r, 6000));
  assert.equal(await count(), before);
  const one = (await queryDocs("class_sessions", "scheduleId", "sch_02"))[0];
  assert.match(one.id, /^sch_02_\d{8}$/);
});

const s26 = await signIn("student26@test.chinesetracker");
// Sessions on a later day than today (Jakarta), so none has started yet.
const todayKey = new Date(Date.now() + 7 * 3600000).toISOString().slice(0, 10).replace(/-/g, "");
const futureOf = async (sid) => (await queryDocs("class_sessions", "scheduleId", sid))
    .filter((d) => str(d.fields, "status") === "scheduled")
    .filter((d) => d.id.slice(-8) > todayKey)
    .sort((x, y) => x.id.localeCompare(y.id));
let picks;
await step("VC-04 booking reserves a voucher session; with none left it is refused", async () => {
  for (const d of await queryDocs("student_class_terms", "studentId", s26.uid)) {
    await deleteDoc(`student_class_terms/${d.id}`);
  }
  await setDocRaw(`student_class_terms/flow_two_${RUN}`, {studentId: s26.uid, packageSize: 8,
    sessionsRemaining: 2, sessionsUsed: 6, sessionsBooked: 0, status: "active",
    startDate: "2026-11-01", deadlineDate: "2027-12-31", createdAt: new Date()});
  picks = [...(await futureOf("sch_03")), ...(await futureOf("sch_06")),
    ...(await futureOf("sch_09"))];
  assert.ok(picks.length >= 3, "three future sessions");
  for (const p of picks.slice(0, 2)) {
    const r = await call(s26, "bookSession", {sessionId: p.id});
    assert.ok(r.data, JSON.stringify(r.error));
  }
  const term = await readDoc(`student_class_terms/flow_two_${RUN}`);
  assert.equal(term.sessionsBooked, 2);
  assert.equal(term.sessionsRemaining, 2, "remaining moves only at close (Build 7)");
  const third = await call(s26, "bookSession", {sessionId: picks[2].id});
  assert.equal(reasonOf(third), "no_sessions");
  const seat = await readDoc(`class_sessions/${picks[0].id}`);
  assert.ok(seat.bookedCount >= 1);
});

await step("a full class, an overlapping class and a session on a day off are refused", async () => {
  await patchDoc(`student_class_terms/flow_two_${RUN}`, {sessionsRemaining: {integerValue: "8"}});
  const full = `flow_full_${RUN}`;
  const date = (await readDoc(`class_sessions/${picks[0].id}`)).sessionDate;
  await setDocRaw(`class_sessions/${full}`, {teacherId: budi.uid, sessionDate: "2027-01-05",
    sessionTitle: "Full", startMinutes: 600, endMinutes: 690, capacity: 1, bookedCount: 1,
    status: "scheduled", room: "Main", isOpen: true, isConcluded: false});
  assert.equal(reasonOf(await call(s26, "bookSession", {sessionId: full})), "full");
  const clash = `flow_clash_${RUN}`;
  const p0 = await readDoc(`class_sessions/${picks[0].id}`);
  await setDocRaw(`class_sessions/${clash}`, {teacherId: budi.uid, sessionDate: date,
    sessionTitle: "Clash", startMinutes: p0.startMinutes + 30, endMinutes: p0.endMinutes + 30,
    capacity: 8, bookedCount: 0, status: "scheduled", room: "Sub Room", isOpen: true,
    isConcluded: false});
  assert.equal(reasonOf(await call(s26, "bookSession", {sessionId: clash})), "overlap");
  const off = `flow_off_${RUN}`;
  await setDocRaw(`class_sessions/${off}`, {teacherId: budi.uid, sessionDate: "2027-01-06",
    sessionTitle: "Off", startMinutes: 600, endMinutes: 690, capacity: 8, bookedCount: 0,
    status: "needs_teacher", room: "Main", isOpen: true, isConcluded: false});
  assert.equal(reasonOf(await call(s26, "bookSession", {sessionId: off})), "needs_teacher");
});

await step("cancel before the start gives the seat and the session back; after the start it is refused", async () => {
  const id = picks[1].id;
  const before = await readDoc(`class_sessions/${id}`);
  const r = await call(s26, "cancelBooking", {sessionId: id});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal((await readDoc(`class_sessions/${id}`)).bookedCount, before.bookedCount - 1);
  assert.equal((await readDoc(`student_class_terms/flow_two_${RUN}`)).sessionsBooked, 1);
  assert.equal(await readDoc(`attendance/${id}_${s26.uid}`), null);
  await patchDoc(`class_sessions/${picks[0].id}`, {sessionDate: {stringValue: "2026-01-05"}});
  const late = await call(s26, "cancelBooking", {sessionId: picks[0].id});
  assert.equal(reasonOf(late), "too_late");
});

await step("a voucher's class day books its student into each new session", async () => {
  const s23 = await signIn("student23@test.chinesetracker");
  const sessions = await futureOf("sch_01");
  assert.ok(sessions.length >= 1);
  const att = await readDoc(`attendance/${sessions[0].id}_${s23.uid}`);
  assert.ok(att && att.booked === true, "booked by the generation job");
  assert.equal(att.bookedVia, "class_day");
});

await step("a parent books only for their own child; a student only for themself", async () => {
  const parent2 = await signIn("parent@test.chinesetracker");
  const notChild = await call(parent2, "bookSession", {studentId: s26.uid, sessionId: picks[2].id});
  assert.equal(reasonOf(notChild), "not-yours");
  const other = await call(s1, "bookSession", {studentId: s26.uid, sessionId: picks[2].id});
  assert.equal(reasonOf(other), "not-yours");
});

// ---------------------------------------------------------------------------
// Build 7: the teaching day — check-in, the close in one idempotent
// transaction with the voucher ledger (VC-01, VC-02, VC-03), reconciliation
// (VC-05), the late / reminder / unclosed job, substitutes and cancels.
const jak = new Date(Date.now() + 7 * 3600000);
const today7 = jak.toISOString().slice(0, 10);
const nowMin = jak.getUTCHours() * 60 + jak.getUTCMinutes();
const tomorrow7 = new Date(Date.now() + 31 * 3600000).toISOString().slice(0, 10);
const atMs = (date, min) => Date.parse(`${date}T00:00:00Z`) - 7 * 3600000 + min * 60000;
const juneMonday = (() => {
  for (let d = 1; d <= 7; d += 1) {
    const s = `2027-06-0${d}`;
    if (new Date(`${s}T00:00:00Z`).getUTCDay() === 1) return s;
  }
  return "2027-06-07";
})();
const juneTuesday = `2027-06-${String(Number(juneMonday.slice(-2)) + 1).padStart(2, "0")}`;
const day = await Promise.all([19, 20, 21, 22, 24, 27].map((n) =>
  signIn(`student${n}@test.chinesetracker`)));
const [d19, d20, d21, d22, d24, d27] = day;
const S7 = `flow7_${RUN}`;
const S7B = `flow7b_${RUN}`;
const S7C = `flow7c_${RUN}`;
const S7E = `flow7e_${RUN}`;
const term7 = (s) => `flow7_term_${s.uid}`;
const session7 = (id, extra) => setDocRaw(`class_sessions/${id}`, {teacherId: budi.uid,
  teacherName: "Budi Santoso", sessionTitle: `Flow Hari ${id}`, capacity: 8, bookedCount: 0,
  status: "scheduled", room: "Sub Room", level: "", isOpen: true, isConcluded: false,
  generated: true, scheduleId: "flow7_schedule", createdAt: new Date(), ...extra});
const notices = async (uid, title) => (await queryDocs("notifications", "userId", uid))
    .filter((n) => str(n.fields, "title") === title);

await step("Build 7 setup: five students with a voucher each book one session", async () => {
  for (const s of day) {
    for (const d of await queryDocs("student_class_terms", "studentId", s.uid)) {
      await deleteDoc(`student_class_terms/${d.id}`);
    }
    for (const a of await queryDocs("attendance", "studentId", s.uid)) {
      await deleteDoc(`attendance/${a.id}`);
    }
    await setDocRaw(`student_class_terms/${term7(s)}`, {studentId: s.uid, packageSize: 8,
      sessionsRemaining: 5, sessionsUsed: 3, sessionsBooked: 0, status: "active",
      startDate: "2026-11-01", deadlineDate: "2027-12-31", createdAt: new Date()});
  }
  await session7(S7, {sessionDate: tomorrow7, startMinutes: 370, endMinutes: 460});
  await session7(S7B, {sessionDate: tomorrow7, startMinutes: 480, endMinutes: 570,
    sessionTitle: "Flow Hari B"});
  for (const s of [d19, d20, d21, d22, d24]) {
    const r = await call(s, "bookSession", {sessionId: S7});
    assert.ok(r.data, JSON.stringify(r.error));
  }
  assert.equal((await readDoc(`class_sessions/${S7}`)).bookedCount, 5);
  assert.equal((await readDoc(`student_class_terms/${term7(d19)}`)).sessionsBooked, 1);
  // The class is today, started 20 minutes ago (the owner moves it).
  const start = Math.max(0, nowMin - 20);
  await patchDoc(`class_sessions/${S7}`, {sessionDate: {stringValue: today7},
    startMinutes: {integerValue: String(start)},
    endMinutes: {integerValue: String(Math.min(1439, start + 90))}});
});

await step("check-in: another teacher and a student are refused; the teacher starts it with the server time, flagged late", async () => {
  assert.equal(reasonOf(await call(teacher, "checkInSession", {sessionId: S7})), "not-yours");
  assert.equal((await call(d19, "checkInSession", {sessionId: S7})).error.status,
      "PERMISSION_DENIED");
  const r = await call(budi, "checkInSession", {sessionId: S7});
  assert.ok(r.data, JSON.stringify(r.error));
  const s = await readDoc(`class_sessions/${S7}`);
  assert.equal(s.status, "ongoing");
  assert.ok(s.checkInAt instanceof Date);
  if (nowMin >= 20) {
    assert.ok(s.lateMinutes >= 19, `late ${s.lateMinutes}`);
    assert.equal(s.lateCheckIn, true);
  }
  // Owner 2026-11-23: a second check-in changes nothing (the same answer).
  const again = await call(budi, "checkInSession", {sessionId: S7});
  assert.ok(again.data, JSON.stringify(again.error));
  assert.equal(again.data.lateMinutes, r.data.lateMinutes);
  assert.equal((await readDoc(`class_sessions/${S7}`)).checkInAt.getTime(), s.checkInAt.getTime());
});

await step("owner 2026-11-23: a late student joins a class that is going on; an ended class is refused", async () => {
  if (nowMin < 15 || nowMin > 1380) return; // too close to midnight to place both classes today
  const live = `flow7l_${RUN}`;
  const over = `flow7o_${RUN}`;
  await session7(live, {sessionDate: today7, startMinutes: nowMin - 10, endMinutes: nowMin + 50,
    sessionTitle: `Flow Late ${RUN}`});
  await session7(over, {sessionDate: today7, startMinutes: Math.max(0, nowMin - 15),
    endMinutes: nowMin - 1, sessionTitle: `Flow Over ${RUN}`});
  const r = await call(d27, "bookSession", {sessionId: live});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal((await readDoc(`attendance/${live}_${d27.uid}`)).lateJoin, true);
  assert.equal(reasonOf(await call(d27, "bookSession", {sessionId: over})), "too_late");
  // Put the seat and the voucher session back for the next steps.
  assert.ok((await call(admin, "cancelSession", {sessionId: live, reason: "flow"})).data);
  await deleteDoc(`attendance/${live}_${d27.uid}`);
  await setDocRaw(`student_class_terms/${term7(d27)}`, {studentId: d27.uid, packageSize: 8,
    sessionsRemaining: 5, sessionsUsed: 3, sessionsBooked: 0, status: "active",
    startDate: "2026-11-01", deadlineDate: "2027-12-31", createdAt: new Date()});
});

await step("VC-01 + VC-03 close (3 hadir, 1 izin, 1 alpa) while one of them books another session: both succeed, counts right", async () => {
  const statuses = {[d19.uid]: "hadir", [d20.uid]: "hadir", [d21.uid]: "hadir",
    [d22.uid]: "izin", [d24.uid]: "alpa"};
  assert.equal((await call(d19, "closeSession", {sessionId: S7, statuses})).error.status,
      "PERMISSION_DENIED");
  const [closed, booked] = await Promise.all([
    call(budi, "closeSession", {sessionId: S7, statuses}),
    call(d19, "bookSession", {sessionId: S7B}),
  ]);
  assert.ok(closed.data, JSON.stringify(closed.error));
  assert.ok(booked.data, JSON.stringify(booked.error));
  assert.equal(closed.data.credited, 4);
  assert.equal(closed.data.excused, 1);
  const t = async (s) => readDoc(`student_class_terms/${term7(s)}`);
  const t19 = await t(d19);
  assert.deepEqual([t19.sessionsUsed, t19.sessionsRemaining, t19.sessionsBooked], [4, 4, 1],
      "the new booking survives the close");
  for (const s of [d20, d21, d24]) {
    const x = await t(s);
    assert.deepEqual([x.sessionsUsed, x.sessionsRemaining, x.sessionsBooked], [4, 4, 0]);
  }
  const izin = await t(d22);
  assert.deepEqual([izin.sessionsUsed, izin.sessionsRemaining, izin.sessionsBooked], [3, 5, 0]);
  const ledger = [];
  for (const s of [d19, d20, d21, d22, d24]) {
    ledger.push(await readDoc(`voucher_history/${S7}_${s.uid}`));
  }
  assert.equal(ledger.filter(Boolean).length, 5, "five ledger docs");
  assert.deepEqual(ledger.map((e) => e.sessions), [-1, -1, -1, 0, -1]);
  assert.ok(ledger.every((e) => e.kind === "session"));
  const s = await readDoc(`class_sessions/${S7}`);
  assert.equal(s.status, "done");
  assert.equal(s.isConcluded, true);
  const a = await readDoc(`attendance/${S7}_${d24.uid}`);
  assert.equal(a.attendanceStatus, "alpa");
  assert.equal(a.sessionCredited, true);
  const recap = await readDoc(`teacher_recaps/${budi.uid}_${today7.slice(0, 7).replace("-", "")}`);
  assert.ok(recap.held >= 1 && recap.hours >= 1.5, JSON.stringify(recap));
});

await step("VC-02 closing the same session again deducts nothing", async () => {
  const before = await readDoc(`student_class_terms/${term7(d20)}`);
  const again = await call(budi, "closeSession", {sessionId: S7, statuses: {[d20.uid]: "alpa"}});
  assert.ok(again.data, JSON.stringify(again.error));
  assert.equal(again.data.already, true);
  const after = await readDoc(`student_class_terms/${term7(d20)}`);
  assert.deepEqual([after.sessionsUsed, after.sessionsRemaining],
      [before.sessionsUsed, before.sessionsRemaining]);
  assert.equal((await readDoc(`voucher_history/${S7}_${d20.uid}`)).status, "hadir");
});

await step("VC-05 reconcile: no mismatch on these vouchers; a counter broken by hand is reported", async () => {
  assert.equal((await call(budi, "reconcileVouchers", {})).error.status, "PERMISSION_DENIED");
  const mine = new Set(day.map(term7));
  const ok = await call(admin, "reconcileVouchers", {});
  assert.ok(ok.data, JSON.stringify(ok.error));
  assert.deepEqual(ok.data.mismatches.filter((m) => mine.has(m.termId)), []);
  await patchDoc(`student_class_terms/${term7(d21)}`, {sessionsUsed: {integerValue: "7"}});
  const bad = await call(admin, "reconcileVouchers", {});
  const found = bad.data.mismatches.filter((m) => mine.has(m.termId));
  assert.equal(found.length, 1);
  assert.equal(found[0].termId, term7(d21));
  assert.match(found[0].problems[0], /sessionsUsed [0-9]+ but 1 in the ledger/);
  await patchDoc(`student_class_terms/${term7(d21)}`, {sessionsUsed: {integerValue: "4"}});
});

await step("the job: the reminder goes once an hour before; late check-in is flagged once with one admin notice; unclosed after 2 hours", async () => {
  await session7(S7C, {sessionDate: juneMonday, startMinutes: 960, endMinutes: 1050,
    sessionTitle: `Flow Hari C ${RUN}`});
  const r = await call(d27, "bookSession", {sessionId: S7C});
  assert.ok(r.data, JSON.stringify(r.error));
  const pass = (min) => call(admin, "runTeachingDayPass", {nowMs: atMs(juneMonday, min)});
  const remind = async () => (await notices(d27.uid, "Class in an hour"))
      .filter((n) => str(n.fields, "body").includes(`Flow Hari C ${RUN}`)).length;
  assert.ok((await pass(920)).data);
  assert.equal(await remind(), 1);
  await pass(930);
  assert.equal(await remind(), 1, "once");
  assert.equal((await call(budi, "runTeachingDayPass", {})).error.status, "PERMISSION_DENIED");
  const lateNotes = async () => (await queryDocs("notifications", "forRole", "admin"))
      .filter((n) => str(n.fields, "title") === "Late check-in" &&
        str(n.fields, "body").includes(`Flow Hari C ${RUN}`)).length;
  assert.equal((await readDoc(`class_sessions/${S7C}`)).status, "scheduled", "not before the start");
  await pass(980);
  const startedC = await readDoc(`class_sessions/${S7C}`);
  assert.equal(startedC.status, "ongoing", "owner 2026-11-23: started by itself");
  assert.ok(startedC.autoStartedAt instanceof Date);
  assert.equal(startedC.lateCheckIn, true, "the teacher has not checked in");
  assert.equal(await lateNotes(), 1);
  await pass(1000);
  assert.equal(await lateNotes(), 1, "flagged once");
  await pass(1050 + 119);
  assert.notEqual((await readDoc(`class_sessions/${S7C}`)).unclosed, true);
  await pass(1050 + 121);
  assert.equal((await readDoc(`class_sessions/${S7C}`)).unclosed, true);
});

await step("substitute: the busy teacher is left out; the admin assigns one and everyone is told", async () => {
  assert.equal((await call(budi, "substituteCandidates", {sessionId: S7C})).error.status,
      "PERMISSION_DENIED");
  const c = await call(admin, "substituteCandidates", {sessionId: S7C});
  assert.ok(c.data, JSON.stringify(c.error));
  const ids = c.data.candidates.map((x) => x.uid);
  assert.ok(!ids.includes(budi.uid), "not the session's own teacher");
  assert.ok(!ids.includes(andrea.uid), "Andrea teaches Flow Dasar at that time");
  const sub = ids[0] || clara.uid;
  const r = await call(admin, "assignSubstitute", {sessionId: S7C, teacherId: sub});
  assert.ok(r.data, JSON.stringify(r.error));
  const s = await readDoc(`class_sessions/${S7C}`);
  assert.equal(s.teacherId, sub);
  assert.equal(s.substituteFor, budi.uid);
  assert.equal((await readDoc(`attendance/${S7C}_${d27.uid}`)).teacherId, sub);
  assert.equal((await notices(d27.uid, "Substitute teacher")).length, 1);
  assert.equal((await notices(sub, "Substitute teacher")).length >= 1, true);
  assert.equal((await notices(budi.uid, "Substitute teacher")).length >= 1, true);
});

await step("cancel: the teacher may not cancel a timetable session; the admin cancels and both bookings come back", async () => {
  await session7(S7E, {sessionDate: juneTuesday, startMinutes: 600, endMinutes: 690,
    sessionTitle: `Flow Hari E ${RUN}`});
  for (const s of [d20, d24]) {
    const r = await call(s, "bookSession", {sessionId: S7E});
    assert.ok(r.data, JSON.stringify(r.error));
  }
  assert.equal((await readDoc(`student_class_terms/${term7(d20)}`)).sessionsBooked, 1);
  assert.equal(reasonOf(await call(budi, "cancelSession", {sessionId: S7E})), "admin-only");
  const r = await call(admin, "cancelSession", {sessionId: S7E});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.returned, 2);
  const s = await readDoc(`class_sessions/${S7E}`);
  assert.equal(s.status, "cancelled");
  assert.equal(s.bookedCount, 0);
  for (const st of [d20, d24]) {
    assert.equal((await readDoc(`student_class_terms/${term7(st)}`)).sessionsBooked, 0);
    assert.equal((await readDoc(`attendance/${S7E}_${st.uid}`)).status, "cancelled");
    assert.equal((await notices(st.uid, "Class cancelled")).length, 1);
  }
  const again = await call(admin, "cancelSession", {sessionId: S7E});
  assert.ok(again.data);
  assert.equal(again.data.returned, 0, "a second cancel returns nothing");
  const rc = await call(admin, "reconcileVouchers", {});
  const mine = new Set(day.map(term7));
  assert.deepEqual(rc.data.mismatches.filter((m) => mine.has(m.termId)), []);
});

await step("confirm and change requests: the teacher confirms their own schedule, asks with a reason; the admin declines with a note", async () => {
  const sc = (await queryDocs("schedules", "teacherId", clara.uid))
      .find((d) => str(d.fields, "className") === `Flow Race ${RUN}`);
  assert.ok(sc);
  assert.equal(reasonOf(await call(budi, "confirmSchedule", {scheduleId: sc.id})), "not-yours");
  assert.ok((await call(clara, "confirmSchedule", {scheduleId: sc.id})).data);
  assert.equal((await readDoc(`schedules/${sc.id}`)).status, "confirmed");
  assert.equal(reasonOf(await call(clara, "requestScheduleChange", {scheduleId: sc.id,
    reason: " "})), "reason-required");
  const req = await call(clara, "requestScheduleChange", {scheduleId: sc.id,
    reason: "Exam week at my campus", wanted: "Thursday instead"});
  assert.ok(req.data, JSON.stringify(req.error));
  assert.equal((await readDoc(`schedule_change_requests/${req.data.requestId}`)).status, "open");
  assert.equal((await call(clara, "resolveScheduleChange", {requestId: req.data.requestId,
    accept: false})).error.status, "PERMISSION_DENIED");
  const done = await call(admin, "resolveScheduleChange", {requestId: req.data.requestId,
    accept: false, note: "Room is taken on Thursday"});
  assert.ok(done.data);
  const after = await readDoc(`schedule_change_requests/${req.data.requestId}`);
  assert.equal(after.status, "declined");
  assert.equal(after.note, "Room is taken on Thursday");
  assert.equal((await notices(clara.uid, "Schedule change declined")).length, 1);
});

await step("teacher recap: one row per teacher with scheduled, held, cancelled and hours", async () => {
  const r = await call(admin, "teacherRecap", {month: juneMonday.slice(0, 7).replace("-", "")});
  assert.ok(r.data, JSON.stringify(r.error));
  const b = r.data.rows.find((x) => x.teacherId === budi.uid);
  assert.ok(b && b.cancelled >= 1 && b.scheduled >= 1, JSON.stringify(r.data.rows));
  const now = await call(admin, "teacherRecap", {month: today7.slice(0, 7).replace("-", "")});
  const b2 = now.data.rows.find((x) => x.teacherId === budi.uid);
  assert.ok(b2 && b2.held >= 1 && b2.hours >= 1.5, JSON.stringify(b2));
  assert.equal((await call(budi, "teacherRecap", {month: "202701"})).error.status,
      "PERMISSION_DENIED");
});

await step("a forgotten one-attempt exam is closed by the hourly job", async () => {
  const id = `flow7_exam_${RUN}_${d27.uid}`;
  await setDocRaw(`exercise_attempts/${id}`, {studentId: d27.uid, exerciseId: "flow7_exam",
    category: "exam", startedAt: new Date(Date.now() - 2 * 3600000), timeLimitSeconds: 600});
  const r = await call(admin, "runTeachingDayPass", {attempts: true});
  assert.ok(r.data && r.data.attempts >= 1, JSON.stringify(r));
  const a = await readDoc(`exercise_attempts/${id}`);
  assert.ok(a.finishedAt instanceof Date);
  assert.equal(a.closedBy, "system");
  // Build 8: a zero result, so it shows in the student's history.
  const zero = await readDoc(`exercise_results/${id}_closed`);
  assert.ok(zero, "a zero result is written");
  assert.equal(zero.score, 0);
  assert.equal(zero.studentId, d27.uid);
  assert.equal(zero.late, true);
  const again = await call(admin, "runTeachingDayPass", {attempts: true});
  assert.equal(again.data.attempts, 0, "closed once");
});

// ---------------------------------------------------------------------------
// Build 8: the monthly report and the seed's counts.
await step("monthly report: admin-only rebuild; revenue equals this month's paid invoices", async () => {
  const month = today7.slice(0, 7).replace("-", "");
  assert.equal((await call(budi, "rebuildMonthlyReport", {month})).error.status,
      "PERMISSION_DENIED");
  assert.equal(reasonOf(await call(admin, "rebuildMonthlyReport", {month: "2026-11"})), "month");
  const r = await call(admin, "rebuildMonthlyReport", {month});
  assert.ok(r.data, JSON.stringify(r.error));
  const from = Date.parse(`${today7.slice(0, 7)}-01T00:00:00+07:00`);
  const [y, m] = [Number(month.slice(0, 4)), Number(month.slice(4))];
  const to = Date.parse(`${m === 12 ? y + 1 : y}-${String(m === 12 ? 1 : m + 1).padStart(2, "0")}-01T00:00:00+07:00`);
  let revenue = 0;
  for (const d of await queryDocs("invoices", "status", "paid")) {
    const paidAt = d.fields.paidAt && Date.parse(d.fields.paidAt.timestampValue);
    if (paidAt >= from && paidAt < to) revenue += Number(d.fields.amount.integerValue ?? d.fields.amount.doubleValue ?? 0);
  }
  assert.equal(r.data.revenue, revenue);
  const stored = await readDoc(`reports/${month}`);
  assert.equal(stored.revenue, revenue);
  assert.ok(stored.teachingHours >= 1.5, "Build 7's closed session counts");
});

await step("the seed: one admin and four teachers, the flyer's ten schedules, no duplicates", async () => {
  const admins = (await queryDocs("users", "role", "admin")).filter((d) => !d.id.startsWith("trial_"));
  const teachers = (await queryDocs("users", "role", "teacher")).filter((d) => !d.id.startsWith("trial_"));
  assert.equal(admins.length, 1);
  assert.equal(teachers.length, 4);
  const flyer = (await listDocs("schedules?pageSize=300")).filter((d) => /\/sch_\d\d$/.test(d.name));
  assert.equal(flyer.length, 10);
});

// ---------------------------------------------------------------------------
// Owner requests 2026-11-23 and the After-Build-8 follow-ups.
await step("owner 2026-11-23: back-to-back classes are fine; the admin's gap is named; Recheck answers the same", async () => {
  const a = {className: `Flow Back A ${RUN}`, weekday: 2, startMinutes: 900, endMinutes: 990,
    room: "Main", teacherId: clara.uid, ...june};
  const saved = await call(admin, "saveSchedule", a);
  assert.ok(saved.data, JSON.stringify(saved.error));
  const b = {...a, className: `Flow Back B ${RUN}`, startMinutes: 991, endMinutes: 1080};
  const ok = await call(admin, "checkScheduleConflict", b);
  assert.equal(ok.data.ok, true, JSON.stringify(ok.data));
  assert.equal((await call(admin, "checkScheduleConflict", {...b, startMinutes: 990})).data.ok, true,
      "back to back");
  await setDocRaw("settings/scheduling", {...RULES_THESIS, minGapMinutes: 15});
  const gap = await call(admin, "checkScheduleConflict", b);
  assert.equal(gap.data.ok, false);
  assert.ok(gap.data.reasons.every((r) => /15 minutes are needed between classes/.test(r.text)),
      JSON.stringify(gap.data.reasons));
  await setDocRaw("settings/scheduling", RULES_THESIS);
  const second = await call(admin, "saveSchedule", b);
  assert.ok(second.data, JSON.stringify(second.error));
  for (const id of [saved.data.scheduleId, second.data.scheduleId]) {
    assert.ok((await call(admin, "deleteSchedule", {scheduleId: id})).data);
  }
});

await step("owner 2026-11-23: deleting a schedule cancels its coming sessions and clears the class day; admin only", async () => {
  const body = {className: `Flow Delete ${RUN}`, weekday: 5, startMinutes: 1080, endMinutes: 1140,
    room: "Sub Room", teacherId: clara.uid, ...june};
  const saved = await call(admin, "saveSchedule", body);
  assert.ok(saved.data, JSON.stringify(saved.error));
  const id = saved.data.scheduleId;
  const sess = `${id}_flow`;
  await session7(sess, {scheduleId: id, sessionDate: tomorrow7, startMinutes: 1080,
    endMinutes: 1140, teacherId: clara.uid, sessionTitle: `Flow Delete ${RUN}`});
  const term = `flow_del_term_${RUN}`;
  await setDocRaw(`student_class_terms/${term}`, {studentId: d24.uid, packageSize: 8,
    sessionsRemaining: 0, sessionsUsed: 8, sessionsBooked: 0, status: "used_up",
    startDate: "2026-11-01", deadlineDate: "2027-12-31", classDay: id, createdAt: new Date()});
  assert.equal((await call(budi, "deleteSchedule", {scheduleId: id})).error.status, "PERMISSION_DENIED");
  const r = await call(admin, "deleteSchedule", {scheduleId: id});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal(r.data.cancelled, 1);
  assert.equal(r.data.classDaysCleared, 1);
  assert.equal(await readDoc(`schedules/${id}`), null);
  assert.equal((await readDoc(`class_sessions/${sess}`)).status, "cancelled");
  assert.equal((await readDoc(`student_class_terms/${term}`)).classDay, undefined);
  await deleteDoc(`student_class_terms/${term}`);
});

await step("follow-up: a voucher that gets a class day is booked into that schedule's coming sessions", async () => {
  const coming = (await futureOf("sch_03")).length;
  assert.ok(coming >= 1, "the seed generated sch_03 sessions");
  await patchDoc(`student_class_terms/${term7(d20)}`, {classDay: {stringValue: "sch_03"}});
  let mine = [];
  for (let i = 0; i < 30 && !mine.length; i += 1) {
    await new Promise((res) => setTimeout(res, 1000));
    mine = (await queryDocs("attendance", "studentId", d20.uid))
        .filter((a) => str(a.fields, "sessionId").startsWith("sch_03_") &&
          str(a.fields, "bookedVia") === "class_day");
  }
  assert.ok(mine.length >= 1, "booked by the trigger");
  const t = await readDoc(`student_class_terms/${term7(d20)}`);
  assert.equal(t.sessionsBooked, mine.length);
  assert.equal(reasonOf(await call(s1, "createInvoice", {studentId: s1.uid,
    priceItemId: "package8", acceptedTerms: true, classDay: "no_such_schedule"})), "class-day");
});

await step("follow-up: decideRegistration uses the admin's minimum of codes", async () => {
  const p = await readDoc("settings/promotion");
  const want = p && p.minCodes ? p.minCodes : 3;
  for (const d of await queryDocs("promotion_progress", "minCodes", want)) {
    assert.equal(Number(d.fields.minCodes.integerValue), want);
  }
});

await step("follow-up: visitor details on unclaimed placement results are cleared after 180 days", async () => {
  assert.equal((await call(budi, "runPlacementCleanup", {})).error.status, "PERMISSION_DENIED");
  const now = await call(admin, "runPlacementCleanup", {});
  assert.ok(now.data, JSON.stringify(now.error));
  const unclaimed = (await queryDocs("placement_results", "claimedBy", ""))
      .filter((d) => str(d.fields, "name"));
  assert.ok(unclaimed.length >= 1, "the flow left an unclaimed visitor result");
  const later = await call(admin, "runPlacementCleanup", {nowMs: Date.now() + 181 * 86400000});
  assert.ok(later.data.cleared >= unclaimed.length);
  for (const d of unclaimed) {
    const r = await readDoc(`placement_results/${d.id}`);
    assert.equal(r.name, "");
    assert.equal(r.whatsapp, "");
    assert.ok(Number.isFinite(r.total), "the marks stay");
  }
  assert.equal((await readDoc(`placement_results/${visitor.attemptId}`)).name, "Flow Visitor",
      "a claimed result is kept");
});

// ---------------------------------------------------------------------------
// Owner requests 2026-11-23, second round.
await step("owner 2026-11-23: with teacher readiness off, availability is not checked and a new schedule is confirmed", async () => {
  await setDocRaw("settings/scheduling", RULES_OWNER);
  const late = await call(admin, "checkScheduleConflict", mon({teacherId: andrea.uid,
    room: "Sub Room", startMinutes: 1200, endMinutes: 1290}));
  assert.equal(late.data.ok, true, JSON.stringify(late.data));
  const saved = await call(admin, "saveSchedule", mon({teacherId: andrea.uid, room: "Sub Room",
    startMinutes: 1200, endMinutes: 1290, className: `Flow Ready ${RUN}`}));
  assert.ok(saved.data, JSON.stringify(saved.error));
  assert.equal((await readDoc(`schedules/${saved.data.scheduleId}`)).status, "confirmed");
  assert.ok((await call(admin, "deleteSchedule", {scheduleId: saved.data.scheduleId})).data);
});

await step("owner 2026-11-23: a helper teacher is checked for clashes, is saved on the schedule and may close the class", async () => {
  // Andrea teaches Flow Dasar on Monday 16:00-17:30 in June (JD-01).
  const clash = await call(admin, "checkScheduleConflict", mon({teacherId: clara.uid,
    coTeacherIds: [andrea.uid], room: "Sub Room", startMinutes: 990, endMinutes: 1080}));
  assert.equal(clash.data.ok, false);
  assert.ok(clash.data.reasons.some((r) => /Andrea .*already teaches Flow Dasar/.test(r.text)),
      JSON.stringify(clash.data.reasons));
  const saved = await call(admin, "saveSchedule", {className: `Flow Duo ${RUN}`, weekday: 7,
    startMinutes: 600, endMinutes: 690, room: "Sub Room", teacherId: clara.uid,
    coTeacherIds: [andrea.uid, clara.uid, andrea.uid], ...june});
  assert.ok(saved.data, JSON.stringify(saved.error));
  const sch = await readDoc(`schedules/${saved.data.scheduleId}`);
  assert.deepEqual(sch.coTeacherIds, [andrea.uid], "unique, not the main teacher");
  assert.equal(sch.coTeacherNames.length, 1);
  assert.ok((await call(admin, "deleteSchedule", {scheduleId: saved.data.scheduleId})).data);
  // A one-off class with Andrea as helper: Andrea may close it, Budi may not.
  const one = `flow_duo_${RUN}`;
  await setDocRaw(`class_sessions/${one}`, {teacherId: clara.uid, teacherName: "Clara",
    coTeacherIds: [andrea.uid], sessionTitle: "Flow Duo", sessionDate: today7, startMinutes: 0,
    endMinutes: 60, capacity: 8, bookedCount: 0, status: "ongoing", isOpen: true,
    isConcluded: false, generated: false, room: "Main", createdAt: new Date()});
  await setDocRaw(`attendance/${one}_${d27.uid}`, {sessionId: one, studentId: d27.uid,
    teacherId: clara.uid, sessionDate: today7, sessionTitle: "Flow Duo", startMinutes: 0,
    endMinutes: 60, attended: true, booked: false, joinedBy: "teacher", sessionCredited: false,
    studentName: "Student 27"});
  assert.equal(reasonOf(await call(budi, "closeSession", {sessionId: one, statuses: {}})), "not-yours");
  const closed = await call(andrea, "closeSession", {sessionId: one,
    statuses: {[d27.uid]: "hadir"}, board: {[d27.uid]: true}, boardExtras: "Dodi",
    boardMismatches: 1});
  assert.ok(closed.data, JSON.stringify(closed.error));
  assert.equal((await readDoc(`attendance/${one}_${d27.uid}`)).onBoard, true);
  const after = await readDoc(`class_sessions/${one}`);
  assert.equal(after.status, "done");
  assert.equal(after.boardExtras, "Dodi");
  assert.equal(after.boardMismatches, 1);
});

await step("owner 2026-11-23: fewer than 3 booked students close a class 3 hours before; 3 keep it", async () => {
  const few = `flow_few_${RUN}`;
  const full = `flow_full_${RUN}`;
  await session7(few, {sessionDate: juneTuesday, startMinutes: 960, endMinutes: 1050,
    bookedCount: 0, sessionTitle: `Flow Few ${RUN}`});
  await session7(full, {sessionDate: juneTuesday, startMinutes: 960, endMinutes: 1050,
    bookedCount: 3, sessionTitle: `Flow Full ${RUN}`});
  const pass = (min) => call(admin, "runTeachingDayPass", {nowMs: atMs(juneTuesday, min)});
  assert.ok((await pass(770)).data, "more than 3 hours before: nothing");
  assert.equal((await readDoc(`class_sessions/${few}`)).status, "scheduled");
  const r = await pass(790);
  assert.ok(r.data.tooFew >= 1, JSON.stringify(r.data));
  const f = await readDoc(`class_sessions/${few}`);
  assert.equal(f.status, "cancelled");
  assert.equal(f.cancelReason, "too_few");
  const k = await readDoc(`class_sessions/${full}`);
  assert.equal(k.status, "scheduled");
  assert.ok(k.minStudentsCheckedAt instanceof Date);
  const told = (await queryDocs("notifications", "userId", budi.uid))
      .filter((n) => str(n.fields, "title") === "Class closed: too few students");
  assert.ok(told.length >= 1, "the teacher is told");
  // With readiness off, no late check-in is flagged on the kept class.
  await pass(980);
  assert.notEqual((await readDoc(`class_sessions/${full}`)).lateCheckIn, true);
});

await step("owner 2026-11-23: Indonesian holidays load once; closing a day cancels its classes and posts an announcement; opening brings them back", async () => {
  assert.equal((await call(budi, "importHolidays", {})).error.status, "PERMISSION_DENIED");
  const first = await call(admin, "importHolidays", {});
  assert.ok(first.data, JSON.stringify(first.error));
  const again = await call(admin, "importHolidays", {});
  assert.equal(again.data.added, 0, "no copies");
  assert.equal((await readDoc("holidays/2027-03-10")).name, "Idulfitri 1448 Hijriah");
  const day = `flow_day_${RUN}`;
  await session7(day, {sessionDate: tomorrow7, startMinutes: 1000, endMinutes: 1090,
    sessionTitle: `Flow Day ${RUN}`});
  assert.equal((await call(budi, "setDayClosed", {date: tomorrow7, closed: true})).error.status,
      "PERMISSION_DENIED");
  const closed = await call(admin, "setDayClosed", {date: tomorrow7, closed: true,
    name: `Flow libur ${RUN}`});
  assert.ok(closed.data, JSON.stringify(closed.error));
  assert.ok(closed.data.cancelled >= 1);
  const c = await readDoc(`class_sessions/${day}`);
  assert.equal(c.status, "cancelled");
  assert.equal(c.cancelReason, "day_closed");
  assert.equal((await readDoc(`holidays/${tomorrow7}`)).decision, "closed");
  const ann = await readDoc(`announcements/${closed.data.announcementId}`);
  assert.equal(ann.kind, "closure");
  assert.equal(ann.toDate, tomorrow7);
  const opened = await call(admin, "setDayClosed", {date: tomorrow7, closed: false});
  assert.ok(opened.data.reopened >= 1, JSON.stringify(opened.data));
  assert.equal((await readDoc(`class_sessions/${day}`)).status, "scheduled");
  assert.equal((await readDoc(`holidays/${tomorrow7}`)).decision, "open");
});

await step("owner 2026-11-24 (Q12): an admin promotes a student straight away; only upwards, with a reason; the student is told", async () => {
  await patchDoc(`users/${s26.uid}`, {level: {stringValue: "HSK 2"}});
  assert.equal((await call(budi, "promoteStudent", {studentId: s26.uid, toLevel: "HSK 4",
    reason: "x"})).error.status, "PERMISSION_DENIED");
  assert.equal((await call(admin, "promoteStudent", {studentId: s26.uid, toLevel: "HSK 4"}))
      .error.status, "INVALID_ARGUMENT", "a reason is required");
  assert.equal((await call(admin, "promoteStudent", {studentId: s26.uid, toLevel: "HSK 1",
    reason: "x"})).error.status, "INVALID_ARGUMENT", "only upwards");
  const r = await call(admin, "promoteStudent", {studentId: s26.uid, toLevel: "HSK 4",
    reason: `Very capable ${RUN}`});
  assert.ok(r.data, JSON.stringify(r.error));
  assert.equal((await readDoc(`users/${s26.uid}`)).level, "HSK 4");
  const prog = await readDoc(`promotion_progress/${s26.uid}`);
  assert.equal(prog.levelKey, "4");
  assert.equal(prog.count, 0);
  const hist = await listDocs(`users/${s26.uid}/level_history`);
  assert.ok(hist.some((d) => d.fields.kind?.stringValue === "manual" &&
    d.fields.to?.stringValue === "HSK 4"), "a manual history row");
  const notes = await queryDocs("notifications", "userId", s26.uid);
  assert.ok(notes.some((n) => str(n.fields, "kind") === "promotion" &&
    /HSK 4/.test(str(n.fields, "body"))), "the student is told");
});

await step("owner 2026-11-24: a News post with a notification rings the bell of its audience only", async () => {
  const id = `flow_ann_${RUN}`;
  assert.equal(await writeAs(budi, `announcements/${id}_x`, {title: "x", body: "", audience: "all",
    toDate: "2099-01-01", kind: "info", notify: true}), 403, "teachers cannot post");
  assert.equal(await writeAs(admin, `announcements/${id}`, {title: `Flow news ${RUN}`, body: "Hello",
    audience: "teachers", toDate: "2099-01-01", kind: "info", notify: true}), 200);
  const note = await waitFor(() => readDoc(`notifications/ann_${id}_teacher`), "the teacher notice");
  assert.equal(note.forRole, "teacher");
  assert.equal(note.kind, "announcement");
  assert.equal(await readDoc(`notifications/ann_${id}_student`), null, "students are not told");
  await writeAs(admin, `announcements/${id}_quiet`, {title: "Quiet", body: "", audience: "all",
    toDate: "2099-01-01", kind: "info", notify: false});
  await new Promise((r) => setTimeout(r, 2500));
  assert.equal(await readDoc(`notifications/ann_${id}_quiet_teacher`), null, "no notice without the tick");
});

await step("owner 2026-11-24 (App Store): a student deletes their own account after a fresh sign-in; staff cannot; records stay", async () => {
  // A fresh student linked to the seed parent.
  const email = `selfdel_${RUN}@test.chinesetracker`;
  const r = await fetch(`${AUTH}/accounts:signUp?key=fake`, {method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password: PASSWORD, returnSecureToken: true})});
  const j = await r.json();
  assert.ok(j.localId, JSON.stringify(j).slice(0, 200));
  await setDocRaw(`users/${j.localId}`, {email, name: "Self Delete", role: "student",
    status: "active", active: true, linkedParentUid: parent.uid});
  await patchDoc(`users/${parent.uid}`, {studentIds: {arrayValue: {values: [{stringValue: j.localId}]}}});
  await setDocRaw(`invoices/selfdel_${RUN}`, {studentId: j.localId, amount: 1000, status: "paid"});
  assert.equal((await call(teacher, "deleteMyAccount", {})).error.status, "PERMISSION_DENIED",
      "staff ask an admin");
  const me = {token: j.idToken, uid: j.localId};
  const done = await call(me, "deleteMyAccount", {});
  assert.ok(done.data && done.data.deleted, JSON.stringify(done.error));
  assert.equal(await readDoc(`users/${j.localId}`), null, "the profile is gone");
  const again = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password: PASSWORD, returnSecureToken: true})});
  assert.ok(!again.ok, "the sign-in is gone");
  assert.ok(await readDoc(`invoices/selfdel_${RUN}`), "the invoice stays as a record");
  const p = await readDoc(`users/${parent.uid}`);
  assert.ok(!(p.studentIds || []).includes(j.localId), "the parent's list forgets the child");
});

await step("owner 2026-11-24: a reopened holiday is announced as 'classes run' and replaces the closing notice", async () => {
  const anns = await queryDocs("announcements", "date", tomorrow7);
  const kinds = anns.map((x) => str(x.fields, "kind"));
  assert.ok(kinds.includes("opened"), JSON.stringify(kinds));
  assert.ok(!kinds.includes("closure"), "the closing notice of that day is gone");
});

await step("owner 2026-11-24: an admin discards an unpaid invoice with a reason, may restore it; a paid one cannot be discarded", async () => {
  const id = `flow_disc_${RUN}`;
  await setDocRaw(`invoices/${id}`, {invoiceNumber: `INV-${RUN}`, studentId: s1.uid,
    amount: 5000, status: "pending", paymentMethod: "manual", item: "other"});
  assert.equal((await call(teacher, "discardInvoice", {invoiceId: id, reason: "x"})).error.status,
      "PERMISSION_DENIED");
  assert.equal((await call(admin, "discardInvoice", {invoiceId: id})).error.status,
      "FAILED_PRECONDITION", "a reason is required");
  const done = await call(admin, "discardInvoice", {invoiceId: id, reason: "Duplicate"});
  assert.ok(done.data, JSON.stringify(done.error));
  let inv = await readDoc(`invoices/${id}`);
  assert.equal(inv.status, "discarded");
  assert.equal(inv.discardReason, "Duplicate");
  assert.equal(inv.statusBeforeDiscard, "pending");
  const back = await call(admin, "discardInvoice", {invoiceId: id, restore: true});
  assert.ok(back.data, JSON.stringify(back.error));
  inv = await readDoc(`invoices/${id}`);
  assert.equal(inv.status, "pending");
  await setDocRaw(`invoices/${id}_paid`, {invoiceNumber: `INV-${RUN}-P`, studentId: s1.uid,
    amount: 5000, status: "paid"});
  assert.equal((await call(admin, "discardInvoice", {invoiceId: `${id}_paid`, reason: "x"}))
      .error.status, "FAILED_PRECONDITION", "a paid invoice stays");
});

console.log(`supervised flow: ${passed} steps passed`);
