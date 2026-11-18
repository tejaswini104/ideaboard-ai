# AWS EC2 Quickstart (30–60 minute MVP)

This deploys the supplied IdeaBoard app on one Ubuntu EC2 VM using Docker Compose and PostgreSQL. It is an AWS-hosted MVP, **not** the full case-study architecture: EKS, managed RDS, second-cloud deployment and cloud-agnostic multi-cloud IaC remain later milestones.

## 1. AWS account and cost guardrails

- Check Billing → Free Tier / Credits and confirm whether this account is on the Free plan or Paid plan.
- New eligible AWS customers currently receive $100 signup credits and may earn up to $100 more; the Free plan is limited to six months or credit exhaustion. Check the actual balance and expiry in your account.
- For the quickstart, choose an EC2 size marked Free tier eligible in your own console. For accounts created on/after 15 July 2025, AWS lists t3.micro/t3.small and t4g.micro/t4g.small among eligible types. For older accounts, eligibility differs.
- Do not create EKS, NAT Gateway, RDS, or Load Balancer for this 1-hour MVP. They can add cost and are not required for this single-VM proof of concept.
- Create a small AWS Budget/email alert. Budgets are alerts, not hard spending caps.

## 2. Launch EC2

In EC2 → Launch instance:

- Name: `ideaboard-mvp`
- AMI: Ubuntu Server 24.04 LTS (64-bit x86)
- Instance type: choose a Free Tier eligible type shown by your account. `t3.small` is more comfortable for building images; `t3.micro` may need swap and can be slow.
- Key pair: create/download a `.pem` key and keep it private.
- Network: create/select a security group with **SSH TCP 22 from My IP only** and **HTTP TCP 80 from 0.0.0.0/0**. Do not open 5432 or 8000. Do not open SSH to the whole internet.
- Storage: 20 GB gp3 (check the free/credit allowance shown for your account).
- Launch.

Copy the instance Public IPv4 address. If the console does not assign one, enable auto-assign public IPv4 or allocate an Elastic IP only if you understand its charges.

## 3. Connect and install Docker

From Windows PowerShell (replace path and IP):

```powershell
ssh -i "$HOME\Downloads\ideaboard-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

On EC2:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git openssl
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
exit
```

Reconnect over SSH so the docker group takes effect. Verify:

```bash
docker --version
docker compose version
```

If you use a 1 GB instance and Docker builds run out of memory, add 2 GB swap:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 4. Put the repository on GitHub

Create a GitHub repository. Push the contents of this project folder to its `main` branch. For the simplest first deployment, make the repository public so EC2 can clone it without a deploy key. Never commit `.env`, API keys, passwords, AWS credentials, Terraform state or private keys.

On EC2:

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/ideaboard-ai.git
cd ideaboard-ai
```

## 5. Configure the database password and start the app

On EC2, generate a URL-safe random password and write it to `.env`:

```bash
umask 077
POSTGRES_PASSWORD="$(openssl rand -hex 24)"
printf 'POSTGRES_PASSWORD=%s\n' "$POSTGRES_PASSWORD" > .env
unset POSTGRES_PASSWORD
```

Start the AWS Compose stack:

```bash
docker compose --env-file .env -f docker-compose.aws.yml up --build -d
```

Check:

```bash
docker compose --env-file .env -f docker-compose.aws.yml ps
docker compose --env-file .env -f docker-compose.aws.yml logs --tail=100 backend
curl -fsS http://localhost/health
curl -fsS http://localhost/api/ideas
```

Expected health response includes `"status":"ok"` and `"database":"connected"`.

Open in your browser:

`http://YOUR_EC2_PUBLIC_IP/`

Add an idea, refresh the page, and verify it persists.

## 6. Basic operations

```bash
# View logs
docker compose --env-file .env -f docker-compose.aws.yml logs -f

# Restart

docker compose --env-file .env -f docker-compose.aws.yml restart

# Pull latest source and rebuild

git pull
docker compose --env-file .env -f docker-compose.aws.yml up --build -d

# Stop containers (keeps database volume)
docker compose --env-file .env -f docker-compose.aws.yml down
```

Do **not** use `down -v` unless you intentionally want to delete the PostgreSQL data volume.

## 7. AI log analysis (optional)

The repository includes `scripts/ai_analyze.py`. It sends the supplied log text to the OpenAI Responses API using `OPENAI_API_KEY`. API usage may cost money. Keep the key out of the repository and do not paste secrets or sensitive production logs into an external AI service. It is advisory only; it does not execute commands or perform rollback.

Example on EC2 after configuring a key securely in your shell:

```bash
docker compose --env-file .env -f docker-compose.aws.yml logs --no-color --tail=200 > deploy.log
OPENAI_API_KEY='YOUR_API_KEY' python3 scripts/ai_analyze.py deploy.log
```

## 8. Security and cleanup

- This is a learning/demo deployment. Add HTTPS (domain + TLS reverse proxy or managed edge), patching, backups, monitoring, and a proper secret manager before production use.
- PostgreSQL is not published to the host; only HTTP port 80 is exposed. SSH is restricted to your IP.
- Stop/delete the EC2 instance and its EBS volume when finished if you do not need it. Check for leftover public IPv4 addresses, snapshots, volumes, and other resources. Deleting an instance does not necessarily delete every separately allocated resource.

## 9. What remains for the full case study

This quickstart does not satisfy every original deliverable. The case study additionally asks for an orchestration service, managed PostgreSQL, modular cloud-agnostic IaC deployable to at least two providers, and successful deployments on two providers. The next AWS milestone is EKS + RDS + Terraform modules + OIDC-based GitHub Actions deployment; the second-provider milestone is GKE + Cloud SQL or another supported cloud equivalent.
