# Github_workflow_run_id_tracking

A playground for testing and experimenting with GitHub Actions workflows.

This example shows a way to identidy the correct run ID when you may run multiple jobs in parallel, and you want to track the run ID of a specific job.

## Prerequisites

- A GitHub repository with a workflow that you want to test.
- A GitHub Personal Access Token (PAT) with `workflow` and `repo` scopes to trigger workflows and access run details.

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
