# GCP Deployment

This project deploys to Google Cloud Run with two services:

- Production: `main` branch -> `parish-simulator`
- Testing: `testing` branch -> `parish-simulator-testing`

Cloud Run provides the free public `run.app` URL after each service is first deployed.

## One-Time GCP Setup

Replace `YOUR_PROJECT_ID` with your Google Cloud project ID.

```bash
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
gcloud artifacts repositories create parish-simulator --repository-format=docker --location=us-central1
```

Cloud Build needs permission to deploy Cloud Run services and write images. In the Google Cloud console, grant the Cloud Build service account these roles:

- Cloud Run Admin
- Artifact Registry Writer
- Service Account User

## Create Cloud Build Triggers

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

## Version Links

After the first deploy, Cloud Run will show each service URL.

Update both Cloud Build triggers with:

- `_PRODUCTION_URL=<production run.app URL>`
- `_TESTING_URL=<testing run.app URL>`

Then run both triggers again. The app's first screen will let players choose Production or Testing.

## Notes

- `--max-instances=1` is intentional for now because live game state is stored in memory.
- If the game later needs multiple instances, add shared state such as Redis or a real game-state service.
- WebSocket connections on Cloud Run are still subject to request timeouts, so clients should expect reconnects.
