locals {
  first_failover_location = var.failover_location != null ? [{
    location        = var.failover_location
    failover_priority = 1
    zone_redundant  = var.failover_location_zone_reduntant
  }] : []

  # Alert configuration locals
  # Merge user-provided alert configurations with dynamic conditions
  evaluated_alerts = var.enable_alerts ? {
    for key, alert in var.cosmos_alerts : key => merge(alert, {
      # Dynamically evaluate conditions for conditional alerts
      condition = key == "replication_lag" ? (var.enable_multiple_write_locations || var.failover_location != null) : lookup(alert, "condition", true)
    })
  } : {}

  # Filter alerts based on enabled and condition flags
  active_alerts = {
    for key, alert in local.evaluated_alerts : key => alert
    if lookup(alert, "enabled", true) && lookup(alert, "condition", true)
  }
}
