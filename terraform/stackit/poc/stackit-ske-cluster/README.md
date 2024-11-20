# Terraform for stackit poc

## Tips

- install nginx ingress controller

```
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

- get .kube/config: `terraform output -raw kubeconfig`

- to publish a service with dns name, just add this annotation:

```
  annotations:
    external-dns.alpha.kubernetes.io/hostname: <service>.highmed.runs.onstackit.cloud
```
