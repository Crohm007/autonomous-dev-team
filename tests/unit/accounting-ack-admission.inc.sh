echo "== acknowledged historical unknown admission =="
IA=500
AK="$(accounting_invocation_id RUNACKADMIT dev dev 1)"
AU="$(accounting_invocation_id RUNACKADMIT dev dev 2)"
accounting_start "$IA" "$AK" dev RUNACKADMIT dev 1 >/dev/null
accounting_commit_usage "$IA" "$AK" 50 >/dev/null
accounting_start "$IA" "$AU" dev RUNACKADMIT dev 2 >/dev/null
accounting_commit_unknown "$IA" "$AU" historical-gap >/dev/null
QB="$(accounting_admission_query "$IA")"
DB="$(jq -r .source_digest <<<"$QB")"
assert_eq "TC-RESOURCEACCOUNT-081 unacknowledged unknown blocks" usage-unknown "$(jq -r .status <<<"$QB")"
accounting_ack_unknown "$IA" "$AU" >/dev/null
QA="$(accounting_admission_query "$IA")"
assert_eq "TC-RESOURCEACCOUNT-081 ack admits" complete "$(jq -r .status <<<"$QA")"
assert_eq "TC-RESOURCEACCOUNT-081 total remains known numeric only" 50 "$(jq -r .total_tokens <<<"$QA")"
assert_eq "TC-RESOURCEACCOUNT-081 no blocking unknown" 0 "$(jq -r '.unknown_invocations|length' <<<"$QA")"
assert_eq "TC-RESOURCEACCOUNT-081 acked id reported" "$AU" "$(jq -r '.acknowledged_unknown_invocations[0]' <<<"$QA")"
assert_eq "TC-RESOURCEACCOUNT-081 underlying record preserved" usage-unknown "$(jq -r .state "$(_accounting_issue_dir "$IA")/${AU}.json")"
assert_ne "TC-RESOURCEACCOUNT-081 ack changes digest" "$DB" "$(jq -r .source_digest <<<"$QA")"
D1="$(jq -r .source_digest <<<"$QA")"
accounting_ack_unknown "$IA" "$AU" >/dev/null
QD="$(accounting_admission_query "$IA")"
assert_eq "TC-RESOURCEACCOUNT-082 duplicate ack digest-idempotent" "$D1" "$(jq -r .source_digest <<<"$QD")"
assert_eq "TC-RESOURCEACCOUNT-082 one effective ack" 1 "$(jq -r '.acknowledged_unknown_invocations|length' <<<"$QD")"
AL="$(accounting_invocation_id RUNACKADMIT dev dev 3)"
accounting_start "$IA" "$AL" dev RUNACKADMIT dev 3 >/dev/null
accounting_commit_unknown "$IA" "$AL" future-gap >/dev/null
QL="$(accounting_admission_query "$IA")"
assert_eq "TC-RESOURCEACCOUNT-083 later unknown reblocks" usage-unknown "$(jq -r .status <<<"$QL")"
assert_eq "TC-RESOURCEACCOUNT-083 later unknown blocks" "$AL" "$(jq -r '.unknown_invocations[0]' <<<"$QL")"
IM=501
AM="$(accounting_invocation_id RUNACKBAD dev dev 1)"
accounting_start "$IM" "$AM" dev RUNACKBAD dev 1 >/dev/null
accounting_commit_unknown "$IM" "$AM" gap >/dev/null
printf 'not-json\n' > "$(_accounting_issue_dir "$IM")/acks.jsonl"
assert_eq "TC-RESOURCEACCOUNT-084 malformed audit corrupt" corrupt "$(accounting_admission_query "$IM" | jq -r .status)"
ID=502
AD="$(accounting_invocation_id RUNACKDANGLE dev dev 1)"
AX="$(accounting_invocation_id RUNACKDANGLE dev dev 2)"
accounting_start "$ID" "$AD" dev RUNACKDANGLE dev 1 >/dev/null
accounting_commit_unknown "$ID" "$AD" gap >/dev/null
jq -nc --argjson sv "$ACCOUNTING_SCHEMA_VERSION" --arg id "$AX" --argjson issue "$ID" '{schema_version:$sv,invocation_id:$id,issue:$issue,ts:"x",event:"ack-unknown"}' > "$(_accounting_issue_dir "$ID")/acks.jsonl"
assert_eq "TC-RESOURCEACCOUNT-085 dangling ack corrupt" corrupt "$(accounting_admission_query "$ID" | jq -r .status)"
IN=503
AN="$(accounting_invocation_id RUNACKNONREG dev dev 1)"
accounting_start "$IN" "$AN" dev RUNACKNONREG dev 1 >/dev/null
accounting_commit_unknown "$IN" "$AN" gap >/dev/null
mkdir "$(_accounting_issue_dir "$IN")/acks.jsonl"
assert_eq "TC-RESOURCEACCOUNT-086 nonregular audit corrupt" corrupt "$(accounting_admission_query "$IN" | jq -r .status)"
