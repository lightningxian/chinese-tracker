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
import { ref, uploadBytes } from "firebase/storage";

const PROJECT_ID = "demo-chinese-tracker";
let env;

const USERS = {
  admin1: { role: "admin", email: "admin@test", name: "Admin", active: true },
  student1: { role: "student", email: "s1@test", name: "Murid", active: true },
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
