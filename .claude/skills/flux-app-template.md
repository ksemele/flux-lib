---
name: flux-app-template
user-invocable: true
description: >
  Scaffold a new Flux CD app component in apps/<APP_NAME>.
  Creates a versioned subfolder, repo source, helm-release, kustomization,
  an example/ directory, and a README.
  Use this skill when a user says "add app X", "onboard chart Y", or
  "create a Flux component for Z".
  When you need Flux CD API docs, use the context7 MCP tool with
  library ID /fluxcd/flux2 (https://context7.com/fluxcd/flux2).
---

# Flux App Template – Skill

## Overview

This repository uses **Flux CD** (GitOps) to manage Kubernetes workloads.
Each application lives in `apps/<APP_NAME>/` and is composed of:

| Path | Purpose |
|---|---|
| `apps/<APP_NAME>/README.md` | Docs, helm commands, links, and notes |
| `apps/<APP_NAME>/<VERSION>/repo.yaml` | Source object (HelmRepository, GitRepository, OCIRepository) |
| `apps/<APP_NAME>/<VERSION>/helm-chart.yaml` | *(OCI only)* HelmChart linking to the OCIRepository |
| `apps/<APP_NAME>/<VERSION>/helm-release.yaml` | HelmRelease with pinned version and default values |
| `apps/<APP_NAME>/<VERSION>/kustomization.yaml` | Bundles repo.yaml, helm-release.yaml, and any others |
| `apps/<APP_NAME>/example/` | Real sync Kustomization example files |

> **VERSION** is a folder named after the chart's minor series, e.g. `5.22.x`, `1.0.x`.

---

## Step-by-step Instructions

### 1 – Gather information from the user

Before creating any files, resolve the following variables.
Ask the user if any are missing:

| Variable | Description | Example |
|---|---|---|
| `APP_NAME` | Unique name for the app release | `falco-gke`, `cert-manager` |
| `CHART_NAME` | Helm chart name inside the repo | `falco`, `cert-manager` |
| `CHART_VERSION` | Semver of the chart to pin | `4.16.0` |
| `VERSION_FOLDER` | Minor-series folder name | `4.16.x` |
| `NAMESPACE` | Target Kubernetes namespace. Ask the user or infer from chart defaults (e.g. `monitoring`, `security`, `logging`) | `monitoring` |
| `REPO_KIND` | `HelmRepository`, `GitRepository`, or `OCIRepository` | `HelmRepository` |
| `REPO_NAME` | Name of the source object (used in `sourceRef`) | `falcosecurity` |
| `REPO_URL` | URL for the repository | `https://falcosecurity.github.io/charts` |
| `DEFAULT_VALUES` | Key Helm values to apply globally *(can be empty)* | `tty: true` |

---

### 2 – Create `apps/<APP_NAME>/<VERSION_FOLDER>/`

All three files live together in the versioned subfolder.

#### 2a – `repo.yaml`

Pick the template matching `REPO_KIND`:

##### HelmRepository

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: <REPO_NAME>
  namespace: flux-system
spec:
  interval: 24h
  url: <REPO_URL>
```

##### GitRepository (private, auth via secret)

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: <REPO_NAME>
  namespace: flux-system
spec:
  url: <REPO_URL>
  interval: 5m
  secretRef:
    name: flux-git-auth
  ref:
    branch: main
```

##### OCIRepository

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: <REPO_NAME>
  namespace: flux-system
spec:
  interval: 24h
  url: oci://<REPO_URL>
  ref:
    tag: v<CHART_VERSION>
```

#### 2b – `helm-chart.yaml` *(OCI Only)*

If you use an `OCIRepository`, you **must** create a `HelmChart` resource to bridge it, as `HelmRelease` does not support `OCIRepository` directly in `sourceRef`.

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmChart
metadata:
  name: <APP_NAME>
  namespace: flux-system
spec:
  chart: <CHART_NAME>
  version: '<CHART_VERSION>'
  sourceRef:
    kind: OCIRepository
    name: <REPO_NAME>
  interval: 1h
```

#### 2c – `helm-release.yaml`

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <APP_NAME>
  namespace: flux-system
spec:
  interval: 5m
  releaseName: <APP_NAME>
  targetNamespace: <NAMESPACE>
  storageNamespace: <NAMESPACE>
  
  # Option 1: For HelmRepository or GitRepository
  chart:
    spec:
      chart: <CHART_NAME>
      version: '<CHART_VERSION>'
      sourceRef:
        kind: <REPO_KIND>
        name: <REPO_NAME>
        namespace: flux-system
  
  # Option 2: For OCIRepository (uncomment and remove `chart:` block above)
  # chartRef:
  #   kind: HelmChart
  #   name: <APP_NAME>
  #   namespace: flux-system
  
  values:
    # Default values applied to every cluster/env.
    # Only set values that should be universal; leave cluster-specific
    # overrides to custom-resources patches.
    <DEFAULT_VALUES>
```

> **Rule:** Only put values here that are safe and appropriate for *every*
> cluster and environment. When in doubt, leave `values:` empty or commented out.

#### 2d – `kustomization.yaml`

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - repo.yaml
  # - helm-chart.yaml       # uncomment if using OCI
  - helm-release.yaml
  # - network-policy.yaml   # uncomment if you add one
```

#### 2e – `network-policy.yaml` *(optional)*

Only create this file when the app needs explicit ingress/egress control and the user directly asks for it.
Adjust `podSelector`, ports, and CIDR to match the app.

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-<APP_NAME>-${ENV:=instance}
  namespace: <NAMESPACE>
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: <APP_NAME>
  ingress:
    - from:
        - ipBlock:
            cidr: ${COMPANY_IP_CIDR:=10.0.0.0/8}
      ports:
        - port: <PORT>
  policyTypes:
    - Ingress
```

If created, add `network-policy.yaml` to the `resources:` list in `kustomization.yaml`.

---

### 3 – Create `apps/<APP_NAME>/example/`

Instead of inline code blocks in the README, create real example files here.
These show how a cluster sync entry would reference this component.

#### 3a – `example/<APP_NAME>.yaml`

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: <APP_NAME>
  namespace: flux-system
spec:
  interval: 5m
  dependsOn:
    - name: repos
  sourceRef:
    kind: GitRepository
    name: flux-lib
  path: ./apps/<APP_NAME>/<VERSION_FOLDER>
  prune: false
  wait: true
  timeout: 20m
  retryInterval: 5m
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-variables
        optional: false
```

#### 3b – `example/kustomization.yaml`

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - <APP_NAME>.yaml
```

---

### 4 – Create `apps/<APP_NAME>/README.md`

Use the following concise format. Do **not** include YAML code blocks of sync
Kustomizations – those live in `example/` instead.

````markdown
# <APP_NAME>

<One-sentence description of what this app does.>

Docs:

- <LINK_TO_UPSTREAM_DOCS>
- <LINK_TO_CHART_DOCS>

## Local add repo

```sh
# For HelmRepository:
helm repo add <REPO_NAME> <REPO_URL>

# For OCIRepository – no add needed, use directly:
helm show values oci://<REPO_URL> --version <CHART_VERSION>
```

## Get default values

```sh
helm show values <REPO_NAME>/<CHART_NAME>
# or for OCI:
helm show values oci://<REPO_URL> --version <CHART_VERSION>
```

## Check latest chart versions

```sh
helm search repo <REPO_NAME>/<CHART_NAME> --versions | head -n 5
```

## Additional links

<UPSTREAM_GITHUB_URL>
<UPSTREAM_HELM_CHART_PATH_URL>

---

Create a versioned folder under this component (example: `<VERSION_FOLDER>`) containing
`helm-release.yaml`, `repo.yaml` and `kustomization.yaml` similar to other
components in `apps`.

Adjust chart version and values to match the official chart when available.
````

---

### 5 – Final checklist

Before committing, verify all of the following:

- [ ] `apps/<APP_NAME>/<VERSION_FOLDER>/repo.yaml` created with correct source kind and URL
- [ ] `apps/<APP_NAME>/<VERSION_FOLDER>/helm-chart.yaml` created if using `OCIRepository`
- [ ] `apps/<APP_NAME>/<VERSION_FOLDER>/helm-release.yaml` created with correct `chart` or `chartRef`, `version`, `sourceRef` and `values`
- [ ] `apps/<APP_NAME>/<VERSION_FOLDER>/kustomization.yaml` lists all created resources
- [ ] `apps/<APP_NAME>/example/<APP_NAME>.yaml` is a real sync Kustomization (not a code block in README)
- [ ] `apps/<APP_NAME>/example/kustomization.yaml` references the example file
- [ ] `apps/<APP_NAME>/README.md` uses the concise format (docs, helm commands, links, versioned folder note)
- [ ] `network-policy.yaml` included only if needed; listed in `kustomization.yaml`
- [ ] All YAML filenames are **kebab-case** (e.g. `helm-release.yaml`, not `HelmRelease.yaml`)
- [ ] `sourceRef.name` in example sync Kustomization is **`flux-lib`**, not `flux-system`
- [ ] `targetNamespace` / `storageNamespace` reflect the correct app namespace (not `flux-system`)
- [ ] All `<PLACEHOLDER>` tokens replaced with real values
- [ ] Markdown linted (markdownlint rules apply – no trailing spaces, blank lines around headings, etc.)

---

## Key conventions

- **File naming is kebab-case** – all YAML files must use lowercase kebab-case
  (e.g. `helm-release.yaml`, `network-policy.yaml`). Never use PascalCase filenames.
- **Versioned subfolders** – chart files live in a `<MAJOR>.<MINOR>.x` subfolder
  (e.g. `5.22.x/`). This makes version bumps a folder copy rather than an in-place edit.
- **`repo.yaml` lives inside the versioned folder** – not in a shared `repos/` directory.
- **`example/` instead of README code blocks** – real Kustomization examples go in
  `apps/<APP_NAME>/example/`, keeping the README concise.
- **`sourceRef.name` is always `flux-lib`** – sync Kustomizations reference the `flux-lib`
  GitRepository, not `flux-system`.
- **`targetNamespace` is app-specific** – never use `flux-system` as the target namespace.
  Derive the namespace from the chart's own defaults (e.g. `monitoring`, `security`) or
  ask the user. `storageNamespace` must always match `targetNamespace`.
- **`metadata.namespace` is always `flux-system`** for HelmRelease and source
  objects, even when `targetNamespace` is different.
- **`interval: 5m`** is the standard reconcile interval for HelmReleases;
  use `24h` for source repositories.
- **`prune: false`** on Kustomization objects prevents accidental deletion
  during partial rollouts.
- **Post-build substitutions** use `cluster-variables` ConfigMap; add per-app
  variables there rather than hard-coding them in sync files.
- **Version pinning is mandatory** – never use `*` or floating tags in
  production chart references.

## Useful links

- [Flux HelmRelease API](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Flux Source controller](https://fluxcd.io/flux/components/source/)
- [Kustomize reference](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [markdownlint rules](https://github.com/markdownlint/markdownlint/blob/main/docs/RULES.md#rules)
