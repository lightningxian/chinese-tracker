#!/usr/bin/env python3
"""Seed the local Firebase emulators with demo data for Easy Study.

Run the emulators first (no functions, they need project billing):
    firebase emulators:start --only auth,firestore,storage --project chinese-tracker
then:
    python3 scripts/seed_emulator.py
and run the app against them:
    flutter run -d web-server --web-port=5181 --release --dart-define=USE_EMULATORS=true

All accounts use the password below. Nothing here touches the live project:
every request goes to localhost. Names are invented demo data.
"""
import datetime as dt
import json
import os
import random
import sys
import urllib.error
import urllib.request

PROJECT = "chinese-tracker"
# 127.0.0.1, not localhost: on Windows "localhost" tries IPv6 first and every
# request waits for that to fail (the seed took minutes instead of seconds).
AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1"
FS = f"http://127.0.0.1:8080/v1/projects/{PROJECT}/databases/(default)/documents"
# Build 2A: not the live test accounts' password, so a sign-in saved in the
# emulator bundle can never work on the live project.
PASSWORD = "emulator-only-7"
TODAY = dt.date.today()
random.seed(7)


# ---------------------------------------------------------------- REST helpers
def _req(url, method="POST", body=None, headers=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {url} -> {e.code}: {e.read().decode()[:300]}")


def auth_user(email):
    """Create (or reuse) an emulator Auth user; returns the uid."""
    body = {"email": email, "password": PASSWORD, "returnSecureToken": True}
    try:
        return _req(f"{AUTH}/accounts:signInWithPassword?key=fake", body=body)["localId"]
    except SystemExit as e:
        if "EMAIL_NOT_FOUND" not in str(e):
            raise
    return _req(f"{AUTH}/accounts:signUp?key=fake", body=body)["localId"]


def fv(v):
    """Python value -> Firestore REST value."""
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, dt.datetime):
        return {"timestampValue": v.replace(microsecond=0).isoformat() + "Z"}
    if isinstance(v, list):
        return {"arrayValue": {"values": [fv(x) for x in v]}}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: fv(x) for k, x in v.items()}}}
    return {"stringValue": str(v)}


def put(collection, doc_id, data):
    # "Bearer owner" bypasses security rules in the emulator.
    _req(f"{FS}/{collection}/{doc_id}", method="PATCH",
         body={"fields": {k: fv(v) for k, v in data.items()}},
         headers={"Authorization": "Bearer owner"})


def ts(days=0, hour=9):
    d = dt.datetime.combine(TODAY, dt.time(hour)) + dt.timedelta(days=days)
    return d


def ymd(days=0):
    return (TODAY + dt.timedelta(days=days)).isoformat()


# ---------------------------------------------------------------- data
TEACHERS = [
    ("teacher", "Test Teacher", "李老师"),
    ("andrea", "Andrea Natasha", "陈安娜"),
    ("budi", "Budi Santoso", "王布迪"),
    ("clara", "Clara Wijaya", "黄克拉"),
]
FIRST = ["Angeline", "Bryan", "Cindy", "Darren", "Evelyn", "Felix", "Gracia",
         "Hans", "Ivana", "Jason", "Kelvin", "Laura", "Marvin", "Nadia",
         "Owen", "Priscilla", "Quinn", "Ryan", "Stella", "Tommy", "Ursula",
         "Vincent", "Wilson", "Xaviera", "Yosua", "Zoe", "Aurel", "Bima",
         "Celine", "Devan"]
LAST = ["Santoso", "Wijaya", "Hartono", "Tanuwijaya", "Gunawan", "Halim",
        "Kusuma", "Lim", "Tan", "Setiawan"]
CN = ["陈美琳", "林志明", "张婷婷", "黄俊杰", "刘雅文", "王建国", "吴佳怡",
      "周文豪", "郑雪丽", "蔡伟强"]
LEVELS = ["HSK 1"] * 6 + ["HSK 2"] * 6 + ["HSK 3"] * 5 + ["HSK 4"] * 5 + \
         ["HSK 5"] * 4 + ["HSK 6"] * 4
# Build 3: the rooms list (settings/rooms); "Ruang 3" is an old free-text
# room that stays selectable on the session form.
ROOMS = ["Main", "Sub Room", "Ruang 3"]
TEACHER_LEVELS = [["HSK 1", "HSK 2"], ["HSK 1", "HSK 2", "HSK 3"], ["HSK 3", "HSK 4"],
                  ["HSK 5", "HSK 6"]]


def main():
    try:
        urllib.request.urlopen("http://localhost:8080", timeout=3)
    except Exception:
        sys.exit("Firestore emulator not reachable on :8080. Start the emulators first.")

    created = dt.datetime(2026, 8, 1, 9)

    # Admin
    admin_uid = auth_user("admin@test.chinesetracker")
    put("users", admin_uid, {"email": "admin@test.chinesetracker", "name": "Platform Admin",
        "nameIndonesian": "Platform Admin", "role": "admin", "active": True, "createdAt": created})

    # Teachers
    teacher_uids = []
    for t_i, (slug, name, cn) in enumerate(TEACHERS):
        email = f"{slug}@test.chinesetracker"
        uid = auth_user(email)
        teacher_uids.append(uid)
        put("users", uid, {"email": email, "name": name, "nameIndonesian": name,
            "nameChinese": cn, "role": "teacher", "active": True,
            "levels": TEACHER_LEVELS[t_i],
            "whatsapp": "+62812000000", "createdAt": created})

    # Students (student1..3 keep the live test emails; the rest are demo names)
    student_uids, student_names = [], []
    for i in range(30):
        first = FIRST[i]
        name = f"{first} {LAST[i % len(LAST)]}"
        email = f"student{i + 1}@test.chinesetracker"
        uid = auth_user(email)
        teacher = teacher_uids[i % len(teacher_uids)]
        level = LEVELS[i]
        term = 16 if i % 3 == 0 else 8
        student_uids.append(uid)
        student_names.append(name)
        put("users", uid, {"email": email, "name": name, "nameIndonesian": name,
            "nameChinese": CN[i % len(CN)], "role": "student", "active": i != 29,
            "teacherId": teacher, "level": level, "termSize": term,
            "parentName": f"Bapak {LAST[i % len(LAST)]}", "parentPhone": "+62813000000",
            "whatsapp": "+62814000000", "parentCode": f"PC{i + 1:02d}{first[:2].upper()}",
            "createdAt": created + dt.timedelta(days=i)})
        # One active term per student, a few nearly used up.
        used = random.choice([0, 2, 3, 5, term - 1]) if term == 8 else random.choice([0, 4, 9, 14])
        put("student_class_terms", f"term_{i + 1}", {
            "studentId": uid, "packageSize": term, "sessionsRemaining": term - used,
            "sessionsUsed": used, "status": "active",
            "startDate": ymd(-30), "deadlineDate": ymd(60),
            "voucherCode": f"2026_09_{i + 1:03d}", "createdBy": admin_uid,
            "createdAt": created})

    # Parent linked to student1
    parent_uid = auth_user("parent@test.chinesetracker")
    put("users", parent_uid, {"email": "parent@test.chinesetracker", "name": "Ibu Santoso",
        "nameIndonesian": "Ibu Santoso", "role": "parent", "active": True,
        "studentIds": [student_uids[0]], "teacherIds": [teacher_uids[0]],
        "createdAt": created})

    # Class sessions: this week and next, 3 per teacher, one concluded last week.
    sid = 0
    for t_idx, t_uid in enumerate(teacher_uids):
        for day_offset, start in [(-3, 15 * 60), (1, 16 * 60), (3, 10 * 60), (8, 16 * 60)]:
            sid += 1
            concluded = day_offset < 0
            doc = f"sess_{sid}"
            level = ["HSK 1", "HSK 2", "HSK 3", "HSK 4"][t_idx]
            put("class_sessions", doc, {
                "teacherId": t_uid, "sessionDate": ymd(day_offset),
                "sessionTitle": f"{level} · Kelas {'ABCD'[t_idx]}",
                "startMinutes": start, "endMinutes": start + 90, "capacity": 8,
                "isOpen": not concluded, "isConcluded": concluded,
                "registrationState": "closed" if concluded else "open",
                "room": ROOMS[sid % 3], "mode": "offline", "createdAt": created,
                **({"concludedAt": ts(day_offset, 17)} if concluded else {})})
            # Students of this teacher join
            mine = [u for k, u in enumerate(student_uids) if k % len(teacher_uids) == t_idx]
            for u in mine[:5]:
                put("attendance", f"{doc}_{u}", {
                    "sessionId": doc, "studentId": u, "teacherId": t_uid,
                    "sessionDate": ymd(day_offset), "sessionTitle": f"{level} · Kelas {'ABCD'[t_idx]}",
                    "startMinutes": start, "endMinutes": start + 90, "attended": True,
                    "joinedBy": "student", "studentName": student_names[student_uids.index(u)],
                    "sessionCredited": concluded, "joinedAt": ts(day_offset - 2)})

    # Lessons, exercises, assignments, results, grades for the first teacher
    t0 = teacher_uids[0]
    for n, (title, unit) in enumerate([("Greetings 问候", 1), ("Numbers 数字", 1), ("Family 家人", 2)]):
        put("lessons", f"lesson_{n + 1}", {"title": title, "unit": unit, "order": n + 1,
            "content": "Nǐ hǎo! 你好！ Selamat datang di pelajaran ini.", "teacherId": t0,
            "level": "HSK 1", "termNumber": 1})
        put("quizzes", f"quiz_{n + 1}", {"lessonId": f"lesson_{n + 1}", "title": f"Kuis: {title}",
            "teacherId": t0, "questions": [
                {"question": "“你好” artinya?", "options": ["Halo", "Terima kasih", "Maaf", "Selamat tinggal"], "correctIndex": 0},
                {"question": "Pinyin untuk 谢谢?", "options": ["xièxie", "zàijiàn", "qǐng", "duìbuqǐ"], "correctIndex": 0},
            ]})
    put("exercises", "ex_1", {"title": "HSK 1 Reading · Pilihan ganda", "instructions": "Pilih jawaban yang benar.",
        "teacherId": admin_uid, "order": 1, "type": "multiple_choice", "skillCategory": "reading",
        "level": "HSK 1", "termNumber": 1, "isPublished": True, "createdAt": created,
        "questions": [
            {"prompt": "我＿＿学生。", "options": ["是", "有", "在", "去"], "correctIndex": 0},
            {"prompt": "今天天气很＿＿。", "options": ["好", "坐", "吃", "喝"], "correctIndex": 0},
            {"prompt": "他＿＿中国人。", "options": ["不是", "没有", "不去", "没来"], "correctIndex": 0},
        ]})
    put("exercises", "ex_2", {"title": "HSK 1 组词成句", "instructions": "Susun kata menjadi kalimat.",
        "teacherId": admin_uid, "order": 2, "type": "compose_sentences", "skillCategory": "reading",
        "level": "HSK 1", "termNumber": 1, "isPublished": True, "createdAt": created,
        "questions": [{"prompt": "Susun:", "segments": ["我", "喜欢", "喝", "茶"]}]})
    for k, u in enumerate(student_uids[:6]):
        put("exercise_assignments", f"ex_1_{u}", {"exerciseId": "ex_1", "studentId": u,
            "teacherId": t0, "assignedAt": ts(-5), "dueDate": ts(2 if k < 4 else -1)})
        if k < 3:
            put("exercise_results", f"res_{k + 1}", {"studentId": u, "exerciseId": "ex_1",
                "score": [100, 67, 33][k], "submittedAt": ts(-2, 18)})
            put("quiz_results", f"qres_{k + 1}", {"studentId": u, "quizId": "quiz_1",
                "lessonId": "lesson_1", "score": [100, 50, 100][k], "submittedAt": ts(-3, 19)})
            put("student_progress", f"prog_{k + 1}", {"studentId": u, "lessonId": "lesson_1",
                "completed": True, "score": [100, 50, 100][k], "completedAt": ts(-3, 19)})
        put("grades", f"grade_{k + 1}", {"studentId": u, "teacherId": t0, "title": "Ulangan Bab 1",
            "category": "quiz", "status": "graded", "score": 70 + k * 5,
            "letterGrade": ["C", "C+", "B", "B+", "A", "A"][k], "gradedBy": t0,
            "createdAt": ts(-7), "gradedAt": ts(-6)})

    # Invoices: one pending, one paid, one expired
    for k, (status, u) in enumerate([("pending", student_uids[0]), ("paid", student_uids[1]), ("expired", student_uids[2])]):
        put("invoices", f"inv_{k + 1}", {"invoiceNumber": f"ES-INV-17920000{k}-DEMO", "studentId": u,
            "studentName": student_names[k], "teacherId": t0, "packageSize": 8, "amount": 2450000,
            "item": "package", "description": "8 class sessions", "priceItemId": "package8", "kind": "sessions",
            "sessions": 8, "paymentMethod": "midtrans",
            "currency": "IDR", "status": status, "dueDate": ymd(7), "midtransOrderId": f"ES-INV-17920000{k}-DEMO",
            "createdBy": admin_uid, "createdAt": ts(-10 - k),
            **({"paidAt": ts(-9)} if status == "paid" else {})})

    seed_tests(admin_uid, student_uids)
    seed_marking(admin_uid, teacher_uids[0], student_uids)
    seed_build3(admin_uid, teacher_uids)
    seed_build4(admin_uid, teacher_uids, student_uids, student_names)
    seed_build5(admin_uid, student_uids, student_names)
    seed_build6(admin_uid, teacher_uids, student_uids)
    seed_build9(admin_uid, student_uids, student_names)

    # Notifications and settings
    put("notifications", "n_1", {"kind": "registration", "title": "New student registered",
        "body": f"{student_names[29]} registered in Easy Study.", "forRole": "admin", "userId": "",
        "read": False, "createdAt": ts(-1, 10), "targetRoute": "/admin"})
    put("notifications", "n_2", {"kind": "grading", "title": "Practice submitted",
        "body": f"{student_names[0]} scored 100% on HSK 1 Reading.", "forRole": "teacher", "userId": t0,
        "read": False, "createdAt": ts(-2, 18), "targetRoute": "/teacher"})
    put("settings", "pricing", {
        "items": [
            {"id": "registration", "name": "Registration (one-time)", "nameChinese": "报名费", "price": 100000, "kind": "registration", "sessions": 0, "validDays": 0, "active": True},
            {"id": "package8", "name": "8 class sessions", "nameChinese": "8次课程", "price": 2450000, "kind": "sessions", "sessions": 8, "validDays": 60, "active": True},
            {"id": "package16", "name": "16 class sessions", "nameChinese": "16次课程", "price": 3950000, "kind": "sessions", "sessions": 16, "validDays": 60, "active": True},
            {"id": "book", "name": "HSK materials & book", "nameChinese": "HSK教材费", "price": 250000, "kind": "book", "sessions": 0, "validDays": 0, "active": True},
        ],
        "package8": 2450000, "package16": 3950000, "book": 250000, "registration": 100000,
        "termValidDays": 60, "updatedAt": ts(-20)})
    put("settings", "org", {"enablePayments": True, "allowTeacherReschedule": True,
        "evaluationFormsOpen": True, "requireEmailVerification": False,
        "autoGenerateStaffPasswords": False, "updatedAt": created, "updatedBy": admin_uid})
    put("audit_logs", "log_1", {"action": "invoice.paid", "actorId": "midtrans", "actorName": "Midtrans",
        "targetType": "invoice", "targetId": "inv_2", "detail": "Rp 800.000 · 8 sessions credited",
        "createdAt": ts(-9)})

    print("Seeded: 1 admin, 4 teachers, 30 students, 1 parent, terms, sessions, lessons, exercises, invoices.")
    print(f"Password for every account: {PASSWORD}")
    print("Logins: admin@ · teacher@ (and andrea@, budi@, clara@) · student1..30@ · parent@  (all @test.chinesetracker)")


# ---------------------------------------------------------------- Build 1
# Supervised tests: an HSK 3-style worksheet (all three skills, a recording,
# picture choices), the HSK 1-6 formats, one test code with short part
# clocks for the walk, and a practice and an exam package for the
# regression check. Media are generated here (no binaries in git) and
# written next to the emulator web bundle, served at /test_uploads/.
MEDIA_DIR = os.path.join(os.path.dirname(__file__), "..", "build", "web-emulator",
                         "test_uploads")
MEDIA_URL = "http://localhost:5181/test_uploads"
SHEET = "310901-KK"
TEST_CODE = "H3DEMO1"


def _wav(path, seconds=45, rate=8000):
    """A plain beep pattern: one tone per 'item', silence between."""
    import math
    import wave
    frames = bytearray()
    for i in range(seconds * rate):
        t = i / rate
        on = (t % 3) < 0.6
        freq = 440 + 110 * (int(t // 3) % 4)
        v = 128 + (int(60 * math.sin(2 * math.pi * freq * t)) if on else 0)
        frames.append(max(0, min(255, v)))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(1)
        w.setframerate(rate)
        w.writeframes(bytes(frames))


def _png(path, rgb, size=96):
    """A solid square PNG without PIL."""
    import struct
    import zlib
    row = b"\x00" + bytes(rgb) * size
    raw = row * size

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def seed_media():
    os.makedirs(MEDIA_DIR, exist_ok=True)
    _wav(os.path.join(MEDIA_DIR, "hsk3_listening.wav"))
    for name, rgb in [("red", (220, 70, 70)), ("green", (60, 170, 90)),
                      ("blue", (70, 110, 220))]:
        _png(os.path.join(MEDIA_DIR, f"pic_{name}.png"), rgb)


def bank_item(doc_id, index, skill, type_, question, section, owner, **extra):
    put("question_bank", doc_id, {
        "ownerId": owner, "type": type_, "prompt": question.get("prompt", ""),
        "question": question, "skillCategory": skill, "level": "HSK 3",
        "category": extra.pop("category", "hsk_simulation"),
        "tags": [extra.get("sheet", SHEET)], "sheetCode": extra.pop("sheet", SHEET),
        "sheetTitle": extra.pop("title", "HSK 3 · H3DEMO1 (seed)"), "sheetIndex": index,
        "section": section, "usageCount": 0, "createdBy": owner,
        "createdAt": ts(-4), **extra})


def seed_tests(admin_uid, student_uids):
    seed_media()
    rec = f"{MEDIA_URL}/hsk3_listening.wav"
    pics = [f"{MEDIA_URL}/pic_{c}.png" for c in ("red", "green", "blue")]
    L1 = "一、听力 · 第一部分 · 看图选择"
    L2 = "一、听力 · 第二部分"
    R1 = "二、阅读 · 选词填空"
    W1 = "三、书写"
    i = 0

    def nxt():
        nonlocal i
        i += 1
        return i
    # Listening: picture choices first, then text choices; one recording.
    for n, key in enumerate([0, 2]):
        bank_item(f"tq_l{n + 1}", nxt(), "listening", "multiple_choice",
                  {"prompt": f"第{n + 1}题：听录音，选择图片。", "options": ["A", "B", "C"],
                   "optionImageUrls": pics, "correctIndex": key,
                   "explanation": "录音里说的是这张图片。"},
                  L1, admin_uid, sectionAudioUrl=rec)
    for n, (q, opts, key) in enumerate([
            ("他们明天去哪儿？", ["图书馆", "医院", "火车站"], 0),
            ("女的想喝什么？", ["咖啡", "茶", "牛奶"], 1)]):
        bank_item(f"tq_l{n + 3}", nxt(), "listening", "multiple_choice",
                  {"prompt": q, "options": opts, "correctIndex": key,
                   "explanation": "听第二遍时注意关键词。"},
                  L2, admin_uid, sectionAudioUrl=rec)
    # Reading.
    for n, (q, opts, key) in enumerate([
            ("我（ ）喜欢喝茶。", ["很", "是", "的"], 0),
            ("这本书我已经看（ ）了。", ["完", "到", "着"], 0),
            ("他每天骑自行车（ ）学校。", ["去", "在", "从"], 0),
            ("今天比昨天（ ）。", ["冷", "冷了", "很冷"], 0)]):
        bank_item(f"tq_r{n + 1}", nxt(), "reading", "multiple_choice",
                  {"prompt": q, "options": opts, "correctIndex": key,
                   "explanation": "看句子的结构。"}, R1, admin_uid)
    # Writing: type the hanzi, and build a sentence.
    for n, (q, kw, acc) in enumerate([("我（ ）到家。", "gāng", ["刚"]),
                                      ("请（ ）一下。", "děng", ["等"])]):
        bank_item(f"tq_w{n + 1}", nxt(), "typing", "type_hanzi",
                  {"prompt": q, "keyword": kw, "options": acc}, W1, admin_uid)
    bank_item("tq_w3", nxt(), "typing", "compose_sentences",
              {"prompt": "", "segments": ["经理的", "办公室在", "二楼"]}, W1, admin_uid)

    # Formats HSK 1-6 (thesis scope). The rest come from "Load standard
    # formats" in the app, so loading twice can be walked.
    def part(skill, q, m):
        return {"skill": skill, "questions": q, "minutes": m, "maxScore": 100}
    hsk = {
        "1": [part("listening", 20, 18), part("reading", 20, 17)],
        "2": [part("listening", 35, 28), part("reading", 25, 22)],
        "3": [part("listening", 40, 40), part("reading", 30, 30), part("writing", 10, 15)],
        "4": [part("listening", 45, 35), part("reading", 40, 40), part("writing", 15, 25)],
        "5": [part("listening", 45, 35), part("reading", 45, 45), part("writing", 10, 40)],
        "6": [part("listening", 50, 40), part("reading", 50, 50), part("writing", 1, 45)],
    }
    for n, (key, parts) in enumerate(hsk.items()):
        put("test_formats", f"hsk-{key}", {
            "family": "hsk", "level": f"HSK {key}", "levelKey": key, "parts": parts,
            "passMark": 120 if len(parts) == 2 else 180, "provisional": False,
            "order": n + 1, "createdAt": ts(-4), "updatedAt": ts(-4)})

    # The walk's code: the seeded worksheet, HSK 3, short clocks (2 minutes
    # per part) so a part can be left to run out.
    put("test_codes", TEST_CODE, {
        "code": TEST_CODE, "family": "hsk", "level": "HSK 3", "levelKey": "3",
        "sheetKey": SHEET, "formatId": "hsk-3", "releaseYear": 2021,
        "format": {"parts": [part("listening", 4, 2), part("reading", 4, 2),
                             part("writing", 3, 2)], "passMark": 180},
        "active": True, "countsForPromotion": True, "createdBy": admin_uid,
        "createdAt": ts(-3)})

    # Regression: one practice package and one exam package from the bank.
    bank_item("pq_1", 1, "reading", "multiple_choice",
              {"prompt": "你好 artinya?", "options": ["Halo", "Terima kasih", "Maaf"],
               "correctIndex": 0}, "", admin_uid, sheet="310902-RDG",
              title="Latihan HSK 1 (seed)", category="exercise")
    bank_item("pq_2", 2, "reading", "multiple_choice",
              {"prompt": "谢谢 artinya?", "options": ["Maaf", "Terima kasih", "Halo"],
               "correctIndex": 1}, "", admin_uid, sheet="310902-RDG",
              title="Latihan HSK 1 (seed)", category="exercise")
    bank_item("eq_1", 1, "reading", "multiple_choice",
              {"prompt": "他是我（ ）朋友。", "options": ["的", "了", "吗"],
               "correctIndex": 0}, "", admin_uid, sheet="310903-RDG",
              title="Ujian HSK 1 (seed)", category="exam")
    bank_item("eq_2", 2, "reading", "multiple_choice",
              {"prompt": "你叫什么（ ）？", "options": ["名字", "朋友", "老师"],
               "correctIndex": 0}, "", admin_uid, sheet="310903-RDG",
              title="Ujian HSK 1 (seed)", category="exam")
    for ex_id, title, sheet, limit in [("pkg_practice", "Latihan HSK 1 (paket)", "310902-RDG", None),
                                       ("pkg_exam", "Ujian HSK 1 (paket)", "310903-RDG", 10)]:
        put("exercises", ex_id, {
            "title": title, "instructions": "Pilih jawaban yang benar.",
            "teacherId": admin_uid, "order": 3, "type": "multiple_choice",
            "skillCategory": "reading", "level": "HSK 1", "termNumber": 1,
            "isPublished": True, "createdAt": ts(-2), "bankSheets": [sheet],
            "bankQuestionIds": [], **({"timeLimitMinutes": limit} if limit else {})})
        for u in student_uids[:3]:
            put("exercise_assignments", f"{ex_id}_{u}", {
                "exerciseId": ex_id, "studentId": u, "teacherId": admin_uid,
                "assignedAt": ts(-1), "dueDate": ts(5)})
    print(f"Build 1: worksheet {SHEET}, formats HSK 1-6, test code {TEST_CODE}, "
          f"packages pkg_practice / pkg_exam, media in {os.path.abspath(MEDIA_DIR)}")


TYPING_SHEET = "310904-WRT"
ESSAY_SHEET = "310905-WRT"
ESSAY_CODE = "H3ESSAY"


def seed_marking(admin_uid, teacher_uid, student_uids):
    """Build 2A: a typing package (half credit goes to the teacher's queue)
    and a short test code with free writing (pending until marked)."""
    W = "三、书写"
    typing = dict(sheet=TYPING_SHEET, title="Mengetik HSK 3 (seed)", category="exercise")
    bank_item("ty_1", 1, "typing", "type_hanzi",
              {"prompt": "Ketik dengan hanzi: wǒ hěn xǐhuan hē chá",
               "keyword": "wǒ hěn xǐhuan hē chá", "options": ["我很喜欢喝茶"]},
              W, admin_uid, **typing)
    bank_item("ty_2", 2, "typing", "type_pinyin",
              {"prompt": "你好", "options": ["nǐ hǎo"]}, W, admin_uid, **typing)
    bank_item("ty_3", 3, "typing", "compose_sentences",
              {"prompt": "", "segments": ["把书", "放在", "桌子上"]}, W, admin_uid, **typing)
    put("exercises", "pkg_typing", {
        "title": "Mengetik HSK 3 (paket)", "instructions": "Ketik jawabannya.",
        "teacherId": teacher_uid, "order": 4, "type": "type_hanzi",
        "skillCategory": "typing", "level": "HSK 3", "termNumber": 1,
        "isPublished": True, "createdAt": ts(-2), "bankSheets": [TYPING_SHEET],
        "bankQuestionIds": []})
    for u in student_uids[:3]:
        put("exercise_assignments", f"pkg_typing_{u}", {
            "exerciseId": "pkg_typing", "studentId": u, "teacherId": teacher_uid,
            "assignedAt": ts(-1), "dueDate": ts(5)})

    essay = dict(sheet=ESSAY_SHEET, title="HSK 3 · H3ESSAY (seed)")
    bank_item("es_l1", 1, "listening", "multiple_choice",
              {"prompt": "他们明天去哪儿？", "options": ["图书馆", "医院", "火车站"],
               "correctIndex": 0}, "一、听力", admin_uid, **essay)
    bank_item("es_r1", 2, "reading", "multiple_choice",
              {"prompt": "我（ ）喜欢喝茶。", "options": ["很", "是", "的"],
               "correctIndex": 0}, "二、阅读", admin_uid, **essay)
    bank_item("es_w1", 3, "typing", "type_hanzi",
              {"prompt": "我（ ）到家。", "keyword": "gāng", "options": ["刚"]},
              W, admin_uid, **essay)
    bank_item("es_w2", 4, "typing", "essay",
              {"prompt": "用下面的词写一段话（80字左右）。", "keywords": ["周末", "公园"]},
              W, admin_uid, **essay)

    def part(skill, q, m):
        return {"skill": skill, "questions": q, "minutes": m, "maxScore": 100}
    put("test_codes", ESSAY_CODE, {
        "code": ESSAY_CODE, "family": "hsk", "level": "HSK 3", "levelKey": "3",
        "sheetKey": ESSAY_SHEET, "formatId": "hsk-3", "releaseYear": 2021,
        "format": {"parts": [part("listening", 1, 2), part("reading", 1, 2),
                             part("writing", 2, 5)], "passMark": 180},
        "active": True, "countsForPromotion": True, "createdBy": admin_uid,
        "createdAt": ts(-3)})
    print(f"Build 2A: package pkg_typing ({TYPING_SHEET}), test code {ESSAY_CODE} "
          f"({ESSAY_SHEET}) with free writing; emulator password {PASSWORD}")


# ---------------------------------------------------------------- Build 3
PLACE_SHEET = "310906-PLC"
PLACE_CODE = "H1PLACE"


def seed_build3(admin_uid, teacher_uids):
    """Build 3: two pending registrations (one with a visitor's placement
    result code), a short HSK 1 placement code, the rooms list."""
    put("settings", "rooms", {"names": ["Main", "Sub Room"], "updatedAt": ts(-1)})

    # A short HSK 1 paper: 3 listening + 3 reading, 2 minutes per part.
    place = dict(sheet=PLACE_SHEET, title="HSK 1 · Placement (seed)", level="HSK 1",
                 category="exam")
    for n, (q, opts, key) in enumerate([
            ("他是谁？", ["老师", "医生", "学生"], 0),
            ("他们在哪儿？", ["学校", "饭店", "商店"], 1),
            ("现在几点？", ["八点", "九点", "十点"], 2)]):
        bank_item(f"pl_l{n + 1}", n + 1, "listening", "multiple_choice",
                  {"prompt": q, "options": opts, "correctIndex": key}, "一、听力",
                  admin_uid, **place)
    for n, (q, opts, key) in enumerate([
            ("我（ ）中国人。", ["是", "有", "在"], 0),
            ("你叫什么（ ）？", ["朋友", "名字", "老师"], 1),
            ("我很（ ）茶。", ["喜欢", "学生", "今天"], 0)]):
        bank_item(f"pl_r{n + 1}", n + 4, "reading", "multiple_choice",
                  {"prompt": q, "options": opts, "correctIndex": key}, "二、阅读",
                  admin_uid, **place)

    def part(skill, q, m):
        return {"skill": skill, "questions": q, "minutes": m, "maxScore": 100}
    put("test_codes", PLACE_CODE, {
        "code": PLACE_CODE, "family": "hsk", "level": "HSK 1", "levelKey": "1",
        "sheetKey": PLACE_SHEET, "formatId": "hsk-1", "releaseYear": 2021,
        "format": {"parts": [part("listening", 3, 2), part("reading", 3, 2)], "passMark": 120},
        "active": True, "placement": True, "countsForPromotion": False,
        "createdBy": admin_uid, "createdAt": ts(-2)})

    # A visitor already sat a placement paper (HSK 3, passed → HSK 4).
    put("placement_results", "seed_visitor_1", {
        "name": "Rina Kusuma", "whatsapp": "+6281299990001", "codeId": "H3DEMO1",
        "code": "H3DEMO1", "level": "HSK 3", "levelKey": "3",
        "parts": [{"skill": "listening", "mark": 80, "maxScore": 100},
                  {"skill": "reading", "mark": 75, "maxScore": 100},
                  {"skill": "writing", "mark": 70, "maxScore": 100}],
        "total": 225, "max": 300, "passMark": 180, "passed": True,
        "recommendedLevel": "HSK 4", "resultCode": "RK4PLC", "sessionId": "seed",
        "openedBy": teacher_uids[0], "supervisorName": "Test Teacher",
        "finishedAt": ts(-1, 10), "claimedBy": "", "createdAt": ts(-1, 10)})

    # Two pending registrations.
    for email, name, cn, choice, target, code, teacher in [
            ("pending1@test.chinesetracker", "Doni Pratama", "", "hsk1", "", "", ""),
            ("pending2@test.chinesetracker", "Rina Kusuma", "林丽娜", "test", "HSK 4",
             "RK4PLC", teacher_uids[1])]:
        uid = auth_user(email)
        put("users", uid, {"email": email, "name": name, "nameIndonesian": name,
            "nameChinese": cn, "role": "student", "active": True, "status": "pending",
            "teacherId": teacher, "level": "", "termSize": 8, "whatsapp": "+6281299990002",
            "placementChoice": choice, "placementTarget": target,
            "placementResultCode": code, "createdAt": ts(0, 8)})
    print(f"Build 3: pending1@ / pending2@ waiting for approval, placement code "
          f"{PLACE_CODE} ({PLACE_SHEET}), visitor result code RK4PLC, settings/rooms")


# ---------------------------------------------------------------- Build 4
FN = "http://127.0.0.1:5001/chinese-tracker/us-central1"


def _exercise_result(doc_id, uid, days_ago, score, skills=None):
    skills = skills or {"reading": (round(score / 25), 4), "listening": (round(score / 50), 2)}
    put("exercise_results", doc_id, {
        "studentId": uid, "exerciseId": "pkg_practice", "exerciseTitle": "Latihan HSK 1 (paket)",
        "category": "exercise", "score": score, "status": "final", "scoredBy": "server",
        "correct": sum(c for c, _ in skills.values()), "total": sum(t for _, t in skills.values()),
        "bySkill": {k: {"correct": c, "total": t} for k, (c, t) in skills.items()},
        "submittedAt": ts(-days_ago, 11)})


def _attendance(doc_id, uid, teacher, days_ago, status):
    put("attendance", doc_id, {
        "sessionId": doc_id, "studentId": uid, "teacherId": teacher,
        "sessionDate": ymd(-days_ago), "sessionTitle": "Kelas (seed)",
        "startMinutes": 900, "endMinutes": 990, "attended": status == "hadir",
        "attendanceStatus": status, "joinedBy": "teacher", "sessionCredited": True,
        "joinedAt": ts(-days_ago, 8)})


def _test_result(code, uid, days_ago, total, chinese, latin, level="HSK 3"):
    put("test_results", f"{code}_{uid}", {
        "codeId": code, "code": code, "studentId": uid, "family": "hsk", "level": level,
        "levelKey": level[-1], "total": total, "max": 300, "passMark": 180,
        "passed": total >= 180, "valid": True, "status": "final", "studentName": latin,
        "studentNameChinese": chinese, "durationSeconds": 3000 + total,
        "finishedAt": ts(-days_ago, 10),
        "parts": [{"skill": "listening", "mark": total // 3, "maxScore": 100},
                  {"skill": "reading", "mark": total // 3, "maxScore": 100},
                  {"skill": "writing", "mark": total - 2 * (total // 3), "maxScore": 100}]})


def seed_build4(admin_uid, teacher_uids, student_uids, student_names):
    """Build 4: one healthy student (12 weeks of practice, 2 of 3 codes, a
    note) and five shaped for the five warnings; then every summary is
    rebuilt with the admin callable."""
    for c in ["PRG1", "PRG2", "PRG3", "PRG4"]:
        put("test_codes", c, {"code": c, "family": "hsk", "level": "HSK 3", "levelKey": "3",
            "countsForPromotion": True, "active": True, "sheetKey": "310901-KK",
            "format": {"parts": [], "passMark": 180}, "createdAt": ts(-30)})
    # student13 (index 12, HSK 3): healthy.
    ok, ok_name = student_uids[12], student_names[12]
    t_ok = teacher_uids[12 % len(teacher_uids)]
    for w in range(12):
        for k, score in enumerate([72 + w, 78 + w]):
            _exercise_result(f"prg_ok_{w}_{k}", ok, w * 7 + 1 + k * 2, min(score, 100))
    for d, st in [(2, "hadir"), (6, "hadir"), (9, "hadir"), (13, "izin"), (16, "hadir"), (20, "hadir")]:
        _attendance(f"prg_ok_att_{d}", ok, t_ok, d, st)
    put("student_class_terms", "term_13", {"studentId": ok, "packageSize": 16,
        "sessionsRemaining": 9, "sessionsUsed": 7, "status": "active",
        "startDate": ymd(-30), "deadlineDate": ymd(40), "voucherCode": "2026_09_013",
        "createdBy": admin_uid, "createdAt": ts(-30)})
    _test_result("PRG1", ok, 20, 230, CN[12 % len(CN)], ok_name)
    _test_result("PRG2", ok, 8, 215, CN[12 % len(CN)], ok_name)
    # Fourteen classmates on PRG2's board (the healthy student ranks among
    # them); students the flow test does not use.
    for n, j in enumerate([7, 10, 11] + list(range(18, 29))):
        _test_result("PRG2", student_uids[j], 9, 180 + n * 6, CN[j % len(CN)], student_names[j])
    put("progress_notes", "prg_note_ok", {"studentId": ok, "teacherId": t_ok,
        "teacherName": TEACHERS[12 % len(TEACHERS)][1],
        "text": "Rajin latihan menulis. Lanjutkan membaca teks pendek setiap hari.",
        "createdAt": ts(-2, 15)})

    # student14 (index 13): attendance under 75 % (2 present, 3 absent).
    a = student_uids[13]
    for d, st in [(2, "hadir"), (5, "alpa"), (9, "alpa"), (12, "hadir"), (16, "alpa")]:
        _attendance(f"prg_att_{d}", a, teacher_uids[13 % len(teacher_uids)], d, st)
    _exercise_result("prg_att_ex", a, 2, 80)
    # student15 (index 14): practice falling 15 points.
    f = student_uids[14]
    for i, (d, sc) in enumerate([(16, 90), (20, 85), (3, 72), (6, 68)]):
        _exercise_result(f"prg_fall_{i}", f, d, sc)
    # student16 (index 15): no practice for 20 days.
    _exercise_result("prg_idle", student_uids[15], 20, 85)
    put("student_class_terms", "term_16", {"studentId": student_uids[15], "packageSize": 8,
        "sessionsRemaining": 6, "sessionsUsed": 2, "status": "active",
        "startDate": ymd(-20), "deadlineDate": ymd(40), "voucherCode": "2026_09_016",
        "createdBy": admin_uid, "createdAt": ts(-20)})
    # student17 (index 16, HSK 3): two tests failed in a row.
    t = student_uids[16]
    _exercise_result("prg_fail_ex", t, 1, 75)
    _test_result("PRG3", t, 10, 150, CN[16 % len(CN)], student_names[16])
    _test_result("PRG4", t, 4, 170, CN[16 % len(CN)], student_names[16])
    # student18 (index 17): voucher with 1 session left.
    v = student_uids[17]
    _exercise_result("prg_voucher_ex", v, 1, 88)
    put("student_class_terms", "term_18", {"studentId": v, "packageSize": 8,
        "sessionsRemaining": 1, "sessionsUsed": 7, "status": "active",
        "startDate": ymd(-40), "deadlineDate": ymd(20), "voucherCode": "2026_09_018",
        "createdBy": admin_uid, "createdAt": ts(-40)})

    # Rebuild every summary through the admin callable (the triggers ran on
    # each write too, in any order).
    token = _req(f"{AUTH}/accounts:signInWithPassword?key=fake",
                 body={"email": "admin@test.chinesetracker", "password": PASSWORD,
                       "returnSecureToken": True})["idToken"]
    try:
        out = _req(f"{FN}/rebuildProgressSummaries", body={"data": {}},
                   headers={"Authorization": f"Bearer {token}"})
        print(f"Build 4: summaries rebuilt {out.get('result')}")
    except SystemExit as e:
        print(f"Build 4: rebuild skipped (functions emulator?): {e}")
    print("Build 4: healthy student13@, warnings: student14@ attendance, student15@ "
          "falling scores, student16@ inactive, student17@ two failed tests, "
          "student18@ voucher 1 left")


# ---------------------------------------------------------------- Build 5
def seed_build5(admin_uid, student_uids, student_names):
    """Build 5: an expired voucher waiting for the expiry job, one with 2
    sessions left, and a paid in-app purchase with its ledger entry."""
    put("student_class_terms", "term_past_deadline", {"studentId": student_uids[19],
        "packageSize": 8, "sessionsRemaining": 3, "sessionsUsed": 5, "status": "active",
        "startDate": ymd(-70), "deadlineDate": ymd(-3), "nameChinese": "8次课程",
        "validDays": 60, "voucherCode": "2026_08_020", "createdBy": admin_uid,
        "createdAt": ts(-70)})
    put("student_class_terms", "term_two_left", {"studentId": student_uids[20],
        "packageSize": 8, "sessionsRemaining": 2, "sessionsUsed": 6, "status": "active",
        "startDate": ymd(-30), "deadlineDate": ymd(30), "nameChinese": "8次课程",
        "validDays": 60, "voucherCode": "2026_09_021", "createdBy": admin_uid,
        "createdAt": ts(-30)})
    uid, name = student_uids[21], student_names[21]
    put("invoices", "inv_app_paid", {"invoiceNumber": "ES-INV-17920099-APP", "studentId": uid,
        "studentName": name, "teacherId": "", "item": "package", "description": "16 class sessions",
        "packageSize": 16, "priceItemId": "package16", "kind": "sessions", "sessions": 16,
        "nameChinese": "16次课程", "validDays": 60, "amount": 3950000, "currency": "IDR",
        "status": "paid", "paymentMethod": "midtrans", "midtransOrderId": "ES-INV-17920099-APP",
        "selfPurchase": True, "acceptedTerms": True, "termsVersion": "2026-10-flyer",
        "createdByRole": "student", "dueDate": ymd(7), "createdBy": uid,
        "createdAt": ts(-5), "paidAt": ts(-5, 10)})
    put("student_class_terms", "term_app_paid", {"studentId": uid, "packageSize": 16,
        "sessionsRemaining": 16, "sessionsUsed": 0, "sessionsBooked": 0, "status": "active",
        "startDate": ymd(-5), "deadlineDate": ymd(55), "nameChinese": "16次课程",
        "validDays": 60, "priceItemId": "package16", "source": "app",
        "sourceInvoiceId": "inv_app_paid", "createdBy": "midtrans", "createdAt": ts(-5, 10)})
    put("voucher_history", "inv_app_paid_purchase", {"kind": "purchase", "studentId": uid,
        "termId": "term_app_paid", "invoiceId": "inv_app_paid", "sessions": 16,
        "nameChinese": "16次课程", "amount": 3950000, "method": "midtrans", "date": ts(-5, 10)})
    print("Build 5: price list with Chinese names, a past-deadline voucher (student20@), "
          "2 sessions left (student21@), a paid in-app purchase (student22@)")


# ---------------------------------------------------------------- Build 6
def seed_build6(admin_uid, teacher_uids, student_uids):
    """Build 6: the flyer's timetable across the four teachers and two
    rooms, each teacher's availability, one day off, class days on two
    vouchers; then the generation job runs once."""
    # Owner 2026-11-23: back-to-back classes are fine (no gap by default).
    put("settings", "scheduling", {"minGapMinutes": 0, "weeklyHoursWarning": 20,
        "defaultCapacity": 8, "minStudents": 3, "minStudentsHours": 3,
        "teacherReadiness": False})
    # Availability: weekday afternoons and Saturday daytime for everyone.
    avail = {str(d): [{"startMinutes": 840, "endMinutes": 1140}] for d in (1, 2, 3, 5)}
    avail["6"] = [{"startMinutes": 570, "endMinutes": 900}]
    for uid in teacher_uids:
        _req(f"{FS}/users/{uid}?updateMask.fieldPaths=availability", method="PATCH",
             body={"fields": {"availability": fv(avail)}},
             headers={"Authorization": "Bearer owner"})
    # The flyer: Monday 16:00; Tue, Wed, Fri 15:00 and 16:30; Sat 10:00, 11:30, 13:00.
    slots = [(1, 960, "Main")]
    for d in (2, 3, 5):
        slots += [(d, 900, "Main"), (d, 990, "Sub Room")]
    slots += [(6, 600, "Main"), (6, 690, "Sub Room"), (6, 780, "Main")]
    names = ["Teacher", "Andrea Natasha", "Budi Santoso", "Clara Wijaya"]
    ids = []
    for i, (day, start, room) in enumerate(slots):
        t = i % len(teacher_uids)
        sid = f"sch_{i + 1:02d}"
        ids.append(sid)
        put("schedules", sid, {"className": f"Kelas {'ABCDEFGHIJK'[i]}", "weekday": day,
            "startMinutes": start, "endMinutes": start + 90, "room": room,
            "teacherId": teacher_uids[t], "teacherName": names[t], "capacity": 8,
            "level": "", "validFrom": ymd(-7), "validTo": ymd(120), "active": True,
            "status": "unconfirmed", "createdBy": admin_uid, "createdAt": ts(-7)})
    put("teacher_days_off", "off_1", {"teacherId": teacher_uids[1], "date": ymd(8),
        "reason": "Family event", "createdAt": ts(-1)})
    # Class days: student23's and student24's vouchers.
    for n, (idx, sid) in enumerate([(22, ids[0]), (23, ids[1])]):
        put("student_class_terms", f"term_class_day_{n}", {"studentId": student_uids[idx],
            "packageSize": 8, "sessionsRemaining": 8, "sessionsUsed": 0, "sessionsBooked": 0,
            "status": "active", "startDate": ymd(-2), "deadlineDate": ymd(58),
            "nameChinese": "8次课程", "classDay": sid, "createdBy": admin_uid,
            "createdAt": ts(-2)})
    try:
        _req("http://127.0.0.1:5001/chinese-tracker/us-central1/generateSessions-0", body={})
        print(f"Build 6: {len(ids)} schedules, availability, a day off, class days; "
              "sessions generated for 14 days")
    except SystemExit as e:
        print(f"Build 6: generation skipped: {e}")



# ---------------------------------------------------------------- Build 9
# Enough rows to see page 2: 70 audit entries (most this month), and a
# board of 28 students on code H3BOARD (written by onTestResultWritten
# with its rankKey). Ties on purpose: equal total and seconds share a rank.
BOARD_CODE = "H3BOARD"


def seed_build9(admin_uid, student_uids, student_names):
    actions = ["invoice.created", "invoice.paid", "test.session.open", "test.session.close",
               "promotion.approve", "registration.approve", "schedule.create", "day.close"]
    for i in range(70):
        days = -(i % 40) if i < 60 else -(45 + i)
        put("audit_logs", f"b9_log_{i:02d}", {
            "action": actions[i % len(actions)], "actorId": admin_uid, "actorName": "Admin Seed",
            "targetType": "seed", "targetId": f"t{i}", "detail": f"Seed entry {i + 1}",
            "createdAt": ts(days, 8 + i % 10)})
    put("test_codes", BOARD_CODE, {
        "code": BOARD_CODE, "family": "hsk", "level": "HSK 3", "levelKey": "3",
        "sheetKey": SHEET, "formatId": "hsk-3", "releaseYear": 2021, "active": True,
        "countsForPromotion": False, "createdBy": admin_uid, "createdAt": ts(-12)})
    # Students 13-18 are shaped for the progress warnings (Build 4) and
    # stay off this board; four rows without an account fill it to 28.
    people = [(uid, student_names[i] if i < len(student_names) else f"Student {i + 1}")
              for i, uid in enumerate(student_uids) if not 12 <= i <= 17]
    people += [(f"board_guest_{k}", f"Guest {k}") for k in range(1, 5)]
    n = min(28, len(people))
    for i in range(n):
        total = 290 - (i // 2) * 9          # pairs share a total
        uid, latin = people[i]
        put("test_results", f"{BOARD_CODE}_{uid}", {
            "codeId": BOARD_CODE, "code": BOARD_CODE, "studentId": uid,
            "family": "hsk", "level": "HSK 3", "levelKey": "3", "total": total, "max": 300,
            "passMark": 180, "passed": total >= 180, "valid": True, "status": "final",
            "studentName": latin, "studentNameChinese": f"学生{i + 1}",
            "durationSeconds": 3000 + (i // 2) * 10, "finishedAt": ts(-10 + i % 5, 9 + i % 8),
            "parts": [{"skill": "listening", "mark": total // 3, "maxScore": 100},
                      {"skill": "reading", "mark": total // 3, "maxScore": 100},
                      {"skill": "writing", "mark": total - 2 * (total // 3), "maxScore": 100}]})
    # Session 2: 40 invoices this month, so Payments has a page 2.
    for i in range(40):
        uid = student_uids[i % len(student_uids)]
        status = ["paid", "pending", "paid", "expired"][i % 4]
        put("invoices", f"b9_inv_{i:02d}", {
            "studentId": uid, "studentName": student_names[i % len(student_names)],
            "invoiceNumber": f"INV-B9-{i + 1:03d}", "amount": 2450000 if i % 2 else 3950000,
            "packageSize": 8 if i % 2 else 16, "priceItemId": "package8" if i % 2 else "package16",
            "itemLabel": "8次课程" if i % 2 else "16次课程", "status": status,
            "dueDate": ymd(7), "createdAt": ts(-(i % 20), 9 + i % 8),
            **({"paidAt": ts(-(i % 20), 12), "paymentMethod": "transfer"} if status == "paid" else {})})
    # And 30 open answers in the marking queue (page 2 for the admin).
    for i in range(30):
        uid = student_uids[i % len(student_uids)]
        put("marking_items", f"b9_mark_{i:02d}", {
            "source": "package", "resultId": f"b9_res_{i:02d}", "title": "Seed package",
            "studentId": uid, "studentName": student_names[i % len(student_names)],
            "questionId": f"q{i}", "type": "essay", "prompt": "写一句话。",
            "answerText": "我喜欢学习中文。", "characterCount": 8, "reason": "free_writing",
            "machinePoints": 0, "maxPoints": 10, "status": "open",
            "teacherIds": [admin_uid], "createdAt": ts(-(i % 25), 10)})
    print(f"Build 9: 70 audit entries, board {BOARD_CODE} with {n} results, 40 invoices, 30 marking items")


if __name__ == "__main__":
    main()
