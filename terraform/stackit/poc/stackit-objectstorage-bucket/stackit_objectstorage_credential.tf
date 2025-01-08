resource "stackit_objectstorage_credential" "this" {
  project_id           = var.project_id
  credentials_group_id = stackit_objectstorage_credentials_group.this.credentials_group_id
  expiration_timestamp = "2026-01-01T00:00:00Z"
  depends_on           = [stackit_objectstorage_credentials_group.this]
}

resource "stackit_objectstorage_credential" "neu" {
  project_id           = var.project_id
  credentials_group_id = stackit_objectstorage_credentials_group.this.credentials_group_id
  expiration_timestamp = "2026-01-01T00:00:00Z"
  depends_on           = [stackit_objectstorage_credentials_group.this]
}
