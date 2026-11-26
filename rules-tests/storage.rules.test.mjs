// Storage rules tests (Build 1B): question-bank media limits. Runs against
// the Storage and Firestore emulators (the rules read the user's role):
//   npm --prefix rules-tests run test:emulator      (from the repo root)
import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, it } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, setDoc } from "firebase/firestore";
import { getBytes, ref, uploadBytes } from "firebase/storage";

const PROJECT_ID = "demo-chinese-tracker";
let env;

const USERS = {
  admin1: { role: "admin", email: "admin@test", name: "Admin", active: true },
  student1: { role: "student", email: "s1@test", name: "Murid", active: true },
  teacher1: { role: "teacher", email: "t1@test", name: "Guru", active: true },
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8") },
    storage: { rules: readFileSync(new URL("../storage.rules", import.meta.url), "utf8") },
  });
});
after(async () => { await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const [uid, data] of Object.entries(USERS)) {
      await setDoc(doc(ctx.firestore(), "users", uid), data);
    }
  });
});

const MB = 1024 * 1024;
const upload = (uid, name, size, contentType) =>
  uploadBytes(
    ref(env.authenticatedContext(uid).storage(), `question_bank_media/${uid}/${name}`),
    new Uint8Array(size),
    { contentType },
  );

describe("question bank media limits (Build 1B)", () => {
  it("a recording up to 60 MB is allowed for staff", async () => {
    await assertSucceeds(upload("admin1", "paper.mp3", 25 * MB, "audio/mpeg"));
  });

  it("a recording of 60 MB or more is refused", async () => {
    await assertFails(upload("admin1", "too_long.mp3", 60 * MB + 1, "audio/mpeg"));
  });

  it("a picture stays under 10 MB", async () => {
    await assertSucceeds(upload("admin1", "pic.png", 2 * MB, "image/png"));
    await assertFails(upload("admin1", "big.png", 11 * MB, "image/png"));
  });

  it("a large file that is not audio cannot pass as a recording", async () => {
    await assertFails(upload("admin1", "fake.mp3", 20 * MB, "application/octet-stream"));
  });

  it("students cannot upload bank media", async () => {
    await assertFails(upload("student1", "x.mp3", 1 * MB, "audio/mpeg"));
  });
});

// Owner 2026-11-26: the answer-sheet PDF is the key: admins only.
describe("answer sheets (2026-11-26)", () => {
  const put = (who, folder, size, contentType) =>
    uploadBytes(
      ref(env.authenticatedContext(who).storage(), `answer_sheets/${folder}/key.pdf`),
      new Uint8Array(size),
      { contentType },
    );

  it("an admin stores a PDF in their own folder and reads it back", async () => {
    await assertSucceeds(put("admin1", "admin1", 1 * MB, "application/pdf"));
    await assertSucceeds(
      getBytes(ref(env.authenticatedContext("admin1").storage(), "answer_sheets/admin1/key.pdf")));
  });

  it("not a PDF, too large, or another admin's folder is refused", async () => {
    await assertFails(put("admin1", "admin1", 1 * MB, "image/png"));
    await assertFails(put("admin1", "admin1", 25 * MB, "application/pdf"));
    await assertFails(put("admin1", "someone", 1 * MB, "application/pdf"));
  });

  it("teachers and students neither upload nor read it", async () => {
    await assertSucceeds(put("admin1", "admin1", 1 * MB, "application/pdf"));
    await assertFails(put("teacher1", "teacher1", 1 * MB, "application/pdf"));
    await assertFails(put("student1", "student1", 1 * MB, "application/pdf"));
    for (const who of ["teacher1", "student1"]) {
      await assertFails(
        getBytes(ref(env.authenticatedContext(who).storage(), "answer_sheets/admin1/key.pdf")));
    }
  });
});

// Owner 2026-11-26: the photo kept when an invoice is marked paid: admins only.
describe("payment photos (2026-11-26)", () => {
  const put = (who, size, contentType) =>
    uploadBytes(
      ref(env.authenticatedContext(who).storage(), "payment_proofs/inv1/1.jpg"),
      new Uint8Array(size),
      { contentType },
    );

  it("an admin stores a photo and reads it back", async () => {
    await assertSucceeds(put("admin1", 1 * MB, "image/jpeg"));
    await assertSucceeds(
      getBytes(ref(env.authenticatedContext("admin1").storage(), "payment_proofs/inv1/1.jpg")));
  });

  it("not an image, an SVG, or too large is refused", async () => {
    await assertFails(put("admin1", 1 * MB, "application/pdf"));
    await assertFails(put("admin1", 1 * MB, "image/svg+xml"));
    await assertFails(put("admin1", 21 * MB, "image/jpeg"));
  });

  it("teachers and students neither upload nor read it", async () => {
    await assertSucceeds(put("admin1", 1 * MB, "image/jpeg"));
    for (const who of ["teacher1", "student1"]) {
      await assertFails(put(who, 1 * MB, "image/jpeg"));
      await assertFails(
        getBytes(ref(env.authenticatedContext(who).storage(), "payment_proofs/inv1/1.jpg")));
    }
  });
});
