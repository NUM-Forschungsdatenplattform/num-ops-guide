resource "stackit_objectstorage_credentials_group" "this" {
  project_id = var.project_id
  name       = "credentials-group"
}
