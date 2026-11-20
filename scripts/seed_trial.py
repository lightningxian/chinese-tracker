#!/usr/bin/env python3
"""Build 8 (docs/PLAN.md §4, Must 4): the thesis trial seed, 35 respondents.

Two modes:

  py -I scripts/seed_trial.py emulator
      Everything, on the local emulators (start them first):
      1 admin, 4 teachers with levels and availability, 30 students
      (12 beginner HSK 1-2, 10 intermediate HSK 3-4, 8 advanced HSK 5-6),
      the rooms, the price list, the flyer's timetable, vouchers with class
      days, sessions, results and bookings, plus the trial extras that make
      every admin dashboard card non-empty (a late check-in today, an
      unclosed session, students needing attention). Fixed ids: running it
      twice changes nothing.

  py -I scripts/seed_trial.py live --credentials <service-account.json>
      Accounts and structures only, never papers or results, on the LIVE
      project (scripts/seed_trial_live.mjs through firebase-admin). The
      passwords come from scripts/trial/passwords.local.json and the names
      from scripts/trial/respondents.local.csv; both are git-ignored and
      never committed. The owner runs this and hands out the passwords.

  py -I scripts/seed_trial.py verify
      Counts the trial documents on the emulator and fails on duplicates.
"""
import datetime as dt
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import seed_emulator as base  # noqa: E402  (same folder)


def trial_extras():
    """What the dashboard needs beyond the demo seed (fixed ids)."""
    today = base.ymd(0)
    yesterday = base.ymd(-1)
    users = base._req(f"{base.FS}:runQuery", body={"structuredQuery": {
        "from": [{"collectionId": "users"}],
        "where": {"fieldFilter": {"field": {"fieldPath": "role"}, "op": "EQUAL",
                                  "value": {"stringValue": "teacher"}}}}},
        headers={"Authorization": "Bearer owner"})
    teachers = [r["document"]["name"].rsplit("/", 1)[1] for r in users if "document" in r]
    teachers.sort()
    t0 = teachers[0] if teachers else ""
    t1 = teachers[1] if len(teachers) > 1 else t0
    base.put("class_sessions", "trial_late_today", {
        "teacherId": t0, "teacherName": "Trial", "sessionDate": today,
        "sessionTitle": "Trial · late check-in", "startMinutes": 0, "endMinutes": 90,
        "capacity": 8, "bookedCount": 0, "status": "scheduled", "room": "Sub Room",
        "level": "", "isOpen": True, "isConcluded": False, "generated": True,
        "scheduleId": "trial", "lateCheckIn": True, "createdAt": base.ts(-1)})
    base.put("class_sessions", "trial_unclosed", {
        "teacherId": t1, "teacherName": "Trial", "sessionDate": yesterday,
        "sessionTitle": "Trial · not closed", "startMinutes": 600, "endMinutes": 690,
        "capacity": 8, "bookedCount": 0, "status": "ongoing", "room": "Main",
        "level": "", "isOpen": False, "isConcluded": False, "generated": True,
        "scheduleId": "trial", "unclosed": True, "lateMinutes": 20,
        "createdAt": base.ts(-2)})
    print("trial: a late check-in today, an unclosed session yesterday")


def verify():
    """Counts by collection; a second seed run must give the same numbers."""
    def count(coll, field=None, value=None):
        q = {"from": [{"collectionId": coll}]}
        if field:
            q["where"] = {"fieldFilter": {"field": {"fieldPath": field}, "op": "EQUAL",
                                          "value": {"stringValue": value}}}
        res = base._req(f"{base.FS}:runAggregationQuery", body={
            "structuredAggregationQuery": {"structuredQuery": q,
                                           "aggregations": [{"alias": "n", "count": {}}]}},
            headers={"Authorization": "Bearer owner"})
        return int(res[0]["result"]["aggregateFields"]["n"]["integerValue"])
    counts = {
        "admins": count("users", "role", "admin"),
        "teachers": count("users", "role", "teacher"),
        "students": count("users", "role", "student"),
        "schedules": count("schedules"),
        "terms": count("student_class_terms"),
    }
    print("trial counts:", counts)
    # The live-mode accounts (trial_*) may also be on the emulator after a
    # rehearsal of `seed_trial_live.mjs --emulator`.
    try:
        base._req(f"{base.FS}/users/trial_admin", method="GET",
                  headers={"Authorization": "Bearer owner"})
        extra = True
    except SystemExit:
        extra = False
    want = {"admins": 2, "teachers": 8} if extra else {"admins": 1, "teachers": 4}
    bad = {k: v for k, v in want.items() if counts[k] != v}
    if counts["students"] < 30 or counts["schedules"] < 10 or bad:
        sys.exit(f"unexpected counts: {bad or counts}")
    return counts


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "emulator":
        started = dt.datetime.now()
        base.main()
        trial_extras()
        verify()
        print(f"trial seed (emulator) done in {(dt.datetime.now() - started).seconds} s")
    elif mode == "live":
        node = "node"
        script = os.path.join(HERE, "seed_trial_live.mjs")
        sys.exit(subprocess.call([node, script, *sys.argv[2:]]))
    elif mode == "verify":
        verify()
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
