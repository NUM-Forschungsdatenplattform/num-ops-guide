export VL_USER=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.username}" | base64 -d)
export VL_PASSWD=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.password}" | base64 -d)

echo user: "$VL_USER" password: "$VL_PASSWD"

htpasswd -bc auth "$VL_USER" "$VL_PASSWD"


kubectl create secret generic basic-auth --from-file=auth -o yaml --dry-run=client | kubeseal -o yaml > basic-auth-sealed-secret.yaml

---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: basic-auth
  namespace: victoria-logs
spec:
  encryptedData:
    auth: AgBar2eYwzfPx3A2BZ5b9f4N7idp1MXm83iqls7LUBMlubi+9W0cllZ/J6YmshLBb45fXZMv8y9666NJFvtkx9yHIniyxqZQ9m2dSCZ/KqmpgxRJnMywNRW/NmPdRjEvQ0eG0/F5QLtzbsdDlL7mad1CSwr412Kp7Dbqk7CHDY/dS9FZAYAg1/vkkPUaKDmE4ydDNQvOeCfKaz83iOGRgSLoRKgI4/EaW3ME2buGsfUEVC5fYokOT3dRVavN6w9bSkrNTAnJnKsSSEJ6Y5ZMhmyf8IIENx33rwQc9om0d03+JheTCi49Lii5TKcX+gmK4gLr/wsCte3a07o/hgdXOW1/bpy8NdYJv/xSAqQYUICXOHmkZ24283+LNl7EeCj2naYNB9vZKKkHwwDOXLt91jT+r+PV/V+o8cLc/KXBYaQbjIUFKYlj5rBBWRS5rDtXZC0X570rRkNPZ3yUH771Wr+fPefVFSBlCCJctR2l/cnvEJzj6q4hiw1+HgfygIjmD5W3wuPBjNKyGQGFn2vz1CF+LVGTTYe8JojJLrM9Js251jwiVCkbkA1WYI9onjWWkzhcmlUw6hpe96rc40VCiqa9zw3SMy4mDvAWwNfxtegpIcV3qwYJf0NhVYOf7N+BbaydRdQ4CorOLZGIHB5BOMTaR+NJg5J9AuRte57+yLEn+ZcNdCrVN6RYaVuFlstnEHwgYp8yCqvZA+j2WYKGPBOF3WHAzTGFsB1GDmxu2bKzXcapKkfo8ZenQ7+6tjaWfeP8B7uYC7L8Nhc=
  template:
    metadata:
      creationTimestamp: null
      name: basic-auth
      namespace: victoria-logs




$ k get secret basic-auth-generated-secret -o yaml
apiVersion: v1
data:
  password: cC1DV1RKQmVNMVNiYjh0bkV3RkpMN09RT0huVkpuNFc2cg==
  username: dS1mU21qbEhGTU1Xa2kxbjRm
kind: Secret
metadata:
  annotations:
    helm.sh/resource-policy: keep
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"password":"cC1DV1RKQmVNMVNiYjh0bkV3RkpMN09RT0huVkpuNFc2cg==","username":"dS1mU21qbEhGTU1Xa2kxbjRm"},"kind":"Secret","metadata":{"annotations":{"helm.sh/resource-policy":"keep"},"labels":{"argocd.argoproj.io/instance":"victoria-logs"},"name":"basic-auth-generated-secret","namespace":"victoria-logs"},"type":"Opaque"}
  creationTimestamp: "2024-03-03T07:27:57Z"
  labels:
    argocd.argoproj.io/instance: victoria-logs
  name: basic-auth-generated-secret
  namespace: victoria-logs
  resourceVersion: "18419997"
  uid: bbb06e59-431a-4a11-827e-1bdc2bcfe6a1
type: Opaque

