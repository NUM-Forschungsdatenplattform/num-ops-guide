resource "stackit_ske_kubeconfig" "this" {
  project_id   = var.PROJECTID
  cluster_name = var.CLUSTERNAME
  refresh      = true
  expiration   = 3600

  depends_on = [stackit_ske_cluster.this]
}
