resource "stackit_ske_kubeconfig" "this" {
  project_id   = var.project_id
  cluster_name = var.cluster_name
  refresh      = true
  expiration   = 3 * 30 * 24 * 60 * 60

  depends_on = [stackit_ske_cluster.this]
}
