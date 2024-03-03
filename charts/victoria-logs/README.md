# secret handling for victoria logs basic http auth file used by nginx ingress controller

## get and export generated secrets

    export VL_USER=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.username}" | base64 -d)
    export VL_PASSWD=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.password}" | base64 -d)

    echo user: "$VL_USER" password: "$VL_PASSWD"

## create auth file

    htpasswd -bc auth "$VL_USER" "$VL_PASSWD"

## backup username and password in an generic basic-auth-input secret

    kubectl create secret generic basic-auth-input --from-literal=username="$VL_USER" --from-literal=password="$VL_PASSWD"

## create an sealed secret from the auth file

    kubectl create secret generic basic-auth --from-file=auth -o yaml --dry-run=client | kubeseal -o yaml > basic-auth-sealed-secret.yaml

