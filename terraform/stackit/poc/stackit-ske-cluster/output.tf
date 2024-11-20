output "kubeversion" {
  description = "kubernetes version used"
  value       = stackit_ske_cluster.this.kubernetes_version_used
}

output "kubeconfig" {
  description = "kubeconfig used to connect to the cluster"
  value       = stackit_ske_kubeconfig.this.kube_config
  sensitive   = true
}

output "grafana_initial_admin_user" {
  description = "initial admin user for grafana"
  value       = stackit_observability_instance.this.grafana_initial_admin_user
  sensitive   = true
}

output "grafana_initial_admin_password" {
  description = "initial admin password for grafana"
  value       = stackit_observability_instance.this.grafana_initial_admin_password
  sensitive   = true
}

output "zone_id" {
  description = "highmed dns zone id"
  value       = stackit_dns_zone.this.zone_id
}
