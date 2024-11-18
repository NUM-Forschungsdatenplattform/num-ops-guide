# Define the node_pools
locals {
  node_pools = [
    for zone in var.availability_zones : {
      name               = "node-pool-${zone}"
      machine_type       = "g2i.2"
      volume_size        = 50
      minimum            = "1"
      maximum            = "2"
      max_surge          = "1"
      availability_zones = [zone]
    }
  ]
}

resource "stackit_ske_cluster" "this" {
  project_id = var.project_id
  name       = var.cluster_name
  node_pools = local.node_pools

  hibernations = [
    {
      start    = "30 17 * * *"
      end      = "0 8 * * *"
      timezone = "Europe/Berlin"
    }
  ]

  maintenance = {
    enable_kubernetes_version_updates    = true
    enable_machine_image_version_updates = true
    start                                = "01:00:00Z"
    end                                  = "02:00:00Z"
  }

  extensions = {
    acl = {
      allowed_cidrs = ["0.0.0.0/24"] # adjust
      enabled       = true
    }
  }
}
