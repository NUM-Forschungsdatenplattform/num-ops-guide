variable "project_id" {
  type        = string
  description = "Project ID"
  default     = "8219b75a-0385-4aa0-b014-c8e521d031db"
}

variable "cluster_name" {
  type        = string
  description = "Cluster Name"
  default     = "poc"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu01-1", "eu01-2", "eu01-3"]
}

