
output "s3_url" {
  description = "s3 url"
  value       = stackit_objectstorage_bucket.this.url_path_style
}

output "s3_name" {
  description = "s3 name"
  value       = stackit_objectstorage_credential.this.name
}

output "s3_access_key" {
  description = "s3 access key"
  value       = stackit_objectstorage_credential.this.access_key
}

output "s3_secret_access_key" {
  description = "s3 secret accesskey"
  value       = stackit_objectstorage_credential.this.secret_access_key
  sensitive   = true
}

