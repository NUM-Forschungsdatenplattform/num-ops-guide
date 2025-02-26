## Getting Started

Before diving into Kubernetes operations, make sure you have the necessary prerequisites installed. Consult the [official Kubernetes documentation](https://kubernetes.io/docs/setup/) for guidance on setting up `kubectl` for managing the Kubernetes cluster.

For local developement you can use [colima](https://github.com/abiosoft/colima).
To startup a k8s cluster, that matches the current prod env simply run:

    colima start --cpu 4 --memory 8 --arch x86_64 --kubernetes --kubernetes-version v1.24.6+k3s1

