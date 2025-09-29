variable "key_vault_key_id" {
  description = "(Versionless_ID) The Base ID of the Key Vault Key"
  type        = string
}

variable "kv_id" {
  description = "The ID of the Key Vault containing your key_vault_key."
  type        = string
}

variable "identity_name" {
  type        = string
  description = "(Optional) The identity name for the user-assigned managed identity. Changing this forces a new resource to be created."
  default     = "cosmos-identity"
}

variable "subnet_id" {
  description = "The ID of the subnet for the private link."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which the CosmosDB Account is created. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "tags" {
  default     = {}
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(string)
}
# Cosmos database creation variables
variable "cosmos_database_account_name" {
  description = "Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created."
  type        = string
}

variable "offer_type" {
  default     = "Standard"
  description = "(Optional) Specifies the Offer Type to use for this CosmosDB Account - currently this can only be set to Standard."
  type        = string
}

variable "db_kind" {
  default     = "GlobalDocumentDB"
  description = "(Optional) Specifies the Kind of CosmosDB to create - possible values are GlobalDocumentDB and MongoDB. Defaults to GlobalDocumentDB."
  type        = string
  validation {
    condition     = contains(["GlobalDocumentDB", "Parse"], var.db_kind)
    error_message = "The db_kind must be one of the following: GlobalDocumentDB or Parse. If you're looking for MongoDB please see Mongo..."
  }
}

variable "is_virtual_network_filter_enabled" {
  default     = false
  description = "(Optional) Enables virtual network filtering for this Cosmos DB account."
  type        = bool
}

variable "network_acl_bypass_for_azure_services" {
  default     = false
  description = "(Optional) If Azure services can bypass ACLs. Defaults to false"
  type        = bool
}
variable "virtual_network_rule" {
  description = "Specifies a virtual_network_rules resource used to define which subnets are allowed to access this CosmosDB account"
  type = list(object({
    id                               = string,
    ignore_missing_vnet_service_endpoint = bool
  }))
  default = null
}

variable "enable_multiple_write_locations" {
  default     = true
  description = "Enable multiple write locations for this Cosmos DB account."
  type        = bool
}

variable "local_authentication_disabled" {
  description = "(Optional) Whether to disable local access key based authentication to the Cosmos DB account. NT Policy requires this to be"
  type        = bool
  default     = true
}

variable "consistency_level" {
  default     = "BoundedStaleness"
  description = "(Optional) The Consistency Level to use for this Cosmos DB Account - can be either BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix"
  validation {
    condition     = contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], var.consistency_level)
    error_message = "The consistency_level must be one of the following: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix."
  }
  type = string
}

variable "max_interval_in_seconds" {
  default     = 5
  description = "(Optional) When used with the Bounded Staleness consistency level, this value represents the time amount of staleness (in seconds)."
  type        = number
}

variable "max_staleness_prefix" {
  default     = 100
  description = "(Optional) When used with the Bounded Staleness consistency level, this value represents the number of stale requests tolerated."
  type        = number
}

variable "primary_location_zone_redundant" {
  description = "(Optional) Should zone redundancy be enabled for primary location/region? Defaults to false."
  type        = bool
  default     = false
}

variable "failover_location" {
  description = "(Optional) Legacy second geo location for Cosmos DB. Previously required, now optional to support backward compatibility."
  type        = string
  default     = null
}

variable "failover_location_zone_reduntant" {
  description = "(Optional) Should zone redundancy be enabled for failover location/region? Defaults to false."
  type        = bool
  default     = false
}

## Backup variables
variable "backup_type" {
  type        = string
  default     = "Periodic"
  description = "(Optional) The type of backup desired. Value must be either 'Periodic' (default) or 'Continuous'. If backup_type is 'Continuous'..."

  validation {
    condition     = var.backup_type == "Periodic" || var.backup_type == "Continuous"
    error_message = "The backup_type value must be either 'Periodic' or 'Continuous'."
  }
}

variable "backup_tier" {
  type        = string
  default     = "Continuous7Days"
  description = "(Optional) The tier of Continuous backup desired. Must be either 'Continuous7Days' or 'Continuous30Days'."

  validation {
    condition     = var.backup_tier == "Continuous7Days" || var.backup_tier == "Continuous30Days"
    error_message = "The backup_tier value must be either 'Continuous7Days' or 'Continuous30Days'."
  }
}

variable "backup_interval_in_minutes" {
  type        = number
  default     = 240
  description = "(Optional) The backup interval when Continuous backups are selected. Must be between 60 and 1440, inclusive."

  validation {
    condition     = var.backup_interval_in_minutes >= 60 && var.backup_interval_in_minutes <= 1440
    error_message = "The backup_interval_in_minutes value must be between 60 and 1440, inclusive."
  }
}

variable "backup_retention_in_hours" {
  type        = number
  default     = 8
  description = "(Optional) The retention period (in hours) when Continuous backups are selected. Must be between 8 and 720, inclusive."

  validation {
    condition     = var.backup_retention_in_hours >= 8 && var.backup_retention_in_hours <= 720
    error_message = "The backup_retention_in_hours value must be between 8 and 720, inclusive."
  }
}

variable "backup_storage_redudancy" {
  type        = string
  default     = "Geo"
  description = "(Optional) The type of storage redundancy desired. Valid inputs are 'Geo', 'Local', and 'Zone'."

  validation {
    condition     = var.backup_storage_redundancy == "Geo" || var.backup_storage_redundancy == "Local" || var.backup_storage_redundancy == "Zone"
    error_message = "The backup_storage_redundancy value must be either 'Geo', 'Local', or 'Zone'."
  }
}

/* SQL API Variables */
variable "sql_dbs" {
  type = map(object({
    db_name          = string
    db_throughput    = optional(number)
    db_max_throughput = optional(number)
  }))
  description = "(Optional) Map of Cosmos DB SQL DBs to create. Some parameters are inherited from cosmos account."
  default     = {}
}

variable "sql_db_containers" {
  type = map(object({
    container_name = string
    db_name        = string
    partition_key_paths    = list(string)
    partition_key_kind     = optional(string, "Hash")
    partition_key_version  = optional(number, 2)
    container_throughput   = optional(number)
    container_max_throughput = optional(number)
    default_ttl            = optional(number)
    analytical_storage_ttl = optional(number)
    indexing_policy_settings = optional(object({
      sql_indexing_mode   = optional(string)
      sql_included_path   = optional(string) # deprecated
      sql_included_paths  = optional(list(string), [])
      sql_excluded_path   = optional(string) # deprecated
      sql_excluded_paths  = optional(list(string), [])
      composite_indexes   = optional(map(object({
        indexes = set(object({
          path  = string
          order = string
        }))
      })))
      spatial_indexes     = optional(map(object({
        path = string
      })))
    }))
    sql_unique_key = optional(list(string))
    conflict_resolution_policy = optional(object({
      mode      = string
      path      = string
      procedure = string
    }))
  }))
  description = "List of Cosmos DB SQL Containers to create. Some parameters are inherited from cosmos account."
  default     = {}
}
# monitor diagnostic variables
variable "analytics_workspace_id" {
  type        = string
  description = "(Required) Resource ID of Log Analytics Workspace."
}

variable "analytics_destination_type" {
  description = "(Optional) Possible values are AzureDiagnostics and Dedicated."
  type        = string
  default     = "Dedicated"

  validation {
    condition     = contains(["AzureDiagnostics", "Dedicated"], var.analytics_destination_type)
    error_message = "The analytics_destination_type must be one of the following: AzureDiagnostics, Dedicated."
  }
}

variable "diagnostics_name" {
  type        = string
  description = "(Optional) Specifies the name of the Diagnostic Setting."
  default     = "LOGANALYTICS-DIAGNOSTICS"
}

### ATTENTION ###
## In Terraform, this value can be obtained from a `azurerm_user_assigned_identity` resource via `azurerm_user_assigned_identity.example.id`
## Because it is associated with the deployed Azure infrastructure, for new resources this value WILL ONLY BE KNOWN DURING AN APPLY -
## So you need a separate variable to control the `count`/`for_each` block you use to conditionally create custom Infra in the module.
## You may also chose to pass in a raw string value for this obtained via the Azure console or Azure CLI.
## As of 11-28-24, it will be in the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/...

## Such a "string format validation" is not provided by this module because this format is subject to change at Microsoft’s discretion.
## See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity#id-1 for more info.
# TODO `cosmo` -> `cosmos`
variable "cosmosdb_user_assigned_identity_id" {
  type        = string
  description = "(Optional) User-supplied Azure managed user identity. If left *blank*, one will be created for you. Null values are not allowed."
  default     = ""
  validation {
    condition     = var.cosmosdb_user_assigned_identity_id != null
    error_message = "The `cosmosdb_user_assigned_identity_id` value cannot be null."
  }
}

variable "use_cosmosdb_user_assigned_identity_id" {
  type        = bool
  description = "(Optional) If true, `cosmosdb_user_assigned_identity_id` input value will be used. Otherwise, it will not be used."
  default     = false
}

variable "create_cosmos_db_spn_kv_role" {
  type        = bool
  description = "(Optional) If true, role assignment for Azure Cosmos DB SPN for Key Vault will be created."
  default     = true
}

variable "burst_capacity_enabled" {
  type        = bool
  description = "Allows the configuration of burst capacity on the Cosmos DB account."
  default     = false
}
variable "analytical_storage_schema_type" {
  description = "The analytical storage schema type for the Cosmos DB account. Possible values are 'WellDefined' and 'FullFidelity'. Default is null."
  type        = string
  default     = null
  validation {
    condition     = var.analytical_storage_schema_type == "WellDefined" || var.analytical_storage_schema_type == "FullFidelity" || var.analytical_storage_schema_type == null
    error_message = "analytical_storage_schema_type must be either 'WellDefined' or 'FullFidelity'."
  }
}

variable "additional_failover_locations" {
  description = "(Optional) A list of additional failover locations for the Cosmos DB account."
  type = list(object({
    location         = string
    failover_priority = number
    zone_redundant   = bool
  }))
  default = null
  validation {
    condition     = var.additional_failover_locations != null ? length(var.additional_failover_locations) <= 3 : true
    error_message = "You can specify up to 3 additional failover locations."
  }
}
