# flux-lib

A centralized library of **Flux CD components and applications**. 

This repository provides highly-reusable, declarative deployments (such as HelmReleases, Kustomizations, and repository references) meant to be consumed by other cluster repositories. It separates the component blueprints from environment-specific configuration values and secrets.

## Usage

To use these components in your cluster, first add this repository as a `GitRepository` source in your Flux configuration. 

See [`flux-lib-source.yaml`](./flux-lib-source.yaml) for a pre-configured example, or apply it directly to your cluster (make sure to replace the `secretRef.name` with your actual Git SSH key secret):

```sh
kubectl apply -f flux-lib-source.yaml
```

Once the source is registered as `flux-lib`, you can deploy any application from this library by referencing it in your cluster's sync Kustomizations:

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: grafana-operator
  namespace: grafana-operator
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-lib
  path: ./apps/grafana-operator/5.22.x
  prune: false
  # ... Add additional cluster-specific configurations
```

## Available Apps

Explore the `apps/` directory for available applications and their usage instructions. Each application contains a `README.md` detailing how to deploy it, as well as an `example/` directory showing how it expects to be consumed.

* [grafana-operator](./apps/grafana-operator)
