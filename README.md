# homelab-k8s

GitOps repository for the homelab Kubernetes (k3s) cluster, managed by **ArgoCD ApplicationSets** and **Helm**.

## Repository Structure

```text
homelab-k8s/
├── values/
│   └── global.yaml                    # Cluster-wide variables (domain, tunnel ID, secrets, namespaces)
├── argocd/
│   ├── root-app.yaml                  # Root App-of-Apps watching `argocd/`
│   ├── infrastructure-appset.yaml     # ApplicationSet deploying `infrastructure/*`
│   └── workloads-appset.yaml          # ApplicationSet deploying `apps/*` via `charts/app-template`
├── charts/
│   └── app-template/                  # Reusable Helm chart for standard homelab applications
├── infrastructure/
│   ├── namespaces/                    # Managed namespaces (sync-wave -1)
│   ├── cloudflared/                   # Cloudflare Tunnel & ingress routing ConfigMap
│   ├── external-dns/                  # External-DNS controller (Cloudflare DNS automation)
│   └── reloader/                      # Stakater Reloader (auto-restarts pods on ConfigMap/Secret changes)
└── apps/
    ├── hello/                         # POC workload: hello.ghport.com
    │   └── values.yaml
    └── hello2/                        # POC workload: hello2.ghport.com
        └── values.yaml
```

## Centralized Variables

Cluster-wide settings are defined once in [`values/global.yaml`](values/global.yaml) and automatically injected into both infrastructure and workload charts by ArgoCD:

- **`global.domain`**: Base Cloudflare domain (`ghport.com`)
- **`global.appsNamespace`**: Default namespace for workloads (`apps`)
- **`global.cloudflare.tunnelId`**: Cloudflare Tunnel UUID
- **`global.cloudflare.credentialsSecret` / `apiTokenSecret`**: Secret names for Cloudflare credentials
- **`global.externalDns.txtOwnerId`**: External-DNS TXT ownership identifier (`k3s-gitops`)

## How to Add a New App

Adding a new application to the cluster only requires **2 steps**:

### 1. Create `apps/<app-name>/values.yaml`

Create a folder under `apps/` with your app name (for example, `apps/myapp/values.yaml`). The `workloads` ApplicationSet will automatically detect the new directory and deploy it using [`charts/app-template`](charts/app-template/values.yaml):

```yaml
replicaCount: 1

image:
  repository: nginxdemos/hello
  tag: plain-text

service:
  port: 80

dns:
  # Automatically creates <app-name>.<global.domain> CNAME in Cloudflare via External-DNS
  enabled: true
```

> See [`charts/app-template/values.yaml`](charts/app-template/values.yaml) for all supported options (`env`, `envFrom`, `persistence`, `resources`, `probes`, `reloader.auto`, etc.).

### 2. Add the Route to `infrastructure/cloudflared/values.yaml`

Append the subdomain to the `routes` list in [`infrastructure/cloudflared/values.yaml`](infrastructure/cloudflared/values.yaml):

```yaml
routes:
  - subdomain: argocd
    service: http://argocd-server.argocd.svc.cluster.local:80
  - subdomain: hello
  - subdomain: hello2
  - subdomain: myapp
```

> For any app in the `apps` namespace using port `80`, only `subdomain: <app-name>` is needed—the chart automatically resolves `http://<app-name>-svc.apps.svc.cluster.local:80` and Stakater Reloader restarts `cloudflared` automatically when the ConfigMap updates.

## Bootstrapping / Updating Root Application

Ensure the `root-application` in ArgoCD points to the `argocd/` directory:

```bash
kubectl apply -f argocd/root-app.yaml
```
