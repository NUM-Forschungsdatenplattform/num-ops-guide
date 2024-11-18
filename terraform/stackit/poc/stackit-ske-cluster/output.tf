output "kubeversion" {
  description = "kubernetes version used"
  value       = stackit_ske_cluster.this.kubernetes_version_used
}

output "kubeconfig" {
  description = "kubeconfig used to connect to the cluster"
  value       = stackit_ske_kubeconfig.this.kube_config
  sensitive   = true
}
