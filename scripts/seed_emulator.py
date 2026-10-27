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
import random
import sys
import urllib.error
import urllib.request

PROJECT = "chinese-tracker"
AUTH = "http://localhost:9099/identitytoolkit.googleapis.com/v1"
FS = f"http://localhost:8080/v1/projects/{PROJECT}/databases/(default)/documents"
PASSWORD = "testpass123"
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
ROOMS = ["Ruang 1", "Ruang 2", "Ruang 3"]


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
    for slug, name, cn in TEACHERS:
        email = f"{slug}@test.chinesetracker"
        uid = auth_user(email)
        teacher_uids.append(uid)
        put("users", uid, {"email": email, "name": name, "nameIndonesian": name,
            "nameChinese": cn, "role": "teacher", "active": True,
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
            "currency": "IDR", "status": status, "dueDate": ymd(7), "midtransOrderId": f"ES-INV-17920000{k}-DEMO",
            "createdBy": admin_uid, "createdAt": ts(-10 - k),
            **({"paidAt": ts(-9)} if status == "paid" else {})})

    # Notifications and settings
    put("notifications", "n_1", {"kind": "registration", "title": "New student registered",
        "body": f"{student_names[29]} registered in Easy Study.", "forRole": "admin", "userId": "",
        "read": False, "createdAt": ts(-1, 10), "targetRoute": "/admin"})
    put("notifications", "n_2", {"kind": "grading", "title": "Practice submitted",
        "body": f"{student_names[0]} scored 100% on HSK 1 Reading.", "forRole": "teacher", "userId": t0,
        "read": False, "createdAt": ts(-2, 18), "targetRoute": "/teacher"})
    put("settings", "pricing", {"package8": 2450000, "package16": 3950000, "book": 250000,
        "registration": 100000, "termValidDays": 60, "updatedAt": created, "updatedBy": admin_uid})
    put("settings", "org", {"enablePayments": True, "allowTeacherReschedule": True,
        "evaluationFormsOpen": True, "requireEmailVerification": False,
        "autoGenerateStaffPasswords": False, "updatedAt": created, "updatedBy": admin_uid})
    put("audit_logs", "log_1", {"action": "invoice.paid", "actorId": "midtrans", "actorName": "Midtrans",
        "targetType": "invoice", "targetId": "inv_2", "detail": "Rp 800.000 · 8 sessions credited",
        "createdAt": ts(-9)})

    print("Seeded: 1 admin, 4 teachers, 30 students, 1 parent, terms, sessions, lessons, exercises, invoices.")
    print(f"Password for every account: {PASSWORD}")
    print("Logins: admin@ · teacher@ (and andrea@, budi@, clara@) · student1..30@ · parent@  (all @test.chinesetracker)")


if __name__ == "__main__":
    main()
