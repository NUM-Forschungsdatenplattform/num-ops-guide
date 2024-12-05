resource "stackit_objectstorage_bucket" "this" {
  project_id = var.project_id
  name       = var.bucket_name
}
