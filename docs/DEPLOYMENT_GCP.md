# GCP Deployment

The current infrastructure deploys the Node WebSocket/static server to Google Cloud Run.

Branch gates:

- Local: feature branch and local machine only.
- Testing: push or merge to `testing`.
- Production: push or merge to `main`.

Do not move to testing or production until explicitly deciding to do so.

## Services

- Production: `main` branch -> `parish-simulator`
- Testing: `testing` branch -> `parish-simulator-testing`

The Node service serves files from `web-export/` and exposes the WebSocket endpoint at `/ws`.

## Before Deploying

1. Run the Godot project locally.
2. Run the Node server locally.
3. Export the Godot Web build into `web-export/`.
4. Run `npm run typecheck`.
5. Run `npm run start` and test `http://localhost:3000`.
6. Commit the Godot project and the updated web export.

## One-Time GCP Setup

Replace `YOUR_PROJECT_ID` with your Google Cloud project ID.

```bash
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
gcloud artifacts repositories create parish-simulator --repository-format=docker --location=us-central1
```

Cloud Build needs:

- Cloud Run Admin
- Artifact Registry Writer
- Service Account User

## Cloud Build Triggers

Create two GitHub push triggers for `rupertt/Parish-Simulator`.

### Production Trigger

- Event: Push to branch
- Branch: `^main$`
- Build config file: `cloudbuild.yaml`
- Substitutions:
  - `_SERVICE_NAME=parish-simulator`
  - `_APP_ENV=production`
  - `_REGION=us-central1`
  - `_ARTIFACT_REPOSITORY=parish-simulator`

### Testing Trigger

- Event: Push to branch
- Branch: `^testing$`
- Build config file: `cloudbuild.yaml`
- Substitutions:
  - `_SERVICE_NAME=parish-simulator-testing`
  - `_APP_ENV=testing`
  - `_REGION=us-central1`
  - `_ARTIFACT_REPOSITORY=parish-simulator`

## Runtime Notes

- `--max-instances=1` is still intentional because shared-world state is in memory.
- Multiple instances require shared world state such as Redis or a dedicated game-state service.
- Cloud Run WebSockets can be interrupted by request timeouts; clients should reconnect in a later iteration.
- Production pages served over HTTPS must use `wss://` for WebSocket connections.
