resource "azurerm_user_assigned_identity" "this" {
  # If the Custom User Assigned Identity Variable was null/blank, we should NOT try using the custom
  # Locals do NOT change value during/between runs (plan, apply, destroy) so for usability, it seems
  # See https://developer.hashicorp.com/terraform/tutorials/configuration-language/locals for more in
  count                = var.use_cosmosdb_user_assigned_identity_id ? 0 : 1
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.identity_name

  tags = var.tags
}

moved {
  from = azurerm_user_assigned_identity.this
  to   = azurerm_user_assigned_identity.this[0]
}

resource "azurerm_role_assignment" "kv_user" {
  count                = var.use_cosmosdb_user_assigned_identity_id ? 0 : 1
  scope                = var.kv_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.this[0].principal_id
  principal_type       = "ServicePrincipal"
}

moved {
  from = azurerm_role_assignment.cosmos_kv
  to   = azurerm_role_assignment.cosmos_kv[0]
}
resource "azurerm_role_assignment" "cosmos_kv" {
  count                = var.create_cosmos_db_spn_kv_role == true ? 1 : 0
  scope                = var.kv_id
  role_definition_name = "Key Vault Crypto Service Encryption User" # Azure Cosmos DB SPN
  principal_id         = "58c80f8e-4084-471f-91f4-ebc5bc9c32d3"
  principal_type       = "ServicePrincipal"
}

# Create Cosmos DB Account
resource "azurerm_cosmosdb_account" "db" {
  name                               = var.cosmos_database_account_name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  offer_type                         = var.offer_type
  kind                               = var.db_kind
  is_virtual_network_filter_enabled  = var.is_virtual_network_filter_enabled
  multiple_write_locations_enabled   = var.enable_multiple_write_locations
  default_identity_type              = var.backup_type == "Continuous" ? "UserAssignedIdentity=${var.use_cosmosdb_user_assigned_identity_id ? var.cosmosdb_user_assigned_identity_id :  azurerm_user_assigned_identity.this[0].id}" : "FirstPartyIdentity"
  tags                               = var.tags
  automatic_failover_enabled         = true                      # NT Policy - Should have autofailover enabled
  access_key_metadata_writes_enabled = false                     # NT Policy - Key based metadata write access should
  public_network_access_enabled      = var.virtual_network_rule != null ? true : false
  local_authentication_disabled      = var.local_authentication_disabled
  key_vault_key_id                   = var.key_vault_key_id
  burst_capacity_enabled             = var.burst_capacity_enabled
  analytical_storage_enabled         = var.analytical_storage_schema_type != null ? true : false
  dynamic "analytical_storage" {
    for_each = var.analytical_storage_schema_type != null ? [var.analytical_storage_schema_type] : []
    content {
      schema_type = analytical_storage.value
    }
  }

  backup {
    type                  = var.backup_type
    tier                  = var.backup_type == "Continuous" ? var.backup_tier : null
    interval_in_minutes   = var.backup_type == "Periodic" ? var.backup_interval_in_minutes : null
    retention_in_hours    = var.backup_type == "Periodic" ? var.backup_retention_in_hours : null
    storage_redundancy    = var.backup_type == "Periodic" ? var.backup_storage_redudancy : null
  }

consistency_policy {
  consistency_level      = var.consistency_level
  max_interval_in_seconds = var.max_interval_in_seconds
  max_staleness_prefix   = var.max_staleness_prefix
}

geo_location {
  location        = var.location
  failover_priority = 0
  zone_redundant  = var.primary_location_zone_redundant
}

# First failover location is optional.
dynamic "geo_location" {
  for_each = local.first_failover_location
  content {
    location          = geo_location.value.location
    failover_priority = geo_location.value.failover_priority
    zone_redundant    = geo_location.value.zone_redundant
  }
}

# Additional failover locations are optional.
dynamic "geo_location" {
  for_each = var.additional_failover_locations != null ? var.additional_failover_locations : []
  content {
    location          = geo_location.value.location
    failover_priority = geo_location.value.failover_priority
    zone_redundant    = geo_location.value.zone_redundant
  }
}
network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services

dynamic "virtual_network_rule" {
  for_each = var.virtual_network_rule != null ? toset(var.virtual_network_rule) : []
  content {
    id                              = virtual_network_rule.value.id
    ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
  }
}

identity {
  type         = "UserAssigned"
  identity_ids = [var.use_cosmosdb_user_assigned_identity_id ? var.cosmosdb_user_assigned_identity_id :  azurerm_user_assigned_identity.this[0].id]
}

depends_on = [
  azurerm_role_assignment.kv_user,
  azurerm_role_assignment.cosmos_kv
]
}

# Create Cosmos SQL Database
resource "azurerm_cosmosdb_sql_database" "this" {
  for_each            = var.sql_dbs
  name                = each.value.db_name
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
  throughput          = each.value.db_max_throughput != null ? null : each.value.db_throughput

  dynamic "autoscale_settings" {
    for_each = each.value.db_max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.db_max_throughput
    }
  }
}

# Create Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = var.sql_db_containers

  name                  = each.value.container_name
  resource_group_name   = azurerm_cosmosdb_account.db.resource_group_name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = each.value.db_name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_kind    = each.value.partition_key_kind
  partition_key_version = each.value.partition_key_version
  throughput            = each.value.container_max_throughput != null ? null : each.value.container_throughput
  default_ttl           = each.value.default_ttl
  analytical_storage_ttl = var.analytical_storage_schema_type != null ? each.value.analytical_storage_ttl : null

  # Autoscaling is optional and depends on max throughput parameter. Mutually exclusive vs. throughput.
  dynamic "autoscale_settings" {
    for_each = each.value.container_max_throughput != null ? [1] : []
    content{
      max_throughput = each.value.container_max_throughput
    }
  }
# Indexing policy is optional
dynamic "indexing_policy" {
  for_each = each.value.indexing_policy_settings != null ? [1] : []
  content {
    # Indexing mode is optional
    indexing_mode = each.value.indexing_policy_settings.sql_indexing_mode

    # Array of Included paths
    dynamic "included_path" {
      for_each = each.value.indexing_policy_settings.sql_included_paths
      iterator = path

      content {
        path = path.value
      }
    }

    # Included path is optional
    # This is redundant due to the array above, but is left for backwards compatibility so users do not have to update their code
    dynamic "included_path" {
      for_each = each.value.indexing_policy_settings.sql_included_path != null ? [1] : []
      content {
        path = each.value.indexing_policy_settings.sql_included_path
      }
    }

    # Array of Excluded paths
    dynamic "excluded_path" {
      for_each = each.value.indexing_policy_settings.sql_excluded_paths
      iterator = path

      content {
        path = path.value
      }
    }
  }
}
# Excluded path is optional
# This is redundant due to the array above, but is left for backwards compatibility so users do not have to update their code
dynamic "excluded_path" {
  for_each = each.value.indexing_policy_settings.sql_excluded_path != null ? [1] : []
  content {
    path = each.value.indexing_policy_settings.sql_excluded_path
  }
}

# Composite Index is optional
dynamic "composite_index" {
  for_each = each.value.indexing_policy_settings.composite_indexes != null ? each.value.indexing_policy_settings.composite_indexes : []
  content {
    dynamic "index" {
      for_each = composite_index.value.indexes
      content {
        path  = index.value.path
        order = index.value.order
      }
    }
  }
}

# Spatial Index is optional
dynamic "spatial_index" {
  for_each = each.value.indexing_policy_settings.spatial_indexes != null ? each.value.indexing_policy_settings.spatial_indexes : {}
  content {
    path = spatial_index.value.path
  }
}

dynamic "unique_key" {
  for_each = each.value.sql_unique_key != null ? each.value.sql_unique_key : []
  content {
    paths = unique_key.value.paths
  }
}
# conflict resolution policy
dynamic "conflict_resolution_policy" {
  for_each = each.value.conflict_resolution_policy != null ? [1] : []
  content {
    mode                        = each.value.conflict_resolution_policy.mode
    conflict_resolution_path    = each.value.conflict_resolution_policy.mode == "LastWriterWins" ? each.value.conflict_resolution_policy.path : null
    conflict_resolution_procedure = each.value.conflict_resolution_policy.mode == "Custom" ? each.value.conflict_resolution_policy.procedure : null
  }
}

# Depends on existence of Cosmos DB SQL API Database managed by module
depends_on = [
  azurerm_cosmosdb_sql_database.this
]
}

##NT POLICY ENFORCEMENT
# NT Policy - CosmosDB accounts should use private link
module "cosmos_private_endpoint" {
  count = var.virtual_network_rule == null ? 1 : 0

  # Minimum version compliant with AzureRM 4.x upgrade - see https://entcfn.ntrs.com:8443/display/TS/AzureRM+4.x+upgrade
  source = "github.com/northerntrust-internal/apm0003302-azr-azure-private-endpoint.git?ref=v1.6.0"

  # TODO add a suffix for multi/single region so Terraform doesn't try overwriting an existing resource
  private_endpoint_name = lower("${azurerm_cosmosdb_account.db.name}-pe")

  resource_group_name = var.resource_group_name

  # Current module behavior will make the embedded Python script attempt to hit "${resource_name}.${private_dns_zone_id}" -> which won't resolve
  # Unintended feature/bug
  # THIS WAS ADDED
  resource_name                = azurerm_cosmosdb_account.db.name
  location                     = var.location
  subnet_id                    = var.subnet_id
  private_connection_resource_id = azurerm_cosmosdb_account.db.id
  subresource_name             = ["SQL"]
  private_dns_zone_id          = "privatelink.documents.azure.com"
  tags                         = var.tags

  depends_on = [
    azurerm_cosmosdb_account.db
  ]
}

moved {
  from = module.cosmos_private_endpoint
  to   = module.cosmos_private_endpoint[0]
}

# NT Policy - Logging-Monitoring - Cosmos DB Deploy Diagnostic Settings for Log Analytics workspace
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = var.diagnostics_name
  target_resource_id         = azurerm_cosmosdb_account.db.id
  log_analytics_workspace_id = var.analytics_workspace_id
  log_analytics_destination_type = var.analytics_destination_type

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.this.log_category_types
    content {
      category = enabled_log.value
    }
  }
  dynamic "metric"{
    for_each = data.azurerm_monitor_diagnostic_categories.this.metrics
    content{
      category = metric.value
    }
  }

  lifecycle {
    ignore_changes = [
      target_resource_id, # Ignore changes in target resource id since it causes recreation as the id isn't known before apply
      metric,
      enabled_log,
      log_analytics_destination_type
    ]
  }
  # TODO remove when issue is fixed: https://github.com/Azure/azure-rest-api-specs/issues/9281
}

# Cosmos DB Monitoring Alerts
# These alerts cover key performance, availability, and cost metrics for Document DB (SQL API)
resource "azurerm_monitor_metric_alert" "cosmos_alerts" {
  for_each = local.active_alerts

  name                = "${var.cosmos_database_account_name}-${each.value.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_cosmosdb_account.db.id]
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold

    dynamic "dimension" {
      for_each = each.value.dimensions != null ? each.value.dimensions : {}
      content {
        name     = dimension.key
        operator = "Include"
        values   = dimension.value
      }
    }
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.tags
}
