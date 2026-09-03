#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/skills/autonomous-dispatcher/scripts/lib-metrics.sh"
source "$ROOT/skills/autonomous-dispatcher/scripts/adapters/codex.sh"
pass=0 fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1" >&2; fail=$((fail+1)); }
assert_eq() { local name="$1" exp="$2" got="$3"; [[ "$got" == "$exp" ]] && ok "$name" || bad "$name expected=[$exp] got=[$got]"; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

f="$tmp/codex.jsonl"
cat >"$f" <<EOF
{"type":"thread.started","thread_id":"abc"}
{"type":"turn.completed","usage":{"input_tokens":10,"output_tokens":1}}
{"type":"thread.started","thread_id":"def"}
{"type":"turn.completed","usage":{"input_tokens":20,"output_tokens":2}}
EOF
assert_eq 'codex reruns aggregate every terminal usage record' 'input_tokens=30 output_tokens=3 total_tokens=33' "$(metrics_parse_tokens "$f")"

cat >"$f" <<EOF
{"type":"turn.completed","usage":{"input_tokens":10,"output_tokens":1}}
{"type":"turn.completed","usage":{"input_tokens":20}}
EOF
assert_eq 'malformed codex terminal usage fails closed' '' "$(metrics_parse_tokens "$f")"

cat >"$f" <<EOF
{"type":"turn.completed"}
EOF
assert_eq 'missing codex terminal usage fails closed' '' "$(metrics_parse_tokens "$f")"

cat >"$f" <<EOF
{"usage":{"input_tokens":5,"output_tokens":1}}
{"usage":{"input_tokens":7,"output_tokens":2}}
EOF
assert_eq 'non-codex structured compatibility keeps last usage' 'input_tokens=7 output_tokens=2 total_tokens=9' "$(metrics_parse_tokens "$f")"

printf 'noise\ntokens used: 42\n' >"$f"
assert_eq 'legacy codex text fallback remains compatible' 'total_tokens=42' "$(metrics_parse_tokens "$f")"

AGENT_DEV_EXTRA_ARGS=''
argv=()
_codex_review_argv argv $'review\nprompt' 'gpt-test' '/tmp/final-review.txt'
joined=$(printf '<%s>' "${argv[@]}")
assert_eq 'review argv has structured and final-message channels' '<review><--json><--output-last-message></tmp/final-review.txt><review
prompt><-c><model="gpt-test">' "$joined"

printf '%s passed, %s failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
