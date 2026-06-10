# GitOps with k-zero-ess

A GitOps learning lab demonstrating an end-to-end workflow: bootstrapping a **k0s** Kubernetes cluster, deploying applications and applicationsets via **Argo CD**, shipping a simple nginx application with raw manifests and **Kustomize** overlays.

## High-Level Structure

```
.
├── 0-k0s/                  # Cluster bootstrap (k0s config + steps)
├── 1-argocd/               # Argo CD installation, ApplicationSet + Martix Generator
│   ├── infra-apps/         #   AppSet + multi cluster configs + Helm values
│   └── post-deployments/   #   Cilium LB pool, L2 policy, NGF Gateway
├── 2-app-deployments/      # Raw Kubernetes manifests (nginx webserver)
│   └── nginx-webserver/
└── 3-nginx-kustomization/  # Kustomize base + dev/stage(blue/green) overlays
    ├── base/
    └── overlays/
        ├── dev/
        └── stage/          # blue/green sub-overlays
```

### `0-k0s/` — Cluster Bootstrap

- `k0s-steps.txt` — step-by-step commands to install a k0s controller and join worker nodes.
- `k0s.conf` — full `ClusterConfig`: pod CIDR `10.244.0.0/16`, service CIDR `10.96.0.0/12`, etcd backend, custom CNI provider (Cilium installed separately), kube-proxy disabled.

### `1-argocd/` — Infrastructure via Argo CD
| Directory | Description |
|---|---|
| `argo-installation.sh` | installs Argo CD into the cluster. |
| `infra-apps/appset.yaml` | **ApplicationSet** using a matrix generator (Git files × cluster list) to deploy Helm charts to clusters `k0s-1` and `k0s-2`. |
| `infra-apps/infra-configs/` | per-cluster JSON configs pointing to Helm repos, charts, versions, and value file paths. Current lab deploy on **k0s-2** cluster. |
| `infra-apps/infra-values/` | per-app Helm values: `defaults.yaml` (shared) + `{cluster}.yaml` (cluster-specific). Currently, this lab only shows one cluster deployment and can add additional cluster using argocli `argocd  cluster add <context>`  |
| `post-deployments/` | manual post-install resources Cilium LoadBalancer IP pool, L2 announcement policy & NGINX Gateway Fabric shared Gateway |

### `2-app-deployments/` - Simple Nginx Deployment (Raw Manifests)
> A simple nginx webserver deployed via plain Kubernetes manifests: 

| Resource | Description |
|---|---|
| **ConfigMap** | HTML page content |
| **Deployment** | `nginx:alpine` mounting the ConfigMap |
| **ClusterIP Service** | port 80 |
| **HTTPRoute** | Gateway API route via the shared NGF Gateway |

### `3-nginx-kustomization/` Nginx Kustomization 
> The same nginx app structured with Kustomize for environment variations:  

| Path | Description |
|---|---|
| **base/** | hardened Deployment (`**non-root, readOnlyRootFS, liveness, readiness,health probes), Service, HTTPRoute.**` |
| **overlays/dev/** | `testing-dev` namespace, unprivileged image, lower resources, `nginx-dev.example.com`.|
| **overlays/stage/** | blue/green sub-overlays in `testing-stage-blue` and `testing-stage-green` namespaces with distinct hostnames and color-themed pages. |

## Tools

| Tool | Role |
|---|---|
| **k0s** | Lightweight Kubernetes distribution (controller + worker, etcd backend) |
| **Cilium** v1.18 | CNI, kube-proxy replacement, L2 announcements, LB IPAM |
| **Argo CD** | GitOps engine — ApplicationSet with dynamic goTemplating, matrix generators, multi-cluster targeting |
| **Kustomize** | Kustomization (patches, configMapGenerator, replacements, overlays) |
| **NGINX Gateway Fabric** v2.6 | Kubernetes Gateway API controller |
| **Longhorn** v1.12 | Distributed block storage (configured, currently disabled, ready to use) |
| **Fluent Bit** v0.48 | Log collection & forwarding (configured, currently disabled, ready to use) |

## Deployment Flow

1. **Bootstrap k0s** : follow `0-k0s/k0s-steps.txt` to create controller + worker nodes.
2. **Install ArgoCD & deploy infra workloads with Appset** : run `1-argocd/argo-installation.sh`, then apply with command `k apply -f appset.yaml` to deploy Cilium and NGINX Gateway Fabric across clusters.
3. **Apply post-deployment resources** : LB IP pool, L2 policy, shared Gateway.
4. **Deploy the sample app** : apply the raw manifests `k apply -f 2-app-deployments/`
Infrastructure apps (Longhorn, Fluent Bit) are pre-configured but disabled via a `_` suffix on their config files - rename to enable when ready.
5. **Deploy nginx with argo Applicationset** : apply argo appset `k apply -f 3-nginx-kustomization/nginx-appset.yaml`

## To-do list

| Name | Description|
|---|---|
| **OIDC**  | For kubernetes cluster and ArgoCD |
| **ESO** | External Secret Operator to consume secrets from Hashicorp Vault, Openbao, Google/AWS secret managers |
| **Cilium Network Policies** | Network policies for each namespaces and apps |
| **Cluster & Deployments** | More Labs |
