// End-to-end check of the supervised test track against the local emulator
// suite (auth 9099, firestore 8080, functions 5001), using the seeded data
// (scripts/seed_emulator.py: test code H3DEMO1, packages pkg_practice and
// pkg_exam). Run after seeding:
//   node functions/test_supervised_flow.mjs
// Thesis scenario IDs (docs/THESIS_FEATURE_BACKLOG.md §13) are in the step
// names: TS-01, TS-02, PN-04, PN-05, LV-02.
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

console.log(`supervised flow: ${passed} steps passed`);
