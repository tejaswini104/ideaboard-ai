# Architecture Notes

## Request path
1. Browser loads the React single-page app from Nginx.
2. Nginx proxies `/api/*` requests to FastAPI on the internal container network.
3. FastAPI validates input with Pydantic and uses SQLAlchemy parameterized SQL.
4. PostgreSQL persists the idea rows.
5. `/health` checks database connectivity and is used by Kubernetes probes.

## Delivery path
Pull requests and pushes run the CI workflow. The workflow performs syntax/build checks, builds both images, and runs a Trivy filesystem scan. The optional AI helper receives only a bounded log excerpt and emits advice. A separate manual workflow publishes immutable commit-SHA image tags and deploys to a cluster after environment approval.

## Multi-cloud boundary
The shared contract is container images, ports, environment variables, health endpoint, and Kubernetes manifests. Provider-specific Terraform provisions the managed Kubernetes control plane, network, and managed PostgreSQL service. The database connection secret is deliberately supplied at deploy time, not committed.
