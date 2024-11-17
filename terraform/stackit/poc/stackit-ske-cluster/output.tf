output "kubeversion" {
   description = "K8s-Version used"
   value       = stackit_ske_cluster.k8scluster1.kubernetes_version_used
}
output "kubeconfig" {
   description = "Kubeconfig"
   value       = stackit_ske_kubeconfig.k8scluster1.kube_config
   sensitive = true
}
