resource "stackit_observability_instance" "this" {
  project_id = var.project_id
  name       = "observability"
  plan_name  = "Observability-Starter-EU01"
  acl        = ["0.0.0.0/0"] # adjust
}
