# Chaos Runner Docker Image

## Overview

This container runs a full Harness Chaos experiment lifecycle:

1. Triggers a Chaos experiment
2. Monitors it until completion
3. Prints the final result as JSON
4. Exits with a success or failure code based on status and resiliency score

- **Exit 0**: Status is `Completed` and (if configured) resiliency score meets or exceeds your threshold  
- **Exit 1**: Any other status or resiliency score is below the threshold

The last line of the container's output will always be the final JSON object returned by the experiment monitor.

---

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `HCE_ACCOUNT_ID` | Harness account ID |
| `HCE_ORG_ID` | Harness org ID |
| `HCE_PROJECT_ID` | Harness project ID |
| `HCE_WORKFLOW_ID` | Chaos workflow (experiment) ID |
| `HCE_API_KEY` | API key with permissions to run experiments |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `HCE_BASE_URL` | `https://app.harness.io` | Base URL for Harness API |
| `EXPECTED_RESILIENCY_SCORE` | *(unset)* | Integer (1–100). If set, the container exits 1 if the experiment's resiliency score is below this value |
| `HCE_CLI` | `hce_cli_api` | Override the CLI binary name/path inside the container |

---

## Run the Container

### Basic Run

```bash
docker run --rm \
  -e HCE_ACCOUNT_ID="$HCE_ACCOUNT_ID" \
  -e HCE_ORG_ID="$HCE_ORG_ID" \
  -e HCE_PROJECT_ID="$HCE_PROJECT_ID" \
  -e HCE_WORKFLOW_ID="$HCE_WORKFLOW_ID" \
  -e HCE_API_KEY="$HCE_API_KEY" \
  pkg.harness.io/eerjnxtns4grlg5vnnjzuw/hce-cli/chaos-runner:v3
