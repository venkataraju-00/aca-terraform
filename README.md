# Azure Cosmos DB Document DB (SQL API) Terraform Module

This Terraform module deploys a comprehensive Azure Cosmos DB Document DB account with enterprise-grade security, monitoring, and compliance features specifically designed for Northern Trust requirements.

## Features

### Core Infrastructure
- **Azure Cosmos DB Document DB Account** with global distribution and SQL API
- **User-Assigned Managed Identity** for secure Key Vault access
- **SQL Databases and Containers** with dynamic configuration
- **Private Endpoint** for network isolation (NT Policy compliance)
- **Customer-Managed Encryption** using Azure Key Vault
- **Multi-region deployment** with automatic failover

### Security & Compliance
- Private Link connectivity (NT Policy requirement)
- Customer-managed encryption keys
- Disabled local authentication (NT Policy requirement)
- Comprehensive diagnostic logging
- Role-based access control integration

### Monitoring & Alerting
- **Comprehensive metric alerts** covering performance, availability, and cost
- **Log Analytics integration** for centralized monitoring
- **Diagnostic settings** with auto-discovery of log categories
- **Customizable alert thresholds** with sensible defaults

## Usage

```hcl
module "cosmos_db" {
  source = "./aca-terraform"

  # Required variables
  resource_group_name           = "rg-cosmos-prod"
  location                     = "East US"
  cosmos_database_account_name = "cosmos-prod-001"
  key_vault_key_id            = "/subscriptions/.../keys/cosmos-key"
  kv_id                       = "/subscriptions/.../vaults/kv-prod"
  subnet_id                   = "/subscriptions/.../subnets/cosmos-subnet"
  analytics_workspace_id      = "/subscriptions/.../workspaces/law-prod"
  
  # Optional alert configuration
  enable_alerts     = true
  action_group_id   = "/subscriptions/.../actionGroups/cosmos-alerts"
  
  # Cosmos DB configuration
  sql_dbs = {
    "main-db" = {
      db_name          = "MainDatabase"
      db_throughput    = 400
      db_max_throughput = null
    }
  }
  
  sql_db_containers = {
    "users-container" = {
      container_name     = "Users"
      db_name           = "MainDatabase"
      partition_key_paths = ["/userId"]
      container_throughput = 400
    }
  }
  
  tags = {
    Environment = "Production"
    Team        = "Platform"
  }
}
```

## Monitoring Alerts

This module includes 12 comprehensive monitoring alerts covering all critical aspects of Document DB (SQL API) operations:

### Performance Alerts
| Alert Name | Description | Default Threshold | Severity |
|------------|-------------|-------------------|----------|
| `high-ru-consumption` | High Request Unit consumption | 1000 RU/s | 2 |
| `high-request-rate` | Unusually high request rate | 100 requests | 2 |
| `high-latency` | High server-side latency | 100ms | 2 |
| `high-provisioned-throughput` | High throughput utilization | 800 RU/s | 2 |

### Error & Availability Alerts
| Alert Name | Description | Default Threshold | Severity |
|------------|-------------|-------------------|----------|
| `throttling-errors` | HTTP 429 throttling errors | 5 errors | 1 |
| `server-errors` | HTTP 5xx server errors | 5 errors | 1 |
| `low-availability` | Service availability drop | 99.9% | 1 |

### Storage & Capacity Alerts
| Alert Name | Description | Default Threshold | Severity |
|------------|-------------|-------------------|----------|
| `high-storage` | Storage usage approaching limits | 80GB | 2 |
| `high-index-usage` | Index usage approaching limits | 8GB | 2 |
| `high-document-count` | Document count approaching limits | 1M documents | 2 |

### Multi-Region Alerts
| Alert Name | Description | Default Threshold | Severity |
|------------|-------------|-------------------|----------|
| `replication-lag` | High replication lag between regions | 1000ms | 2 |

### Metadata Alerts
| Alert Name | Description | Default Threshold | Severity |
|------------|-------------|-------------------|----------|
| `high-metadata-requests` | High metadata request rate | 50 requests | 2 |

### Autoscale Alerts
| Alert Name | Description | Default Threshold | Severity |
|------------|-------------|-------------------|----------|
| `autoscale-max-throughput` | Autoscale max throughput reached | 4000 RU/s | 1 |

## Alert Configuration

### Enable/Disable Alerts
```hcl
enable_alerts = true  # Enable all alerts (default: true)
```

### Action Group Configuration
```hcl
action_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-monitoring/providers/Microsoft.Insights/actionGroups/cosmos-alerts"
```

### Customize Individual Alerts
You can customize any alert by overriding the `cosmos_alerts` variable:

```hcl
cosmos_alerts = {
  # Customize existing alerts
  high_ru_consumption = {
    name             = "high-ru-consumption"
    description      = "Alert when RU consumption is consistently high"
    severity         = 1  # Changed from default 2 to 1 (more critical)
    frequency        = "PT1M"  # Changed from PT5M to PT1M (more frequent)
    window_size      = "PT5M"  # Changed from PT15M to PT5M (shorter window)
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequestUnits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1500  # Changed from default 1000 to 1500
    dimensions       = null
    enabled          = true
    condition        = true
  }
  
  # Disable specific alerts
  high_storage = {
    name             = "high-storage"
    description      = "Alert when storage usage is approaching limits"
    severity         = 2
    frequency        = "PT15M"
    window_size      = "PT30M"
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "DataUsage"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 85899345920
    dimensions       = null
    enabled          = false  # Disable this alert
    condition        = true
  }
  
  # Add custom alert
  custom_alert = {
    name             = "custom-metric-alert"
    description      = "Custom alert for specific metric"
    severity         = 2
    frequency        = "PT5M"
    window_size      = "PT15M"
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "CustomMetric"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 100
    dimensions       = null
    enabled          = true
    condition        = true
  }
}
```

### Quick Threshold Adjustments
For simple threshold changes, you can override just the thresholds:

```hcl
cosmos_alerts = {
  high_ru_consumption = {
    # Keep all defaults, just change threshold
    name             = "high-ru-consumption"
    description      = "Alert when RU consumption is consistently high"
    severity         = 2
    frequency        = "PT5M"
    window_size      = "PT15M"
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequestUnits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 2000  # Custom threshold
    dimensions       = null
    enabled          = true
    condition        = true
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| azurerm | >= 3.116 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.116 |

## Resources Created

### Core Resources
- `azurerm_cosmosdb_account` - Main Cosmos DB account
- `azurerm_user_assigned_identity` - Managed identity (conditional)
- `azurerm_role_assignment` - Key Vault access roles
- `azurerm_cosmosdb_sql_database` - SQL databases (dynamic)
- `azurerm_cosmosdb_sql_container` - SQL containers (dynamic)
- `azurerm_monitor_diagnostic_setting` - Diagnostic logging

### Networking & Security
- `azurerm_private_endpoint` - Private endpoint (via module)
- Private DNS zone integration

### Monitoring
- `azurerm_monitor_metric_alert` - 15+ metric alerts
- `azurerm_monitor_diagnostic_categories` - Auto-discovery of log categories

## Inputs

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Resource group name | `string` |
| `location` | Azure region | `string` |
| `cosmos_database_account_name` | Cosmos DB account name | `string` |
| `key_vault_key_id` | Key Vault key ID for encryption | `string` |
| `kv_id` | Key Vault resource ID | `string` |
| `subnet_id` | Subnet ID for private endpoint | `string` |
| `analytics_workspace_id` | Log Analytics workspace ID | `string` |

### Optional Alert Variables
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_alerts` | Enable monitoring alerts | `bool` | `true` |
| `action_group_id` | Action group for alerts | `string` | `null` |
| `cosmos_alerts` | Map of alert configurations | `map(object)` | See default alerts |

### Default Alert Configurations
The `cosmos_alerts` variable contains default configurations for all alerts. Each alert object has the following structure:

```hcl
{
  name             = string           # Alert name suffix
  description      = string           # Alert description
  severity         = number           # 1 (Critical) or 2 (Warning)
  frequency        = string           # Evaluation frequency (e.g., "PT5M")
  window_size      = string           # Time window (e.g., "PT15M")
  metric_namespace = string           # Azure metric namespace
  metric_name      = string           # Metric name
  aggregation      = string           # Aggregation type (Total, Average, Maximum)
  operator         = string           # Comparison operator
  threshold        = number           # Alert threshold value
  dimensions       = map(list(string)) # Optional metric dimensions
  enabled          = bool             # Enable/disable this alert
  condition        = bool             # Additional condition for dynamic filtering
}
```

[See Variable.tf for complete list of variables]

## Outputs

### Core Outputs
| Name | Description |
|------|-------------|
| `id` | Cosmos DB account ID |
| `name` | Cosmos DB account name |
| `endpoint` | Connection endpoint |
| `primary_key` | Primary access key (sensitive) |
| `cosmosdb_connectionstrings` | Connection strings (sensitive) |

### Alert Outputs
| Name | Description |
|------|-------------|
| `alert_ids` | Map of alert names to resource IDs |
| `mongo_alert_ids` | MongoDB-specific alert IDs |
| `cassandra_alert_ids` | Cassandra-specific alert IDs |
| `replication_alert_ids` | Multi-region alert IDs |

## Northern Trust Policy Compliance

This module enforces several NT-specific requirements:

1. **Automatic failover enabled** - Ensures high availability
2. **Key-based metadata writes disabled** - Security requirement
3. **Private Link required** - Network isolation (when not using VNet rules)
4. **Comprehensive diagnostic logging** - Monitoring requirement
5. **Customer-managed encryption** - Data protection requirement

## Examples

### Basic Deployment
```hcl
module "cosmos_basic" {
  source = "./aca-terraform"
  
  resource_group_name           = "rg-cosmos-dev"
  location                     = "East US"
  cosmos_database_account_name = "cosmos-dev-001"
  key_vault_key_id            = var.kv_key_id
  kv_id                       = var.kv_id
  subnet_id                   = var.subnet_id
  analytics_workspace_id      = var.law_id
}
```

### Production Deployment with Custom Alerts
```hcl
module "cosmos_prod" {
  source = "./aca-terraform"
  
  # Core configuration
  resource_group_name           = "rg-cosmos-prod"
  location                     = "East US"
  cosmos_database_account_name = "cosmos-prod-001"
  
  # Security
  key_vault_key_id = var.kv_key_id
  kv_id           = var.kv_id
  subnet_id       = var.subnet_id
  
  # Monitoring
  analytics_workspace_id = var.law_id
  enable_alerts         = true
  action_group_id       = var.action_group_id
  
  # Custom alert thresholds for production
  high_ru_threshold           = 2000
  throttling_error_threshold  = 3
  low_availability_threshold  = 99.95
  
  # Multi-region configuration
  enable_multiple_write_locations = true
  failover_location              = "West US"
  
  # Backup configuration
  backup_type = "Continuous"
  backup_tier = "Continuous30Days"
  
  tags = {
    Environment = "Production"
    Team        = "Platform"
    CostCenter  = "IT-001"
  }
}
```

## License

This module is maintained by Northern Trust for internal use.
