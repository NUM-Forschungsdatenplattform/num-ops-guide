
## Environments

The clusters are managed by [rancher](https://prod.rancher.gwdg.de/dashboard/home).

### Codex Cluster

- Cluster: codex-central

### Codex Dev Environment

- Cluster: codex-central
- Namespace: central-research-repository-development

#### Codex Keycloak

- URL: https://keycloak.dev.num-codex.de/auth

### Dev Cluster

- Cluster: dev (rdp-dev)
- DNS: \*.dev.num-rdp.de has address 134.76.15.219
- ArgoCD: https://argocd.dev.num-rdp.de/applications

### Dev Environment

- Cluster: dev (rdp-dev)
- Namespace: develop

#### Portal

- URL: https://develop.dev.num-rdp.de

#### Keycloak

- URL: https://keycloak.develop.dev.num-rdp.de/auth
- HTTP Basic auth: see secret `keycloak-basic-auth-input`
- Keycloak Username/Password: see secret `develop-keycloak-admin`

### Test Environment

- Cluster: dev (rdp-dev)
- Namespace: test

#### Portal

- URL: https://test.dev.num-rdp.de

#### Keycloak

- URL: https://keycloak.test.dev.num-rdp.de/auth
- HTTP Basic auth: see secret `keycloak-basic-auth-input`
- Keycloak Username/Password: see secret `develop-keycloak-admin`
