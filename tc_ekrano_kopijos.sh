#!/usr/bin/env bash
# Paleidžia kiekvieną Jira TC atskirai, kad būtų galima padaryti ekrano kopiją.
#
#   ./tc_ekrano_kopijos.sh             visi TC iš eilės
#   ./tc_ekrano_kopijos.sh SCRUM-145   tik vienas TC
#   ./tc_ekrano_kopijos.sh FAIL        tik tie, kurie turi būti FAIL

cd "$(dirname "$0")" || exit 1

# Jira raktas | TC | laukiamas rezultatas | testų pavadinimų šablonas (regex)
CASES=(
  "SCRUM-144|TC-US67-01|PASS|TC-US67-01"
  "SCRUM-145|TC-US67-02|FAIL|TC-US67-02"
  "SCRUM-146|TC-US67-03|PASS|TC-US67-03"
  "SCRUM-147|TC-US67-04|PASS|TC-US67-04"
  "SCRUM-148|TC-US67-05|PASS|TC-US67-05"
  "SCRUM-151|TC-FEAT49-01|PASS|TC-FEAT49-01"
  "SCRUM-152|TC-FEAT49-02|PASS|TC-FEAT49-02"
  "SCRUM-153|TC-FEAT49-03|PASS|TC-FEAT49-03"
  "SCRUM-154|TC-FEAT49-04|PASS|TC-FEAT49-04"
  "SCRUM-155|TC-FEAT49-05|PASS|TC-FEAT49-05"
  "SCRUM-156|TC-FEAT49-06|PASS|TC-FEAT49-06"
  "SCRUM-157|TC-FEAT49-07|PASS|TC-FEAT49-07"
  "SCRUM-158|TC-FEAT49-08|PASS|TC-FEAT49-08"
  "SCRUM-159|TC-FEAT49-09|FAIL|TC-FEAT49-09"
  "SCRUM-160|TC-FEAT49-10|FAIL|TC-FEAT49-10"
  "TC-FEAT49-13|TC-FEAT49-13 (naujas)|PASS|TC-FEAT49-13"
  "SCRUM-104|TC-US39-01|FAIL|TC-US39-01"
  "SCRUM-105|TC-US39-02|FAIL|TC-US39-02"
  "SCRUM-106|TC-US39-03|PASS|TC-US39-03"
  "SCRUM-107|TC-US39-04|PASS|TC-US39-04"
  "SCRUM-108|TC-US39-05|PASS|TC-US39-05"
  "SCRUM-109|TC-US39-06|PASS|TC-US39-06"
  "SCRUM-111|TC-US39-08|PASS|TC-US39-08"
  "TC-US39-10|TC-US39-10 (naujas)|FAIL|TC-US39-10"
  "SCRUM-113|TC-FEAT48-01|PASS|TC-FEAT48-01"
  "SCRUM-114|TC-FEAT48-02|PASS|TC-FEAT48-02"
  "SCRUM-115|TC-FEAT48-03|PASS|TC-FEAT48-03"
  "SCRUM-116|TC-FEAT48-04|PASS|TC-FEAT48-04"
  "SCRUM-117|TC-FEAT48-05|PASS|TC-FEAT48-05"
  "SCRUM-118|TC-FEAT48-06|PASS|TC-FEAT48-06"
  "SCRUM-119|TC-FEAT48-07|PASS|A and B 10 plays each"
  "SCRUM-120|TC-FEAT48-08|PASS|TC-FEAT48-08"
  "TC-FEAT48-10|TC-FEAT48-10 (naujas)|FAIL|TC-FEAT48-10"
  "TC-FEAT48-11|TC-FEAT48-11 (naujas)|PASS|TC-FEAT48-11"
)

filter="$1"
for entry in "${CASES[@]}"; do
  key="${entry%%|*}";   rest="${entry#*|}"
  tc="${rest%%|*}";     rest="${rest#*|}"
  expected="${rest%%|*}"; pattern="${rest#*|}"

  if [[ -n "$filter" && "$filter" != "$key" && "$filter" != "$expected" ]]; then
    continue
  fi

  clear
  echo "════════════════════════════════════════════════════════════════════"
  echo " $key — $tc — laukiamas automatinio testo rezultatas: $expected"
  echo "════════════════════════════════════════════════════════════════════"
  echo "\$ flutter test test/tests/ --reporter expanded --name \"$pattern\""
  echo
  flutter test test/tests/ --reporter expanded --name "$pattern" 2>&1 \
    | sed "s#$(pwd)/##g" \
    | grep -v "^To run this test again\|HttpClient\|TestWidgetsFlutterBinding\|will actually be made\|To test code that needs\|so that your test can"
  echo
  read -r -p "Padarykite ekrano kopiją ($key) ir paspauskite Enter... " _
done
