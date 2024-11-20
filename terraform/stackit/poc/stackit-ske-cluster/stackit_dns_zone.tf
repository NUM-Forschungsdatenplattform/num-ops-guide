resource "stackit_dns_zone" "this" {
  project_id = var.project_id
  name       = "highmed"
  dns_name   = "highmed.runs.onstackit.cloud"
}
