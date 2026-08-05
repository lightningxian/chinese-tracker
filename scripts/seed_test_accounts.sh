#!/usr/bin/env bash
# Seeds Firebase Auth + Firestore profiles for test login buttons.
# Password for all accounts: testpass123

set -euo pipefail

API_KEY="AIzaSyAJySwXYdNO1GUdz_KsVdPd0ODvkf7wLbw"
PASS="testpass123"
PROJECT="chinese-tracker"

sign_up() {
  curl -s "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASS\",\"returnSecureToken\":true}"
}

sign_in() {
  curl -s "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASS\",\"returnSecureToken\":true}"
}

ensure_auth_user() {
  local email="$1"
  local result
  result=$(sign_in "$email")
  if echo "$result" | grep -q '"idToken"'; then
    echo "$result"
    return
  fi
  sign_up "$email"
}

create_profile() {
  local token="$1" doc_id="$2" name="$3" role="$4" teacher_id="$5" level="$6" term="$7" email="$8" created_at="$9"
  local fields="\"name\":{\"stringValue\":\"$name\"},\"email\":{\"stringValue\":\"$email\"},\"role\":{\"stringValue\":\"$role\"},\"active\":{\"booleanValue\":true}"
  if [ -n "$teacher_id" ]; then fields="$fields,\"teacherId\":{\"stringValue\":\"$teacher_id\"}"; fi
  if [ -n "$level" ]; then fields="$fields,\"level\":{\"stringValue\":\"$level\"}"; fi
  if [ -n "$term" ]; then fields="$fields,\"termSize\":{\"integerValue\":\"$term\"}"; fi
  if [ -n "$created_at" ]; then fields="$fields,\"createdAt\":{\"timestampValue\":\"$created_at\"}"; fi

  curl -s -X PATCH \
    "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/users/$doc_id" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{\"fields\":{$fields}}" >/dev/null
}

echo "Seeding test accounts (password: $PASS)..."

TEACHER_JSON=$(ensure_auth_user "teacher@test.chinesetracker")
TEACHER_ID=$(echo "$TEACHER_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['localId'])")
TEACHER_TOKEN=$(echo "$TEACHER_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['idToken'])")
create_profile "$TEACHER_TOKEN" "$TEACHER_ID" "Test Teacher" "teacher" "" "" "" "teacher@test.chinesetracker" "2024-08-02T00:00:00Z"
echo "Teacher: teacher@test.chinesetracker ($TEACHER_ID)"

ADMIN_JSON=$(ensure_auth_user "admin@test.chinesetracker")
ADMIN_ID=$(echo "$ADMIN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['localId'])")
ADMIN_TOKEN=$(echo "$ADMIN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['idToken'])")
create_profile "$ADMIN_TOKEN" "$ADMIN_ID" "Platform Admin" "admin" "" "" "" "admin@test.chinesetracker" "2024-08-01T00:00:00Z"
echo "Admin (platform): admin@test.chinesetracker ($ADMIN_ID)"

for i in 1 2 3; do
  EMAIL="student${i}@test.chinesetracker"
  JSON=$(ensure_auth_user "$EMAIL")
  DOC_ID=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['localId'])")
  TOKEN=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['idToken'])")
  create_profile "$TOKEN" "$DOC_ID" "Test Student $i" "student" "$TEACHER_ID" "HSK 1" "8" "$EMAIL" "2024-11-0${i}T00:00:00Z"
  echo "Student $i: $EMAIL ($DOC_ID)"
done

echo ""
echo "Optional: seed sample data for reports:"
echo "  python3 scripts/seed_report_demo_data.py"
echo "Done."
