# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

`flux-lib` is a **centralized library of Flux CD components** meant to be consumed by cluster repositories via Git. It separates reusable component blueprints (HelmReleases, source definitions) from environment-specific values and secrets. Components are pinned and versioned here; clusters reference them via a `GitRepository` source named `flux-lib`.

## Development Environment

No build/compile step exists — this is a pure GitOps/YAML repository. The devcontainer provisions:

- `kind` (v0.31.0) — local Kubernetes cluster
- `flux` CLI (v2.8.1)
- `kubectl` (v1.35.2) and `helm` (v4.1.1)

```sh
# Create local kind cluster and install Flux
kind create cluster --name flux --config .devcontainer/kind-cluster.yaml
flux install

# Apply this library as a GitRepository source to a cluster
kubectl apply -f flux-lib-source.yaml

# Inspect a HelmRelease on the cluster
flux get helmrelease -A

# Check chart values before writing a HelmRelease
helm repo add <REPO_NAME> <REPO_URL>
helm show values <REPO_NAME>/<CHART_NAME>
# For OCI repos:
helm show values oci://<REPO_URL> --version <CHART_VERSION>
```

## Repository Structure

```
apps/
  <APP_NAME>/
    README.md                        # Docs, helm commands, upstream links
    <MAJOR>.<MINOR>.x/               # Versioned folder (e.g. 5.22.x/)
      repo.yaml                      # HelmRepository / OCIRepository / GitRepository
      helm-chart.yaml                # (OCI only) HelmChart bridging OCIRepository → HelmRelease
      helm-release.yaml              # HelmRelease pinned to chart version
      kustomization.yaml             # Bundles all resources in this folder
    example/
      <APP_NAME>.yaml                # Real sync Kustomization (not a code block)
      kustomization.yaml
clusters/
  <CLUSTER>/
    custom-resources/                # Cluster-specific patches and overrides
flux-lib-source.yaml                 # GitRepository definition for this library
```

## Adding a New App

Use the `/flux-app-template` skill — it guides you through gathering variables, creating all required files, and verifying the checklist.

### Key conventions

- **Kebab-case filenames** — `helm-release.yaml`, not `HelmRelease.yaml`
- **Versioned subfolders** — chart files live in `<MAJOR>.<MINOR>.x/` (e.g. `5.22.x/`)
- **`repo.yaml` lives inside the versioned folder**, not a shared `repos/` directory
- **`example/` instead of README code blocks** — real sync Kustomizations go in `apps/<APP_NAME>/example/`
- **`sourceRef.name` is always `flux-lib`** in sync Kustomizations
- **`metadata.namespace: flux-system`** for all HelmRelease and source objects
- **`targetNamespace` / `storageNamespace`** must be the app's own namespace (never `flux-system`)
- **`interval: 5m`** for HelmReleases; **`interval: 24h`** for source repositories
- **`prune: false`** on sync Kustomization objects
- **Version pinning is mandatory** — no `*` or floating tags
- **`storageNamespace` must match `targetNamespace`**
- Post-build substitutions use a `cluster-variables` ConfigMap — add per-app variables there instead of hard-coding

### OCI source pattern

When `REPO_KIND` is `OCIRepository`, a `HelmChart` bridge resource (`helm-chart.yaml`) is required because `HelmRelease.spec.chart.spec.sourceRef` does not accept `OCIRepository`. Use `chartRef` in `helm-release.yaml` instead of `chart`.

## Flux CD API Documentation

When working with Flux resource APIs, use the Context7 MCP tool with library ID `/fluxcd/flux2` for up-to-date docs.

## Useful Links

- [Flux HelmRelease API](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Flux Source controller](https://fluxcd.io/flux/components/source/)
- [Kustomize reference](https://kubectl.docs.kubernetes.io/references/kustomize/)
