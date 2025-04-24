## Tasks

Follow the step-by-step instructions in the guide to deploy and configure each component. The guide is continually updated to include the latest best practices and improvements.

  * [Content](#content)
  * [Run a test pod for debugging purpose](#run-a-test-pod-for-debugging-purpose)
  * [Securing Kubernetes Services with Let's Encrypt, Nginx Ingress Controller and Cert-Manager](#securing-kubernetes-services-with-lets-encrypt-nginx-ingress-controller-and-cert-manager)
    + [Introduction](#introduction)
    + [Configuring Let's Encrypt Issuer](#configuring-lets-encrypt-issuer)
    + [Cert-Manager and Ingress](#cert-manager-and-ingress)
    + [Conclusion](#conclusion)
    + [Sources](#sources)
  * [Securing Kubernetes Services with Ingress-Nginx Controller and Basic Authentication](#securing-kubernetes-services-with-ingress-nginx-controller-and-basic-authentication)
    + [Create htpasswd file](#create-htpasswd-file)
    + [Convert auth file into a sealed secret](#convert-auth-file-into-a-sealed-secret)
    + [Create an ingress tied to the basic-auth secret](#create-an-ingress-tied-to-the-basic-auth-secret)
    + [Use curl to confirm authorization is required by the ingress](#use-curl-to-confirm-authorization-is-required-by-the-ingress)
    + [Use curl with the correct credentials to connect to the ingress](#use-curl-with-the-correct-credentials-to-connect-to-the-ingress)
    + [Sources](#sources-1)
  * [Using VictoriaLogs with Web UI](#using-victorialogs-with-web-ui)
  * [Using VictoriaLogs from the command line](#using-victorialogs-from-the-command-line)
  * [How to disable DEV dsf-bpe on CODEX cluster](#how-to-disable-dev-dsf-bpe-on-codex-cluster)
  * [How to test DEV fhir-bridge on CODEX cluster](#how-to-test-dev-fhir-bridge-on-codex-cluster)
    + [Count COMPOSITIONs in ehrbase](#count-compositions-in-ehrbase)
    + [Add one Observation to fhir-bridge](#add-one-observation-to-fhir-bridge)
  * [How to dump dev keycloak db on CODEX cluster](#how-to-dump-dev-keycloak-db-on-codex-cluster)
  * [How to import dump of dev keycloak db on dev cluster](#how-to-import-dump-of-dev-keycloak-db-on-dev-cluster)
  * [How to setup the develop environment](#how-to-setup-the-develop-environment)
    + [Rollout new environment](#rollout-new-environment)
    + [Configure keycloak](#configure-keycloak)
    + [Configure num-portal](#configure-num-portal)
    + [test login](#test-login)
  * [How to get certs for DSF](#how-to-get-certs-for-dsf)
  * [How to prepare certs for DSF](#how-to-prepare-certs-for-dsf)
    + [Store PEM encoded certificate as ssl_certificate_file.pem](#store-pem-encoded-certificate-as-ssl_certificate_filepem)
    + [Store unencrypted, PEM encoded private-key as ssl_certificate_key_file.pem](#store-unencrypted-pem-encoded-private-key-as-ssl_certificate_key_filepem)
    + [Store PEM encoded certificate as client_certificate.pem](#store-pem-encoded-certificate-as-client_certificatepem)
    + [Store encrypted or not encrypted, PEM encoded private-key as client_certificate_private_key.pem](#store-encrypted-or-not-encrypted-pem-encoded-private-key-as-client_certificate_private_keypem)
    + [Get the SHA-512 Hash (lowercase hex) of your client certificate (Certificate B)](#get-the-sha-512-hash-lowercase-hex-of-your-client-certificate-certificate-b)
    + [Create pkcs12 file](#create-pkcs12-file)
    + [Create nth-opt-fhir-sealed-secrets.yaml file](#create-nth-opt-fhir-sealed-secretsyaml-file)
    + [Access dsf-fhir with client certificates](#access-dsf-fhir-with-client-certificates)
      - [bundle.xml](#bundlexml)
      - [bundle.json](#bundlejson)
  * [How to prepare SSH key for codex-processes-ap1 codex-process-data-transfer process plugin](#how-to-prepare-ssh-key-for-codex-processes-ap1-codex-process-data-transfer-process-plugin)
    + [Generating a new SSH key](#generating-a-new-ssh-key)
    + [Using the new SSH key](#using-the-new-ssh-key)
  * [How to insert risk principe data to hapi fhir store](#how-to-insert-risk-principe-data-to-hapi-fhir-store)
  * [Ho to refresh `develop` from cli](#ho-to-refresh-develop-from-cli)
  * [How to renew CRR Client Certificate](#how-to-renew-crr-client-certificate)
    + [Add Certificate to https://allowlist-test.gecko.hs-heilbronn.de/](#add-certificate-to-httpsallowlist-testgeckohs-heilbronnde)
    + [Install new Allowlist](#install-new-allowlist)
  * [CloudnativePG Backup restore](#cloudnativepg-backup-restore)
- [POC](#poc)
  * [Install & Configure Nginx Ingress Controller](#install--configure-nginx-ingress-controller)
- [Contributing](#contributing)
- [License](#license)

---

### Run a test pod for debugging purpose

    kubectl run -it --rm test --image=busybox --restart=Never -- sh

### Securing Kubernetes Services with Let's Encrypt, Nginx Ingress Controller and Cert-Manager

#### Introduction

In today's landscape, securing our Kubernetes services is paramount. Let's Encrypt provides free SSL/TLS certificates, making HTTPS encryption accessible to everyone. Nginx Ingress Controller serves as a crucial component for routing traffic within our Kubernetes cluster. Cert-Manager automates the management and issuance of TLS certificates in Kubernetes. This section provides guidance on integrating Let's Encrypt, Nginx Ingress Controller, and Cert-Manager into our Kubernetes environment.

#### Configuring Let's Encrypt Issuer

Before we begin issuing certificates, we need to create an Issuer, which specifies the certificate authority from which signed x509 certificates can be obtained.
The Let’s Encrypt certificate authority offers both a staging server for testing your certificate configuration, and a production server for rolling out verifiable TLS certificates.

Let’s create a test ClusterIssuer to make sure the certificate provisioning mechanism is functioning correctly. A ClusterIssuer is not namespace-scoped and can be used by Certificate resources in any namespace.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  namespace: cert-manager
spec:
  acme:
    # Email address used for ACME registration
    email: admin@example.org
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
    name: letsencrypt-staging-issuer-account-key
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
```

Here we specify that we’d like to create a ClusterIssuer called `letsencrypt-staging`, and use the Let’s Encrypt staging server. We’ll later use the production server to roll out our certificates, but the production server rate-limits requests made against it, so for testing purposes we should use the staging URL.

We then specify an email address to register the certificate, and create a Kubernetes Secret called `letsencrypt-staging-issuer-account-key` to store the ACME account’s private key. We also use the HTTP-01 challenge mechanism. To learn more about these parameters, consult the official cert-manager documentation on Issuers.

The ClusterIssuer for the production server is defined here: [letsencrypt-prod-cluster-issuer.yaml](charts/cert-manager/templates/letsencrypt-prod-cluster-issuer.yaml).

#### Cert-Manager and Ingress

To request TLS signed certificates we annotations to our Ingress resources and cert-manager will facilitate creating the Certificate resource for us. A small sub-component of cert-manager, ingress-shim, is responsible for this. Ingress-shim watches Ingress resources across our cluster. If it observes an Ingress with

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-staging
```

Ingress-shim will ensure a Certificate resource with the name provided in the `tls.secretName` field and configured as described on the Ingress exists in the Ingress's namespace.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
name: victoria-logs-ingress
namespace: victoria-logs
annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
    ingressClassName: nginx
    rules:
    - host: logs.example.org
        http:
        paths:
        - backend:
            service:
                name: victoria-logs
                port:
                number: 9428
            path: /
            pathType: Prefix
    tls:
    - hosts:
        - logs.example.org
        secretName: victoria-logs-letsencrypt-staging-tls
```

When the Certificate resource has conditions like

    kubectl describe certificate victoria-logs-letsencrypt-prod-tls

    ...

    Conditions:
        Last Transition Time:  2024-03-02T13:29:51Z
        Message:               Certificate is up to date and has not expired
        Observed Generation:   1
        Reason:                Ready
        Status:                True
        Type:                  Ready

    ...

everything look fine and we can switch to the production issuer.

#### Conclusion

In conclusion, the integration of Let's Encrypt, Nginx Ingress Controller, and Cert-Manager offers a robust solution for securing Kubernetes services with SSL/TLS certificates. By following the steps outlined in this guide, we have established a reliable mechanism for automating the issuance and management of certificates within our Kubernetes environment.

The configuration of Let's Encrypt Issuer, whether in a staging or production environment, ensures that our certificates are obtained securely and efficiently. Through the use of ClusterIssuers and Ingress annotations, we have streamlined the process of requesting and managing TLS certificates for our services.

The ability to monitor the status of certificates using commands like `kubectl describe certificate` allows us to ensure that our certificates are up to date and valid, providing peace of mind regarding the security of our services.

As we transition from testing with the staging server to the production environment, we can confidently deploy our applications knowing that they are protected by industry-standard encryption protocols. This approach not only enhances the security posture of our Kubernetes cluster but also simplifies the management of SSL/TLS certificates, ultimately contributing to a more resilient and secure infrastructure.

#### Sources

- [Annotated Ingress resource](https://cert-manager.io/docs/usage/ingress/)
- [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes)

### Securing Kubernetes Services with Ingress-Nginx Controller and Basic Authentication

After setting up HTTPS for our Kubernetes Services it is file to use Basic Authentication to control access to them. I order to set up Basic Authentication we will do the following steps:

- Create htpasswd file
- Convert auth file into a sealed secret
- Create an ingress tied to the basic-auth secret
- Use curl to confirm authorization is required by the ingress
- Use curl with the correct credentials to connect to the ingress

#### Create htpasswd file

For the htpasswd file file, we nedd a username and a password. We generate them by using this helm template

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth-generated-secret
  annotations:
    argocd.argoproj.io/sync-options: "Delete=false"
type: Opaque
data:
  username: { { printf "%s-%s" "u" (randAlphaNum 16) | b64enc | quote } }
  password: { { printf "%s-%s" "p" (randAlphaNum 32) | b64enc | quote } }
```

When using argocd, each time, arrgocd syncs the status, new username and passwords are generated.
So we backup the generated username and password in an generic `basic-auth-input` Secret.

```sh
export USERNAME=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.username}" | base64 -d)
export PASSWORD=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.password}" | base64 -d)

kubectl create secret generic basic-auth-input --from-literal=username="$USERNAME" --from-literal=password="$PASSWORD"

echo user: "$USERNAME" password: "$PASSWORD"
```

To create the htpasswd file `auth`, we run

```sh
htpasswd -bc auth "$USERNAME" "$PASSWORD"
```

#### Convert auth file into a sealed secret

We do not want to leak the username in this public repo, so we create a sealed secret to store the auth file:

```sh
kubectl create secret generic basic-auth --from-file=auth -o yaml --dry-run=client | kubeseal  --scope cluster-wide -o yaml > basic-auth-sealed-secret.yaml
```

And update our repo:

```sh
git add basic-auth-sealed-secret.yaml
git commit -m "modified basic-auth-sealed-secret.yaml"
git push
```

After syncing with argo-cd, the sealed-secrets-controller decrypts the sealed-secret into the `basic-auth` secret.

#### Create an ingress tied to the basic-auth secret

To use the basic auth file, we need to annotate the ingress like:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
name: ingress-with-auth
annotations:
  # type of authentication
  nginx.ingress.kubernetes.io/auth-type: basic
  # name of the secret that contains the user/password definitions
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  # message to display with an appropriate context why the authentication is required
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

#### Use curl to confirm authorization is required by the ingress

```sh
curl -Lv logs.rdp-dev.ingress.k8s.highmed.org

*   Trying 134.76.15.219:80...
* Connected to logs.rdp-dev.ingress.k8s.highmed.org (134.76.15.219) port 80
> GET / HTTP/1.1
> Host: logs.rdp-dev.ingress.k8s.highmed.org
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/1.1 308 Permanent Redirect
< Date: Mon, 04 Mar 2024 09:53:50 GMT
< Content-Type: text/html
< Content-Length: 164
< Connection: keep-alive
< Location: https://logs.rdp-dev.ingress.k8s.highmed.org
<
* Ignoring the response-body
* Connection #0 to host logs.rdp-dev.ingress.k8s.highmed.org left intact
* Clear auth, redirects to port from 80 to 443
* Issue another request to this URL: 'https://logs.rdp-dev.ingress.k8s.highmed.org/'
*   Trying 134.76.15.219:443...
* Connected to logs.rdp-dev.ingress.k8s.highmed.org (134.76.15.219) port 443
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
*  CAfile: /etc/ssl/cert.pem
*  CApath: none
* (304) (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=logs.rdp-dev.ingress.k8s.highmed.org
*  start date: Mar  2 12:29:50 2024 GMT
*  expire date: May 31 12:29:49 2024 GMT
*  subjectAltName: host "logs.rdp-dev.ingress.k8s.highmed.org" matched cert's "logs.rdp-dev.ingress.k8s.highmed.org"
*  issuer: C=US; O=Let's Encrypt; CN=R3
*  SSL certificate verify ok.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://logs.rdp-dev.ingress.k8s.highmed.org/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: logs.rdp-dev.ingress.k8s.highmed.org]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.4.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: logs.rdp-dev.ingress.k8s.highmed.org
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/2 401
< date: Mon, 04 Mar 2024 09:53:51 GMT
< content-type: text/html
< content-length: 172
< www-authenticate: Basic realm="Authentication Required"
< strict-transport-security: max-age=15724800; includeSubDomains
<
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #1 to host logs.rdp-dev.ingress.k8s.highmed.org left intact
```

#### Use curl with the correct credentials to connect to the ingress

```sh
export USERNAME=$(kubectl get secret basic-auth-input -o jsonpath="{.data.username}" | base64 -d)
export PASSWORD=$(kubectl get secret basic-auth-input -o jsonpath="{.data.password}" | base64 -d)

curl -vu "$USERNAME:$PASSWORD" https://logs.rdp-dev.ingress.k8s.highmed.org

*   Trying 134.76.15.219:443...
* Connected to logs.rdp-dev.ingress.k8s.highmed.org (134.76.15.219) port 443
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
*  CAfile: /etc/ssl/cert.pem
*  CApath: none
* (304) (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=logs.rdp-dev.ingress.k8s.highmed.org
*  start date: Mar  2 12:29:50 2024 GMT
*  expire date: May 31 12:29:49 2024 GMT
*  subjectAltName: host "logs.rdp-dev.ingress.k8s.highmed.org" matched cert's "logs.rdp-dev.ingress.k8s.highmed.org"
*  issuer: C=US; O=Let's Encrypt; CN=R3
*  SSL certificate verify ok.
* using HTTP/2
* Server auth using Basic with user 'u-****************'
* [HTTP/2] [1] OPENED stream for https://logs.rdp-dev.ingress.k8s.highmed.org/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: logs.rdp-dev.ingress.k8s.highmed.org]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [authorization: Basic dS0qKioqKioqKioqKioqKioqCg==]
* [HTTP/2] [1] [user-agent: curl/8.4.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: logs.rdp-dev.ingress.k8s.highmed.org
> Authorization: Basic dS0qKioqKioqKioqKioqKioqCg==
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/2 200
< date: Mon, 04 Mar 2024 10:01:53 GMT
< content-type: text/html; charset=utf-8
< content-length: 365
< vary: Accept-Encoding
< x-server-hostname: victoria-logs-victoria-logs-single-server-0
< strict-transport-security: max-age=15724800; includeSubDomains
<
* Connection #0 to host logs.rdp-dev.ingress.k8s.highmed.org left intact
<h2>Single-node VictoriaLogs</h2></br>See docs at <a href='https://docs.victoriametrics.com/VictoriaLogs/'>https://docs.victoriametrics.com/VictoriaLogs/</a></br>Useful endpoints:</br><a href="select/vmui">select/vmui</a> - Web UI for VictoriaLogs<br/><a href="metrics">metrics</a> - available service metrics<br/><a href="flags">flags</a> - command-line flags<br/>
```

#### Sources

- [Basic Authentication](https://kubernetes.github.io/ingress-nginx/examples/auth/basic/)

### Using VictoriaLogs with Web UI

VictoriaLogs provides a simple Web UI for logs querying and exploration at [vmui](https://logs.rdp-dev.ingress.k8s.highmed.org/select/vmui). The UI is basic auth protected and you need a valid username and password.

```sh
echo username: $(kubectl get secret basic-auth-input -n victoria-logs -o jsonpath="{.data.username}" | base64 -d)
echo password: $(kubectl get secret basic-auth-input -n victoria-logs -o jsonpath="{.data.password}" | base64 -d)
```

After you log in enter a log query e.q. `_time:5m` and press the `Execute Query` button.

There are three modes of displaying query results:

- Group - results are displayed as a table with rows grouped by stream and fields for filtering.
- Table - displays query results as a table.
- JSON - displays raw JSON response from HTTP API.

This is the first version that has minimal functionality. It comes with the following limitations:

- The number of query results is always limited to 1000 lines. Iteratively add more specific filters to the query in order to get full response with less than 1000 lines.
- Queries are always executed against tenant 0.

These limitations will be removed in future versions.
To get around the current limitations, you can use an alternative - the command line interface.

See also:

- [Key concepts](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html).
- [LogsQL docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html).

### Using VictoriaLogs from the command line

VictoriaLogs integrates well with `curl` and other command-line tools during querying because of the following features:

- VictoriaLogs sends the matching log entries to the response stream as soon as they are found.
  This allows forwarding the response stream to arbitrary [Unix pipes](<https://en.wikipedia.org/wiki/Pipeline_(Unix)>).
- VictoriaLogs automatically adjusts query execution speed to the speed of the client, which reads the response stream.
  For example, if the response stream is piped to `less` command, then the query is suspended
  until the `less` command reads the next block from the response stream.
- VictoriaLogs automatically cancels query execution when the client closes the response stream.
  For example, if the query response is piped to `head` command, then VictoriaLogs stops executing the query
  when the `head` command closes the response stream.

These features allow executing queries at command-line interface, which potentially select billions of rows,
without the risk of high resource usage (CPU, RAM, disk IO) at VictoriaLogs server.

For example, the following query can return very big number of matching log entries (e.g. billions) if VictoriaLogs contains
many log messages with the `error` [word](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#word):

```sh
export USERNAME=$(kubectl get secret basic-auth-input -n victoria-logs -o jsonpath="{.data.username}" | base64 -d)
export PASSWORD=$(kubectl get secret basic-auth-input -n victoria-logs -o jsonpath="{.data.password}" | base64 -d)
export QUERY_URL="https://logs.rdp-dev.ingress.k8s.highmed.org/select/logsql/query"

curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=error'
```

If the command returns "never-ending" response, then just press `ctrl+C` at any time in order to cancel the query.
VictoriaLogs notices that the response stream is closed, so it cancels the query and instantly stops consuming CPU, RAM and disk IO for this query.

Then just use `head` command for investigating the returned log messages and narrowing down the query:

```sh
curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=error' | head -10
```

The `head -10` command reads only the first 10 log messages from the response and then closes the response stream.
This automatically cancels the query at VictoriaLogs side, so it stops consuming CPU, RAM and disk IO resources.

Sometimes it may be more convenient to use `less` command instead of `head` during the investigation of the returned response:

```sh
curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=error' | less
```

The `less` command reads the response stream on demand, when the user scrolls down the output.
VictoriaLogs suspends query execution when `less` stops reading the response stream.
It doesn't consume CPU and disk IO resources during this time. It resumes query execution
when the `less` continues reading the response stream.

Suppose that the initial investigation of the returned query results helped determining that the needed log messages contain
`cannot open file` [phrase](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#phrase-filter).
Then the query can be narrowed down to `error AND "cannot open file"`
(see [these docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#logical-filter) about `AND` operator).
Then run the updated command in order to continue the investigation:

```sh
curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=error AND "cannot open file"' | head
```

Note that the `query` arg must be properly encoded with [percent encoding](https://en.wikipedia.org/wiki/URL_encoding) when passing it to `curl`
or similar tools.

The `pipe the query to "head" or "less" -> investigate the results -> refine the query` iteration
can be repeated multiple times until the needed log messages are found.

The returned VictoriaLogs query response can be post-processed with any combination of Unix commands,
which are usually used for log analysis - `grep`, `jq`, `awk`, `sort`, `uniq`, `wc`, etc.

For example, the following command uses `wc -l` Unix command for counting the number of log messages
with the `error` [word](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#word)
received from [streams](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#stream-fields) with `app="nginx"` field
during the last 5 minutes:

```sh
curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=_stream:{app="nginx"} AND _time:5m AND error' | wc -l
```

See [these docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#stream-filter) about `_stream` filter,
[these docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#time-filter) about `_time` filter
and [these docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#logical-filter) about `AND` operator.

The following example shows how to sort query results by the [`_time` field](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#time-field):

```sh
curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=error' | jq -r '._time + " " + ._msg' | sort | less
```

This command uses `jq` for extracting [`_time`](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#time-field)
and [`_msg`](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#message-field) fields from the returned results,
and piping them to `sort` command.

Note that the `sort` command needs to read all the response stream before returning the sorted results. So the command above
can take non-trivial amounts of time if the `query` returns too many results. The solution is to narrow down the `query`
before sorting the results. See [these tips](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#performance-tips)
on how to narrow down query results.

The following example calculates stats on the number of log messages received during the last 5 minutes
grouped by `log.level` [field](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#data-model):

```sh
curl -u "$USERNAME:$PASSWORD" "$QUERY_URL" -d 'query=_time:5m log.level:*' | jq -r '."log.level"' | sort | uniq -c
```

The query selects all the log messages with non-empty `log.level` field via ["any value" filter](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html#any-value-filter),
then pipes them to `jq` command, which extracts the `log.level` field value from the returned JSON stream, then the extracted `log.level` values
are sorted with `sort` command and, finally, they are passed to `uniq -c` command for calculating the needed stats.

See also:

- [Key concepts](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html).
- [LogsQL docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html).

### How to disable DEV dsf-bpe on CODEX cluster

- checkout the [num-helm-charts](https://github.com/NUM-Forschungsdatenplattform/num-helm-charts) repository
- in `deployment-values/central-research-repository/development-values.yaml` change `dsfBpe.enabled` to `false`
- in `Chart.yaml` increase `version` number, for example, from `0.4.241` to `0.4.242`
- check your changes with `git diff`
- commit your changes with `git commit -am "NUM-109: disable dsf-bpe on dev"`
- push your changes with `git push`
- set namespace with `kubens central-research-repository-development`
- diff helm chart with current k8s state `helm template --is-upgrade num . -f deployment-values/central-research-repository/development-values.yaml --dry-run | kubectl diff -f -`
- **CHECK THE DIFF**
- deploy your changes with `helm upgrade --install -f deployment-values/central-research-repository/development-values.yaml num .`
- check helm output to ensure that there were no errors during deployment. Look for any warnings or errors that might indicate issues with the deployment process.

```sh
Release "num" has been upgraded. Happy Helming!
NAME: num
LAST DEPLOYED: Fri Mar 15 15:49:45 2024
NAMESPACE: central-research-repository-development
STATUS: deployed
REVISION: 103
TEST SUITE: None
```

- Use `kubectl get pods -n central-research-repository-development` to monitor the status of the pods in the namespace where your application is deployed. Make sure that `dsf-bpe` pod was terminated.

### How to test DEV fhir-bridge on CODEX cluster

To test a fhir-bridge we do the following steps:

- count COMPOSITIONs in ehrbase
- add one Observation to fhir-bridge
- count COMPOSITIONs in ehrbase
- compair the number of COMPOSITIONs in ehrbase. They must have increased

If you like `Postman`, please use this [config](https://github.com/NUM-Forschungsdatenplattform/num-fhir-bridge/tree/main/config/postman).

#### Count COMPOSITIONs in ehrbase

- use `kubectl` or `k9s` to port-forward the ehrbase HTTP port to `localhost:8080`
- get username and password for basic auth from the [deployment values in num-helm-charts](https://github.com/NUM-Forschungsdatenplattform/num-helm-charts/blob/main/deployment-values/central-transactional-repository/development-values.yaml) and export them to your ENV like `export USERNAME='karl'` and `export PASSWORD='leiser'`
- use the this `curl` command:

```
curl -s \
    -XPOST \
    -u "$USERNAME:$PASSWORD" \
    -H 'Content-Type: application/json' \
    -d '{"q":"SELECT count(c) FROM EHR e CONTAINS COMPOSITION c"}' \
    http://localhost:8080/ehrbase/rest/openehr/v1/query/aql \
    | jq .rows[0][0]
```

#### Add one Observation to fhir-bridge

- use `kubectl` or `k9s` to port-forward the ehrbase HTTP port to `localhost:8888`.
- use the this `curl` command:

```
curl -s \
    -XPOST \
    -H 'Content-Type: application/json' \
    -d @./test/fhir-bridge/provide-observation.json \
    http://localhost:8888/fhir-bridge/fhir/Observation \
    | jq .status
```

The curl output should be `"final"`.

### How to dump dev keycloak db on CODEX cluster

Describe the pod `num-keycloak-0` in `central-research-repository-development` namespace.
In the env-vars for the keycloak container you will find something like `KC_DB_URL_HOST: acid-keycloak-development.development-postgres-cluster`.
So the database service is called `acid-keycloak-development` in the `development-postgres-cluster` namespace.
Exec a shell for the pod `acid-keycloak-development-0` the run the commands

```
su postgres -
psql
\l
\q
cd /tmp
pg_dump -d keycloak > keycloak_dump.sql
gzip keycloak_dump.sql
```

Then copy `the keycloak_dump.sql` to your local machine:

```
kubectl cp development-postgres-cluster/acid-keycloak-development-0:/tmp/keycloak_dump.sql.gz Downloads/keycloak_dump.sql.gz
```

### How to import dump of dev keycloak db on dev cluster

Then copy `the keycloak_dump.sql` to db pod:

```
kubectl cp keycloak_dump.sql.gz dev/num-portal-postgres-0:/tmp/keycloak_dump.sql.gz
```

In the db pod:

```
su postgres -
psql
\l
drop database  keycloak;
create database  keycloak;
\q
cd /tmp
pg_dump -d keycloak > keycloak_dump-backup.sql
gunzip keycloak_dump.sql.gz
psql -d keycloak -f keycloak_dump.sql
```

### How to setup the develop environment

#### Rollout new environment

- copy a working values file to `develop-values.yaml` in `num-helm-charts/central-research-repository/deployment-values`
- replace URLs to match `develop`
- in `values.yaml` of `num-ops-guide/charts/app-of-app` under `applications` add link to `develop-values.yaml`

```yaml
developEnv:
  enabled: true
  namespace: develop
  helmValueFile: deployment-values/central-research-repository/develop-values.yaml
```

- wait, until argo has deployed the `develop` environment

#### Configure keycloak

- copy a working values file to `develop-rdp-dev.yaml` in `keycloak-configurations/vars/central-research-repository`
- replace URLs to match `develop`
- run `ansible-playbook playbooks/master_playbook.yml --extra-vars "@vars/central-research-repository/develop-rdp-dev.yaml` to setup clients and roles.
- create a user and 'Set User-Specifications' in [keycloak](https://keycloak.develop.dev.num-rdp.de/auth) as described in [Lokale_Umgebung](https://github.com/NUM-Forschungsdatenplattform/num-crr-documentation/blob/main/documentation/3_Lokale_Umgebung/local_environment.md)
- save the keycloak_User_ID

#### Configure num-portal

- use `pgadmin` or `psql` to insert an organization and the user into the numportal db.

```sql
INSERT INTO num.organization(id, name, description, active)
       VALUES (1, 'Orga', 'description', true);
INSERT INTO num.user_details(user_id, approved, organization_id, created_date)
       VALUES ('<keycloak_User_ID>', true, 1, CURRENT_DATE);
```

- kill the num-portal pod

#### test login

- login with the user at: https://develop.dev.num-rdp.de

### How to get certs for DSF

The `sertigo` clusterIssuer can get certs for the `highmed.org` domain. To get a valid certificate for a fhir host in use an ingress like:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: sertigo
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  name: dsf-fhir
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: dsf-fhir.test.rdp-dev.ingress.k8s.highmed.org
      http:
        paths:
          - backend:
              service:
                name: web
                port:
                  number: 8080
            path: /
            pathType: Prefix
  tls:
    - hosts:
        - dsf-fhir.test.rdp-dev.ingress.k8s.highmed.org
      secretName: dsf-fhir-certificate
```

### How to prepare certs for DSF

See: https://dsf.dev/stable/maintain/install.html#dsf-fhir-server

#### Store PEM encoded certificate as ssl_certificate_file.pem

    kubectl get secret dsf-fhir-certificate -o jsonpath='{.data.tls\.crt}' | base64 -d > ssl_certificate_file.pem

#### Store unencrypted, PEM encoded private-key as ssl_certificate_key_file.pem

    kubectl get secret dsf-fhir-certificate -o jsonpath='{.data.tls\.key}‘ | base64 -d > ssl_certificate_key_file.pem

#### Store PEM encoded certificate as client_certificate.pem

    kubectl get secret dsf-bpe-certificate -o jsonpath='{.data.tls\.crt}' | base64 -d > client_certificate.pem

#### Store encrypted or not encrypted, PEM encoded private-key as client_certificate_private_key.pem

    kubectl get secret dsf-bpe-certificate -o jsonpath='{.data.tls\.key}' | base64 -d > client_certificate_private_key.pem

#### Get the SHA-512 Hash (lowercase hex) of your client certificate (Certificate B)

Copy the first cert to `client_certificate-1.pem`.

    certtool --fingerprint --hash=sha512 --infile=client_certificate-1.pem

    0dabd48c1dff128149d21b7839ad62b97e3c56ae04878f6a9043341fd355bf5d08ae21a782b6370b14e9e87780ca35278182f119bbc5c17d5aa0ab0771c83897

or

    openssl x509 -fingerprint -sha512 -in client_certificate.pem
    sha512 Fingerprint=0D:AB:D4:8C:1D:FF:12:81:49:D2:1B:78:39:AD:62:B9:7E:3C:56:AE:04:87:8F:6A:90:43:34:1F:D3:55:BF:5D:08:AE:21:A7:82:B6:37:0B:14:E9:E8:77:80:CA:35:27:81:82:F1:19:BB:C5:C1:7D:5A:A0:AB:07:71:C8:38:97

#### Create pkcs12 file

    openssl pkcs12 -export -out client_certificate.p12 -inkey client_certificate_private_key.pem -in client_certificate.pem

#### Create nth-opt-fhir-sealed-secrets.yaml file

```sh
kubectl create secret generic nth-opt-fhir-secrets \
    --from-file=ssl_certificate_file.pem \
    --from-file=ssl_certificate_key_file.pem \
    --from-file=client_certificate.pem \
    --from-file=client_certificate_private_key.pem \
    --dry-run=client -o yaml -n develop \
    | kubeseal - -w nth-opt-fhir-sealed-secrets.yaml
```

#### Access dsf-fhir with client certificates

    curl -v --cert-type P12 --cert client_certificate.p12  -H "Accept: application/fhir+xml" https://dsf-fhir.test.rdp-dev.ingress.k8s.highmed.org/fhir/Endpoints

or

    curl -v --cert client_certificate.pem --key client_certificate_private_key.pem -H "Accept: application/fhir+xml" https://dsf-fhir.test.rdp-dev.ingress.k8s.highmed.org/fhir/Endpoint

##### [bundle.xml](/docs/assets/bundle.xml)

to parse json

```sh
curl -s --cert client_certificate.pem --key client_certificate_private_key.pem  -H "Accept: application/json" https://dsf-fhir.test.rdp-dev.ingress.k8s.highmed.org/fhir/Endpoint | jq .
```

##### [bundle.json](/docs/assets/bundle.json)

### How to prepare SSH key for codex-processes-ap1 codex-process-data-transfer process plugin

Data for the plugin must be encrypted using a rsa 4096 key pair.
The puclic key should be found on the web page.

#### Generating a new SSH key

    openssl genrsa -out crr-private-key.pem 4096 && openssl rsa -pubout -in crr-private-key.pem -out crr-public-key.pem

This will also generate the public key `crr-public-key.pem`.
Now create a k8s secret file with:

    kubectl create secret generic crr-private-key --from-file=crr-private-key.pem -n test -o yaml > crr-private-key-secret.yaml

To seal the secret call:

    kubeseal -f crr-private-key-secret.yaml -w crr-private-key-sealed-secret.yaml

Add the `crr-private-key` and `crr-private-key-secret.yaml` files to .gitignore

    echo crr-private-key >> .gitignore
    echo crr-private-key-secret.yaml >> .gitignore

Add `.gitignore`, `crr-private-key.pem` and the `crr-private-key-sealed-secret.yaml` to git:

    git add .gitignore
    git add crr-private-key.pem
    git add crr-private-key-sealed-secret.yaml

#### Using the new SSH key

In the deployment of DSF-BPE there is an env var `DE_NETZWERK_UNIVERSITAETSMEDIZIN_RDP_CRR_PRIVATE_KEY` which contains the value of "{{ .Values.appConfig.privateKey.path }}".

So add a secret volume

```yaml
volumes:
  - name: crr-private-key
    secret:
      secretName: "crr-private-key"
      items:
        - key: "crr-private-key"
          path: "crr-private-key"
```

and mount it

```yaml
volumeMounts:
  - name: crr-private-key
    mountPath: "{{ .Values.appConfig.privateKey.path }}"
    subPath: crr-private-key
```

### How to insert risk principe data to hapi fhir store

- get the test data

```
wget https://raw.githubusercontent.com/num-codex/codex-processes-ap1/main/codex-process-data-transfer/src/test/resources/fhir/Bundle/dic_fhir_store_demo_risk_principe.json
```

- port foreward to localhost:8080

- post to the FHIR server

```sh
curl \
    -XPOST -L \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d @dic_fhir_store_demo_risk_principe.json http://localhost:8080/fhir | jq .
```

- replace dic-pseudonym

```json
{
  "resourceType": "Bundle",
  "id": "46e9ee38-b83a-4e48-87ff-ed7e06d3caac",
  "meta": {
    "lastUpdated": "2024-11-28T08:21:47.627+00:00"
  },
  "type": "searchset",
  "total": 1,
  "link": [
    {
      "relation": "self",
      "url": "http://localhost:8080/fhir/Patient?_pretty=true"
    }
  ],
  "entry": [
    {
      "fullUrl": "http://localhost:8080/fhir/Patient/1",
      "resource": {
        "resourceType": "Patient",
        "id": "1",
        "meta": {
          "versionId": "6",
          "lastUpdated": "2024-09-02T08:10:06.995+00:00",
          "source": "#5NzeIQNOkqWHraNA",
          "profile": [
            "https://www.medizininformatik-initiative.de/fhir/core/modul-person/StructureDefinition/PatientPseudonymisiert"
          ]
        },
        "identifier": [
          {
            "type": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-ObservationValue",
                  "code": "PSEUDED"
                }
              ]
            },
            "system": "urn:ietf:rfc:4122",
            "value": "07f602e0-579e-4fe3-95af-381728b00015"
          },
          {
            "type": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
                  "code": "ANON"
                }
              ]
            },
            "system": "http://www.netzwerk-universitaetsmedizin.de/sid/dic-pseudonym",
            "value": "dic_crr_test/dic_E6AXT"
          }
        ],
        "gender": "other",
        "_gender": {
          "extension": [
            {
              "url": "http://fhir.de/StructureDefinition/gender-amtlich-de",
              "valueCoding": {
                "system": "http://fhir.de/CodeSystem/gender-amtlich-de",
                "code": "D",
                "display": "divers"
              }
            }
          ]
        },
        "birthDate": "2022-12-01",
        "managingOrganization": {
          "identifier": {
            "system": "https://www.medizininformatik-initiative.de/fhir/core/CodeSystem/core-location-identifier",
            "value": "MHH"
          }
        }
      },
      "search": {
        "mode": "match"
      }
    }
  ]
}
```

### Ho to refresh `develop` from cli

```bash
argocd login argocd.dev.num-rdp.de
argocd app get argo/develop --refresh
```

### How to renew CRR Client Certificate

The client certificate is the DSF BPE certificate.
It is stored in the `dsf-bpe-certificate` k8s secret.
The secret has the data fields `tls.crt` and `tls.key`.
For the stages `pre-pro` and `production`, the current certificates are valid until `2025-12-05`.
the renewal time is `2025-08-05`.

After the content of the `dsf-bpe-certificate` changed, the deployment values for the `dsf-fhir` need the new `thumbprint` for the certificate.

You can get the new `thumbprint` value from the dsf-fhir log file.

#### Add Certificate to https://allowlist-test.gecko.hs-heilbronn.de/

After login to https://allowlist-test.gecko.hs-heilbronn.de/, click on `Certificates` and `Add Organization Certificate`. Add the contents of the `tls.crt` in to the `Certificate PEM` input field and click on `Save`.
Then click on `Send Request for Approval`.

#### Install new Allowlist

When your request was approved, follow the instuctions after ckicking on the `Download Allow List` button.

### CloudnativePG Backup restore

To restore a backup from cloudnativepg you have to deploy the following Cluster.
This Example is for the ehrshow postgres-db

After the new cluster is deployed the backup process is started. This takes some time. If its finished the new Cluster will be deployed.

```helm
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ehrshow
spec:
  instances: 1
  bootstrap:
    recovery:
      source: ehrshow
  postgresql:
    parameters:
      archive_timeout: 10min
  monitoring:
    enablePodMonitor: true
  storage:
    storageClass: ssd
    size: 1Gi
  backup:
    retentionPolicy: 30d
    barmanObjectStore:
      # this is the cluster-name for the new backup, should be different to the cluster to restore, because the backup would be replaced
      destinationPath: s3://codex-postgres-backup/cloudnative-pg/ehrshow-recovered
      endpointURL: https://s3.fs.gwdg.de
      s3Credentials:
        accessKeyId:
          name: s3-credentials
          key: accessKeyId
        secretAccessKey:
          name: s3-credentials
          key: secretAccessKey
  externalClusters:
    - name: ehrshow
      barmanObjectStore:
        # this is the cluster to restore
        destinationPath: s3://codex-postgres-backup/cloudnative-pg/ehrshow
        endpointURL: https://s3.fs.gwdg.de
        s3Credentials:
          accessKeyId:
            name: s3-credentials
            key: accessKeyId
          secretAccessKey:
            name: s3-credentials
            key: secretAccessKey
```

## POC

### Install & Configure Nginx Ingress Controller

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.config.allow-snippet-annotations=true \
  --set controller.config.use-forwarded-headers=true
```


## Contributing

Contributions are welcome! If you find issues, have suggestions, or want to contribute enhancements, please check our [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).

Happy NUM operations!
