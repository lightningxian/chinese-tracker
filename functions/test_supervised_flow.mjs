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

console.log(`supervised flow: ${passed} steps passed`);
