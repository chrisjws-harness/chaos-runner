#!/usr/bin/env bash
set -euo pipefail

# Required
: "${HCE_ACCOUNT_ID:?set HCE_ACCOUNT_ID}"
: "${HCE_ORG_ID:?set HCE_ORG_ID}"
: "${HCE_PROJECT_ID:?set HCE_PROJECT_ID}"
: "${HCE_WORKFLOW_ID:?set HCE_WORKFLOW_ID}"
: "${HCE_API_KEY:?set HCE_API_KEY}"

# Optional
HCE_CLI="${HCE_CLI:-hce_cli_api}"
HCE_BASE_URL="${HCE_BASE_URL:-https://app.harness.io}"
EXPECTED_RESILIENCY_SCORE="${EXPECTED_RESILIENCY_SCORE:-}"

# Validate expected score if provided (1..100)
if [[ -n "$EXPECTED_RESILIENCY_SCORE" ]]; then
  if ! [[ "$EXPECTED_RESILIENCY_SCORE" =~ ^[0-9]+$ ]] || (( EXPECTED_RESILIENCY_SCORE < 1 || EXPECTED_RESILIENCY_SCORE > 100 )); then
    echo "Invalid EXPECTED_RESILIENCY_SCORE. Use an integer 1..100." >&2
    exit 1
  fi
fi

# 1) Kick off and capture notifyID (parse stdout only)
RUN_OUT_JSON=$(
  "$HCE_CLI" experiment run \
    --account-id "$HCE_ACCOUNT_ID" \
    --org-id "$HCE_ORG_ID" \
    --project-id "$HCE_PROJECT_ID" \
    --experiment-id "$HCE_WORKFLOW_ID" \
    --base-url "$HCE_BASE_URL" \
    -x "$HCE_API_KEY" \
    --color=false -n=false -o json \
  | tee /tmp/run.out \
  | jq -s 'map(select(type=="object")) | last'
)
NOTIFY_ID=$(printf '%s' "$RUN_OUT_JSON" | jq -r 'try .notifyID // ""')
if [[ -z "$NOTIFY_ID" ]]; then
  echo "Failed to get notifyID. See /tmp/run.out" >&2
  exit 1
fi

# 2) Monitor; keep only the last JSON object from stdout stream
MONITOR_OUT=$(
  "$HCE_CLI" experiment monitor \
    --notify-id "$NOTIFY_ID" \
    --account-id "$HCE_ACCOUNT_ID" \
    --org-id "$HCE_ORG_ID" \
    --project-id "$HCE_PROJECT_ID" \
    --base-url "$HCE_BASE_URL" \
    -x "$HCE_API_KEY" \
    --color=false -n=false -o json \
  | tee /tmp/monitor.out \
  | jq -s 'map(select(type=="object")) | last'
)
if [[ -z "$MONITOR_OUT" || "$MONITOR_OUT" = "null" ]]; then
  echo "No valid final JSON returned from monitor. See /tmp/monitor.out" >&2
  exit 1
fi

# 3) Exit policy
FINAL_STATUS=$(printf '%s' "$MONITOR_OUT" | jq -r '.status // empty')
RESILIENCY_SCORE_RAW=$(printf '%s' "$MONITOR_OUT" | jq -r '.resiliencyScore // "-1"')

RC=0
case "$FINAL_STATUS" in
  Completed) RC=0 ;;
  Completed_With_Probe_Failure|Completed_With_Probe_Absent|Stopped) RC=1 ;;
  *) RC=1 ;;
esac

if [[ -n "$EXPECTED_RESILIENCY_SCORE" ]]; then
  if ! [[ "$RESILIENCY_SCORE_RAW" =~ ^-?[0-9]+$ ]]; then
    RC=1
  else
    (( RESILIENCY_SCORE_RAW < EXPECTED_RESILIENCY_SCORE )) && RC=1 || true
  fi
fi

# 4) Print final JSON as the last line and exit accordingly
printf '%s\n' "$MONITOR_OUT"
exit "$RC"
