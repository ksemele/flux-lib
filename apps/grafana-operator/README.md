# Grafana Operator

Installation templates and notes for Grafana Operator.

Docs:

- https://grafana.github.io/grafana-operator/
- https://github.com/grafana/grafana-operator/blob/v5.22.0/docs/

## Get default values

```sh
helm show values oci://ghcr.io/grafana/helm-charts/grafana-operator --version 5.22.0
```

## Check latest chart versions

```sh
# List tags via GitHub releases
open https://github.com/grafana/grafana-operator/releases
```

## Additional links

https://github.com/grafana/grafana-operator
https://github.com/grafana/grafana-operator/tree/main/deploy/helm/grafana-operator

---

Create a versioned folder under this component (example: `5.22.x`) containing
`helm-release.yaml`, `repo.yaml` and `kustomization.yaml` similar to other
components in `apps`.

Adjust chart version and values to match the official chart when available.
