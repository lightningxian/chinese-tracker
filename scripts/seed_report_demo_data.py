#!/usr/bin/env python3
"""Seed Firestore demo data so teacher/admin reports show meaningful numbers.

Prerequisites:
  ./scripts/seed_test_accounts.sh

Password for all accounts: testpass123
"""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

API_KEY = "AIzaSyAJySwXYdNO1GUdz_KsVdPd0ODvkf7wLbw"
PROJECT = "chinese-tracker"
PASSWORD = "testpass123"
ADMIN_EMAIL = "admin@test.chinesetracker"
TEACHER_EMAIL = "teacher@test.chinesetracker"
STUDENT_EMAILS = [
    "student1@test.chinesetracker",
    "student2@test.chinesetracker",
    "student3@test.chinesetracker",
]


def http_json(url: str, data: dict | None = None, headers: dict | None = None) -> dict:
    body = None if data is None else json.dumps(data).encode()
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json", **(headers or {})},
        method="GET" if data is None else "POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def sign_in(email: str) -> dict:
    return http_json(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}",
        {"email": email, "password": PASSWORD, "returnSecureToken": True},
    )


def firestore_url(path: str) -> str:
    return f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/{path}"


def fs_get(token: str, path: str) -> dict | None:
    req = urllib.request.Request(
        firestore_url(path),
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def fs_create_doc(token: str, collection: str, doc_id: str, fields: dict) -> None:
    url = f"{firestore_url(collection)}?documentId={doc_id}"
    data = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        if e.code == 409:
            # Already seeded — update in place.
            fs_set(token, f"{collection}/{doc_id}", fields)
            return
        raise


def fs_set(token: str, path: str, fields: dict) -> None:
    data = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(
        firestore_url(path),
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="PATCH",
    )
    urllib.request.urlopen(req)


def fs_post(token: str, collection: str, fields: dict) -> str:
    data = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(
        firestore_url(collection),
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read().decode())
    return result["name"].split("/")[-1]


def s(value: str) -> dict:
    return {"stringValue": value}


def i(value: int) -> dict:
    return {"integerValue": str(value)}


def b(value: bool) -> dict:
    return {"booleanValue": value}


def ts(dt: datetime) -> dict:
    return {"timestampValue": dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}


def list_lessons(token: str) -> list[tuple[str, dict]]:
    req = urllib.request.Request(
        f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/lessons",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(req) as resp:
        payload = json.loads(resp.read().decode())
    rows = []
    for item in payload.get("documents", []):
        doc_id = item["name"].split("/")[-1]
        fields = item.get("fields", {})
        rows.append((doc_id, fields))
    return rows


def list_exercises(token: str) -> list[tuple[str, dict]]:
    req = urllib.request.Request(
        f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/exercises",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(req) as resp:
        payload = json.loads(resp.read().decode())
    rows = []
    for item in payload.get("documents", []):
        doc_id = item["name"].split("/")[-1]
        fields = item.get("fields", {})
        rows.append((doc_id, fields))
    return rows


def ensure_lessons(token: str, teacher_id: str) -> list[str]:
    existing = list_lessons(token)
    hsk1 = [
        (lid, f)
        for lid, f in existing
        if f.get("level", {}).get("stringValue") == "HSK 1"
        and f.get("teacherId", {}).get("stringValue") == teacher_id
    ]
    if len(hsk1) >= 2:
        return [lid for lid, _ in hsk1[:3]]

    lesson_ids = []
    specs = [
        ("Greetings", 1, "你好 — Hello\n谢谢 — Thank you"),
        ("Numbers", 2, "一 二 三 — basic numbers"),
        ("Family", 3, "爸爸 妈妈 — family words"),
    ]
    for title, order, content in specs:
        doc_id = fs_post(
            token,
            "lessons",
            {
                "title": s(title),
                "unit": s("Term 1 — Basics"),
                "termNumber": i(1),
                "order": i(order),
                "teacherId": s(teacher_id),
                "level": s("HSK 1"),
                "content": s(content),
                "audioUrl": s(""),
            },
        )
        lesson_ids.append(doc_id)
        print(f"  Created lesson: {title} ({doc_id})")
    return lesson_ids


def ensure_exercise(token: str, teacher_id: str) -> str:
    existing = list_exercises(token)
    published = [
        (eid, f)
        for eid, f in existing
        if f.get("isPublished", {}).get("booleanValue", True)
        and f.get("teacherId", {}).get("stringValue") == teacher_id
    ]
    if published:
        return published[0][0]

    doc_id = fs_post(
        token,
        "exercises",
        {
            "title": s("HSK 1 Practice — Greetings"),
            "instructions": s("Choose the correct answer."),
            "teacherId": s(teacher_id),
            "order": i(1),
            "type": s("multipleChoice"),
            "level": s("HSK 1"),
            "termNumber": i(1),
            "isPublished": b(True),
            "questions": {
                "arrayValue": {
                    "values": [
                        {
                            "mapValue": {
                                "fields": {
                                    "prompt": s("Hello in Chinese is ___"),
                                    "options": {
                                        "arrayValue": {
                                            "values": [
                                                s("你好"),
                                                s("谢谢"),
                                                s("再见"),
                                            ]
                                        }
                                    },
                                    "correctIndex": i(0),
                                }
                            }
                        }
                    ]
                }
            },
        },
    )
    print(f"  Created exercise: HSK 1 Practice ({doc_id})")
    return doc_id


def ensure_link_code(token: str, teacher_id: str) -> str:
    """Stable demo link code so register-with-code is demoable."""
    code = "DEMO01"
    expires = datetime.now(timezone.utc) + timedelta(hours=24)
    fields = {
        "teacherId": s(teacher_id),
        "expiresAt": ts(expires),
        "createdAt": ts(datetime.now(timezone.utc)),
    }
    fs_set(token, f"teacher_link_codes/{code}", fields)
    fs_set(
        token,
        f"teacher_link_state/{teacher_id}",
        {
            "code": s(code),
            "expiresAt": ts(expires),
            "updatedAt": ts(datetime.now(timezone.utc)),
        },
    )
    print(f"  Link code: {code} (valid ~24h)")
    return code


def ensure_open_session(token: str, teacher_id: str) -> str:
    """One open class session for the join-live-class demo."""
    today = datetime.now().strftime("%Y-%m-%d")
    doc_id = fs_post(
        token,
        "class_sessions",
        {
            "teacherId": s(teacher_id),
            "sessionDate": s(today),
            "sessionTitle": s("Demo Live Class"),
            "startMinutes": i(9 * 60),
            "endMinutes": i(10 * 60),
            "capacity": i(20),
            "isOpen": b(True),
            "isConcluded": b(False),
            "createdAt": ts(datetime.now(timezone.utc)),
        },
    )
    print(f"  Open class session: Demo Live Class ({doc_id})")
    return doc_id


def assign_homework(
    token: str,
    teacher_id: str,
    exercise_id: str,
    student_id: str,
    *,
    due_days: int | None,
    assigned_days_ago: int,
) -> None:
    fields = {
        "exerciseId": s(exercise_id),
        "studentId": s(student_id),
        "teacherId": s(teacher_id),
        "assignedAt": ts(datetime.now() - timedelta(days=assigned_days_ago)),
    }
    if due_days is not None:
        due = datetime.now() + timedelta(days=due_days)
        fields["dueDate"] = ts(
            due.replace(hour=23, minute=59, second=59, microsecond=0)
        )
    fs_create_doc(
        token,
        "exercise_assignments",
        f"{exercise_id}_{student_id}",
        fields,
    )


def save_result(
    token: str,
    student_id: str,
    exercise_id: str,
    score: int,
    days_ago: int,
) -> None:
    fs_post(
        token,
        "exercise_results",
        {
            "studentId": s(student_id),
            "exerciseId": s(exercise_id),
            "score": i(score),
            "submittedAt": ts(datetime.now() - timedelta(days=days_ago)),
        },
    )


def mark_lesson(
    token: str,
    student_id: str,
    lesson_id: str,
    score: int,
    days_ago: int,
) -> None:
    fs_post(
        token,
        "student_progress",
        {
            "studentId": s(student_id),
            "lessonId": s(lesson_id),
            "completed": b(True),
            "score": i(score),
            "completedAt": ts(datetime.now() - timedelta(days=days_ago)),
        },
    )


def create_term(
    token: str,
    teacher_id: str,
    student_id: str,
    *,
    package_size: int,
    remaining: int,
) -> None:
    start = datetime.now() - timedelta(days=30)
    end = datetime.now() + timedelta(days=60)
    used = package_size - remaining
    # Rules require create with sessionsRemaining == packageSize; then update.
    doc_id = fs_post(
        token,
        "student_class_terms",
        {
            "studentId": s(student_id),
            "packageSize": i(package_size),
            "sessionsRemaining": i(package_size),
            "sessionsUsed": i(0),
            "status": s("active"),
            "startDate": s(start.strftime("%Y-%m-%d")),
            "deadlineDate": s(end.strftime("%Y-%m-%d")),
            "createdBy": s(teacher_id),
            "purchasedAt": ts(datetime.now() - timedelta(days=30)),
            "createdAt": ts(datetime.now() - timedelta(days=30)),
        },
    )
    if remaining != package_size:
        fs_set(
            token,
            f"student_class_terms/{doc_id}",
            {
                "studentId": s(student_id),
                "packageSize": i(package_size),
                "sessionsRemaining": i(remaining),
                "sessionsUsed": i(used),
                "status": s("active" if remaining > 0 else "depleted"),
                "startDate": s(start.strftime("%Y-%m-%d")),
                "deadlineDate": s(end.strftime("%Y-%m-%d")),
                "createdBy": s(teacher_id),
                "purchasedAt": ts(datetime.now() - timedelta(days=30)),
                "createdAt": ts(datetime.now() - timedelta(days=30)),
            },
        )



def main() -> int:
    print("Signing in as Centre Admin...")
    admin = sign_in(ADMIN_EMAIL)
    admin_token = admin["idToken"]

    print("Signing in as Teacher (content owner)...")
    teacher = sign_in(TEACHER_EMAIL)
    teacher_id = teacher["localId"]
    teacher_token = teacher["idToken"]

    student_ids: dict[str, str] = {}
    for email in STUDENT_EMAILS:
        auth = sign_in(email)
        student_ids[email] = auth["localId"]
        print(f"  Student: {email} ({auth['localId']})")

    print("Ensuring lessons and exercises...")
    lesson_ids = ensure_lessons(teacher_token, teacher_id)
    exercise_id = ensure_exercise(teacher_token, teacher_id)

    print("Ensuring demo link code + open class session...")
    link_code = ensure_link_code(teacher_token, teacher_id)
    ensure_open_session(teacher_token, teacher_id)

    s1 = student_ids[STUDENT_EMAILS[0]]
    s2 = student_ids[STUDENT_EMAILS[1]]
    s3 = student_ids[STUDENT_EMAILS[2]]

    print("Seeding student 1 — active, good progress...")
    s1_token = sign_in(STUDENT_EMAILS[0])["idToken"]
    if lesson_ids:
        mark_lesson(s1_token, s1, lesson_ids[0], 88, days_ago=1)
    if len(lesson_ids) > 1:
        mark_lesson(s1_token, s1, lesson_ids[1], 92, days_ago=3)
    assign_homework(
        admin_token, teacher_id, exercise_id, s1,
        due_days=7, assigned_days_ago=5,
    )
    save_result(s1_token, s1, exercise_id, 85, days_ago=2)
    create_term(admin_token, teacher_id, s1, package_size=8, remaining=5)

    print("Seeding student 2 — overdue homework, low sessions...")
    s2_token = sign_in(STUDENT_EMAILS[1])["idToken"]
    if lesson_ids:
        mark_lesson(s2_token, s2, lesson_ids[0], 76, days_ago=10)
    assign_homework(
        admin_token, teacher_id, exercise_id, s2,
        due_days=-3, assigned_days_ago=14,
    )
    create_term(admin_token, teacher_id, s2, package_size=8, remaining=1)

    print("Seeding student 3 — mostly inactive...")
    assign_homework(
        admin_token, teacher_id, exercise_id, s3,
        due_days=14, assigned_days_ago=2,
    )
    create_term(admin_token, teacher_id, s3, package_size=8, remaining=6)

    print("")
    print("Done. Sign in at /dev-login (debug) or /login as:")
    print("  Guru  — teacher@test.chinesetracker")
    print("  Murid — student1@test.chinesetracker")
    print("  Admin — admin@test.chinesetracker")
    print("Password: testpass123")
    print(f"Register with link code: {link_code}")
    print("")
    print("No CONTENT_OWNER_ID needed — content is owned by the demo teacher uid:")
    print(f"  {teacher_id}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        raise SystemExit(1)
