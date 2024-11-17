
resource "stackit_ske_cluster" "this" {
  name       = var.CLUSTERNAME
  project_id = var.PROJECTID

  node_pools = [
    {
      name               = "node-pool-eu01-1"
      machine_type       = "g1.3"
      minimum            = "1"
      maximum            = "2"
      max_surge          = "1"
      availability_zones = ["eu01-1"]
    },
    {
      name               = "node-pool-eu01-2"
      machine_type       = "g1.3"
      minimum            = "1"
      maximum            = "2"
      max_surge          = "1"
      availability_zones = ["eu01-2"]
    },
    {
      name               = "node-pool-eu01-3"
      machine_type       = "g1.3"
      minimum            = "1"
      maximum            = "2"
      max_surge          = "1"
      availability_zones = ["eu01-3"]
    }
  ]
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
