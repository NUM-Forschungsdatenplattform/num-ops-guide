export VL_USER=$(kubectl get secret http-auth-scecret -o jsonpath="{.data.username}" | base64 -d)
export VL_PASSWD=$(kubectl get secret http-auth-scecret -o jsonpath="{.data.password}" | base64 -d)

echo user: "$VL_USER" password: "$VL_PASSWD"

htpasswd -bc auth "$VL_USER" "$VL_PASSWD"


kubectl create secret generic basic-auth --from-file=auth -o yaml --dry-run=client | kubeseal -o yaml > basic-auth-sealed-secret.yaml


