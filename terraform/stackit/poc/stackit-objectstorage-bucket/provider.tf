terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "0.34.0"
    }
  }
}
provider "stackit" {
  region = "eu01"
}
