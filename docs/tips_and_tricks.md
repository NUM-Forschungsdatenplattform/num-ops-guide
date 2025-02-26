## Tips and Tricks

### VictoriaLogs: Useful query strings

- Log the errors from the last 5 minutes:

  `_time:5m error`

- Log the output a given namespace:

  `_stream:{k8s_ns="develop"}`

- Log errors from a container in a given namespace from the last 12 hours:

  `_time:12h _stream:{k8s_ns="develop",k8s_container="num-portal"} error`

### kubectl: Useful Aliases

- Use `k` short cut for `kubectl`:

  `alias k='kubectl'`

- Switch contexts:

  This will switch to the `codex-central` context and list all the nodes.

  `alias kcodex='kubectl config use-context codex-central && kubectl get nodes'`

  `alias   kdev='kubectl config use-context rdp-dev       && kubectl get nodes'`

