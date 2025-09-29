locals {
  first_failover_location = var.failover_location != null ? [{
    location        = var.failover_location
    failover_priority = 1
    zone_redundant  = var.failover_location_zone_redundant
  }] : []
}
