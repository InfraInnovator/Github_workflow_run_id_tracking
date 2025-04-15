#!/bin/bash

# Ensure GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN environment variable is not set."
  exit 1
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq (e.g., 'sudo apt-get install jq' or 'brew install jq')."
    exit 1
fi

# Ensure uuidgen is installed
if ! command -v uuidgen &> /dev/null; then
    echo "Error: uuidgen is not installed. Please install it first.')."
    exit 1
fi

# Get the actor (username) associated with the token
echo "Fetching GitHub username for the provided token..."
actor_login=$(curl -s -L \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user | jq -r '.login')

if [ -z "$actor_login" ] || [ "$actor_login" = "null" ]; then
  echo "Error: Could not fetch username for the provided GITHUB_TOKEN."
  exit 1
fi
echo "Using actor: $actor_login"

OWNER="InfraInnovator"
REPO="Github_workflow_run_id_tracking"
WORKFLOW_FILE="workflow-testing.yaml"
REF="main"
MY_BUILD_VERSION="1.2.3" # Or get this from script arguments: MY_BUILD_VERSION="$1"

# Generate a unique ID for this trigger
trigger_id=$(uuidgen)
echo "Generated unique trigger ID: $trigger_id"

echo "Triggering workflow $WORKFLOW_FILE on ref $REF with trigger ID $trigger_id..."

# Record time just before triggering
start_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Trigger the workflow dispatch including the trigger_id
trigger_response_code=$(curl -s -L -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -o /dev/null \
  -w "%{http_code}" \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches" \
  -d "{\"ref\": \"${REF}\",\"inputs\": {\"MY_BUILD_VERSION_to_build\": \"${MY_BUILD_VERSION}\", \"trigger_id\": \"${trigger_id}\"}}")

if [ "$trigger_response_code" -ne 204 ]; then
  echo "Error: Failed to trigger workflow. HTTP status code: $trigger_response_code"
  exit 1
fi

echo "Workflow triggered successfully. Polling for run ID with trigger ID $trigger_id..."

# Polling configuration
POLL_INTERVAL=10 # seconds
MAX_ATTEMPTS=12 # Total wait time = POLL_INTERVAL * MAX_ATTEMPTS (e.g., 120 seconds)
attempt=0
run_id=""

while [ -z "$run_id" ] && [ $attempt -lt $MAX_ATTEMPTS ]; do
  attempt=$((attempt + 1))
  echo "Polling attempt $attempt/$MAX_ATTEMPTS..."

  # List recent workflow runs, filtering by actor, event, branch. Fetch a few recent ones.
  # Use jq to find the run where the name contains our trigger_id.
  run_id=$(curl -s -L \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_FILE}/runs?actor=${actor_login}&event=workflow_dispatch&branch=${REF}&per_page=10" | \
    jq --arg tid "$trigger_id" '.workflow_runs[] | select(.name | contains($tid)) | .id' | head -n 1) # head -n 1 just in case jq finds multiple somehow

  if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
    run_id="" # Ensure run_id is empty if jq returned null or empty string
    if [ $attempt -lt $MAX_ATTEMPTS ]; then
      echo "Run not found yet. Waiting ${POLL_INTERVAL} seconds..."
      sleep $POLL_INTERVAL
    fi
  else
    echo "Found Workflow Run ID: $run_id"
    break # Exit loop once found
  fi
done

if [ -z "$run_id" ]; then
  echo "Error: Could not find workflow run with trigger ID $trigger_id after $MAX_ATTEMPTS attempts."
  exit 1
fi
