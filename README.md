# Github_workflow_run_id_tracking

A playground for testing and experimenting with GitHub Actions workflows.

This example shows a way to track the `run_id` of a GitHub Actions workflow for use in subsequent workflows.

## Setup

Set your GITHUB_TOKEN to a GitHub Personal Access Token with `workflow` and `repo` scopes.

```bash
export GITHUB_TOKEN=<YOUR_PAT_HERE>
```

## Usage / Demoing

Run the `testing.sh` script to trigger the workflow and track the `run_id`.

```bash
./testing.sh
```
