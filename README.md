# IdeaBoard AI — AI-First, Cloud-Agnostic DevOps Platform

A beginner-friendly reference implementation for the supplied DevOps case study. It contains a React idea board, FastAPI REST API, PostgreSQL, Docker Compose, Kubernetes manifests, Terraform starting configurations for AWS and GCP, and GitHub Actions CI/CD with optional AI-assisted log analysis.

> **Important reality check:** The local application is runnable. Cloud infrastructure creation and public deployment require your own AWS/GCP accounts, billing setup, permissions, credentials, and a configured Kubernetes database connection. No cloud resources or public URLs are created by downloading this repository. Read the cloud deployment section before applying Terraform; cloud resources can incur charges.

## 1. Architecture

```text
Browser
  |
  v
React UI (Nginx container, port 3000)
  |  /api/* proxy
  v
FastAPI REST API (port 8000)
  |
  v
PostgreSQL (port 5432, private Docker network)

GitHub push / pull request
  -> GitHub Actions: Python syntax check + React production build
  -> Docker image builds + Trivy filesystem scan
  -> Optional AI advisory log analysis

Manual GitHub Actions deployment
  -> Build and publish images to GHCR
  -> Apply Kubernetes manifests to selected cluster
  -> Wait for rollout + optional AI analysis of deployment events

Terraform: AWS (EKS + RDS) OR GCP (GKE + Cloud SQL)
```

## 2. Technology choices

- Frontend: React 18, Vite, CSS, served by Nginx.
- Backend: Python 3.12, FastAPI, SQLAlchemy.
- Database: PostgreSQL 16.
- Containers: Docker and Docker Compose.
- Orchestration: Kubernetes.
- IaC: Terraform with separate AWS and GCP roots. The application/Kubernetes layer is shared; provider-specific network, cluster, and managed-database resources remain in provider folders.
- CI/CD: GitHub Actions and GitHub Container Registry (GHCR).
- AI: optional OpenAI API call for a human-readable advisory analysis of CI/deployment logs. AI does not execute commands or trigger rollback.

## 3. Run locally (recommended first milestone)

### Install

1. Install **Docker Desktop** for Windows and start it. Wait until Docker Desktop says it is running.
2. Install **Git**.
3. Install **Visual Studio Code** (recommended).
4. Extract this repository ZIP to a simple path such as `C:\DevOps\ideaboard-ai`.
5. Open that folder in VS Code: File → Open Folder.

You do not need to install Python, Node.js, or PostgreSQL on your computer for the Docker Compose route. You can also double-click `start-windows.bat` to start the app, or `stop-windows.bat` to stop it.

### Start the application

Open VS Code Terminal → New Terminal (or PowerShell), move into the project folder, then run:

```powershell
Copy-Item .env.example .env
docker compose up --build -d
```

Wait for containers to become healthy, then run:

```powershell
docker compose ps
docker compose logs -f backend
```

Open these addresses:

- Application: http://localhost:3000
- API documentation: http://localhost:8000/docs
- API health: http://localhost:8000/health

Add an idea in the web page and refresh. It should remain in PostgreSQL. The API endpoints required by the case study are:

- `GET /api/ideas` — returns all ideas.
- `POST /api/ideas` — accepts `{"content":"My new idea"}` and stores it.

Test POST from PowerShell:

```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8000/api/ideas -ContentType 'application/json' -Body '{"content":"Build an AI-powered campus assistant"}'
Invoke-RestMethod -Uri http://localhost:8000/api/ideas
```

Stop the stack:

```powershell
docker compose down
```

Stop and delete the local database volume (this permanently deletes local ideas):

```powershell
docker compose down -v
```

## 4. Understand the project folders

```text
backend/                 FastAPI application and backend Dockerfile
frontend/                React UI and frontend Dockerfile
docker-compose.yml       Runs frontend + backend + PostgreSQL locally
k8s/                     Shared Kubernetes workload manifests
infra/aws/               AWS EKS + RDS Terraform configuration
infra/gcp/               GCP GKE + Cloud SQL Terraform configuration
.github/workflows/       CI and manual deployment workflows
scripts/ai_analyze.py    Optional AI log analysis helper
docs/                    Architecture and submission notes
```

## 5. GitHub: upload your project

1. Sign in to GitHub and create a **new public repository** named `ideaboard-ai`. Do not initialize it with a README (this folder already has one).
2. In the project folder terminal:

```powershell
git init
git add .
git commit -m "Initial IdeaBoard AI DevOps platform"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/ideaboard-ai.git
git push -u origin main
```

Replace `YOUR_GITHUB_USERNAME` with your own GitHub username. Never commit `.env`, cloud credentials, API keys, Terraform state, or passwords. `.gitignore` excludes common secret/state files.

After pushing, open GitHub → your repository → Actions. The CI workflow should run on the push. It checks Python syntax, builds the frontend and both Docker images, and runs a Trivy filesystem scan. The AI step is optional and advisory.

## 6. Enable optional AI log analysis

1. Create an API key from your OpenAI developer account if you want this feature. API usage may cost money.
2. In GitHub repository: Settings → Secrets and variables → Actions → New repository secret.
3. Name it `OPENAI_API_KEY`; paste the key as the value.
4. Re-run the CI workflow. Without this secret, the workflow safely skips AI analysis.

The AI helper summarizes log evidence and suggests diagnostics. It is intentionally not allowed to run generated shell commands, approve infrastructure changes, or perform automatic rollback. A human must review the advice. This is safer than allowing an LLM to execute arbitrary deployment commands.

## 7. Terraform cloud infrastructure (advanced; do only after local + GitHub work)

**Billing warning:** EKS/GKE clusters, NAT gateways, load balancers, and managed databases may create ongoing charges even when the app is idle. Check current pricing, free-tier eligibility, quotas, and regional availability. Destroy test infrastructure when finished. Never apply both cloud configurations unless you deliberately want two separate billable environments.

Install Terraform CLI and the relevant cloud CLI. Authenticate using the provider's official login method. Use a dedicated least-privilege identity; do not paste credentials into source files.

### Option A — AWS

1. Create an AWS account, enable billing alerts, and configure AWS CLI credentials (`aws configure` or an approved SSO profile).
2. Open a terminal in `infra/aws`.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and set a strong unique database password. This file is ignored only if you add it to `.gitignore` (recommended: do not commit it).
4. Run:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

5. Configure kubectl:

```powershell
aws eks update-kubeconfig --region ap-south-1 --name ideaboard-cluster
kubectl get nodes
```

6. Get the RDS endpoint from Terraform output. Create a Kubernetes secret in the `ideaboard` namespace containing a SQLAlchemy URL. The database security group permits PostgreSQL from the EKS node security group; confirm routing and access before deploying.

```powershell
terraform output
kubectl create namespace ideaboard
kubectl create secret generic ideaboard-db -n ideaboard --from-literal=database-url='postgresql+psycopg://ideaboard:YOUR_DB_PASSWORD@YOUR_RDS_ENDPOINT:5432/ideaboard'
```

Keep the password private. For a real production system, use AWS Secrets Manager + External Secrets/CSI integration instead of a manually created Kubernetes Secret.

### Option B — GCP

1. Create/select a Google Cloud project, attach billing, enable Kubernetes Engine and Cloud SQL APIs, and authenticate with `gcloud auth application-default login`.
2. Open a terminal in `infra/gcp`. Copy `terraform.tfvars.example` to `terraform.tfvars`; set your project ID and a strong password.
3. Run:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

4. Connect to GKE:

```powershell
gcloud container clusters get-credentials ideaboard-gke --region asia-south1 --project YOUR_PROJECT_ID
kubectl get nodes
```

5. **Database connection requirement:** Cloud SQL needs a secure connector path from the workload. Configure Cloud SQL Auth Proxy or the Cloud SQL connector with Workload Identity and least-privilege IAM, then provide the correct database URL/connection path as `ideaboard-db` secret. Do not expose the database publicly. The included GCP Terraform creates the managed instance and database, but does not finish Workload Identity/Cloud SQL proxy wiring for you; follow Google's current Cloud SQL Auth Proxy for GKE instructions before deploying the app.

### Cloud-agnostic explanation

The app containers, REST API, Dockerfiles, Kubernetes Deployment/Service manifests, and GitHub workflow are shared. Terraform has provider-specific roots because AWS and GCP expose different networking, identity, Kubernetes, and database APIs. Changing providers therefore means selecting the corresponding Terraform root, cloud credentials, and database connection secret—not rewriting application code. To add a third provider, implement its infrastructure root while preserving the same container ports, environment contract, Kubernetes labels, and health endpoint.

## 8. Deploy through GitHub Actions

The workflow `.github/workflows/deploy.yml` is manually triggered and publishes versioned images to GHCR, then applies the shared Kubernetes manifests. It requires a Kubernetes cluster and a GitHub Environment secret:

1. Finish one cloud setup above and test `kubectl get nodes` locally.
2. Export the working kubeconfig and base64-encode it. Treat it as a powerful secret. Prefer short-lived OIDC-based cloud authentication for production; this simple case-study workflow uses a kubeconfig secret for ease of learning.
3. In GitHub → Settings → Environments, create `staging` and/or `production`. Add environment secret `KUBECONFIG_B64` containing the base64 kubeconfig. Protect `production` with required reviewers.
4. Ensure the cluster can pull GHCR images. For a public GHCR package this may be straightforward; for private packages create a narrowly scoped `imagePullSecret` and attach it to the service account.
5. Ensure the `ideaboard-db` secret exists in the `ideaboard` namespace as described above.
6. Open Actions → **Deploy to Kubernetes (manual approval)** → Run workflow → choose environment.
7. Check rollout and service:

```powershell
kubectl get pods -n ideaboard
kubectl get svc -n ideaboard
```

The frontend Service is type `LoadBalancer`; wait for an external address and open it in a browser. Configure DNS/TLS (for example, cert-manager + a domain) before production use.

**Rollback:** if a rollout fails, inspect `kubectl describe pod`, `kubectl logs`, and `kubectl rollout history deployment/backend -n ideaboard`. A human can run `kubectl rollout undo deployment/backend -n ideaboard` (and similarly for frontend) after confirming the previous revision is safe. AI output is advisory only.

## 9. AI integration design and value

- CI and post-deployment steps can send a bounded log excerpt to `scripts/ai_analyze.py`.
- The model returns likely cause, supporting evidence, next diagnostic steps, and whether rollback should be considered.
- The workflow continues if AI is not configured or the API is temporarily unavailable.
- The AI never receives cloud credentials by design and cannot execute commands. Deployment and rollback remain deterministic, auditable GitHub Actions/Kubernetes operations with human approval.
- This reduces time spent interpreting noisy logs without handing production control to a probabilistic model.

## 10. Security and limitations to address before production

- Replace demo/local passwords; use managed secret stores and rotate credentials.
- Restrict CORS to the real frontend domain (the Kubernetes example currently uses `*` as a demonstration; change it before production).
- Configure TLS, ingress, DNS, network policies, pod security, image scanning gates, resource quotas, and backups/restore tests.
- Use OIDC federation from GitHub Actions to cloud IAM rather than long-lived access keys or a permanent kubeconfig secret.
- Add Alembic migrations instead of relying on startup table creation for production schema changes.
- Configure private Cloud SQL connectivity and GKE Workload Identity as described above.
- Add automated integration tests and enforce vulnerability thresholds after reviewing scan findings.

## 11. Case-study deliverable checklist

- [x] React frontend to list and submit ideas
- [x] FastAPI `GET /api/ideas` and `POST /api/ideas`
- [x] PostgreSQL `ideas` table (`id`, `content`, `created_at`)
- [x] Frontend and backend Dockerfiles
- [x] Docker Compose local stack
- [x] Terraform starting roots for AWS and GCP (review/complete provider-specific connectivity before use)
- [x] Shared Kubernetes manifests
- [x] GitHub Actions CI and manual deployment workflow
- [x] Optional AI-assisted log analysis
- [x] Architecture and run instructions
- [ ] Create your GitHub repository and push this code
- [ ] Provision cloud infrastructure in two providers
- [ ] Complete each managed database connectivity setup
- [ ] Deploy and verify both public application URLs

The final three items require your own cloud accounts, credentials, decisions, and actual deployment; they cannot be truthfully pre-completed in this offline project bundle.
