terraform {
  required_providers {
    stackit = {
      source = "stackitcloud/stackit"
      version = "0.30.1"
    }
  }
}

provider "stackit" {
  # Configuration options
  region = "eu01"
  service_account_key_path = "./key/sa_key.json" # created via portal -> ServiceAccount -> ServiceAccountKeys - after that give service account permissions in permissions menue
}
