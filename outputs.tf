output "id" {
  description = "The CosmosDB Account ID."
  value       = azurerm_cosmosdb_account.db.id
}

output "name" {
  description = "The CosmosDB Account Name."
  value       = azurerm_cosmosdb_account.db.name
}

output "endpoint" {
  description = "The endpoint used to connect to the CosmosDB account."
  value       = azurerm_cosmosdb_account.db.endpoint
}

output "read_endpoints" {
  description = "A list of read endpoints available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.db.read_endpoints
}

output "write_endpoints" {
  description = "A list of write endpoints available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.db.write_endpoints
}

output "primary_key" {
  description = "The Primary master key for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.db.primary_key
}

output "secondary_key" {
  description = "The Secondary master key for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.db.secondary_key
}

output "cosmosdb_connectionstrings" {
  description = "A list of connection strings available for this CosmosDB account."
  value       = "AccountEndpoint=${azurerm_cosmosdb_account.db.endpoint};AccountKey=${azurerm_cosmosdb_account.db.primary_key};"
  sensitive   = true
}

# Output SQL reference
output "sql_db_id" {
  value       = [for sql_db_id in azurerm_cosmosdb_sql_database.this : zipmap([sql_db_id.name], [sql_db_id.id])]
  description = "SQL API DB IDs"
}

output "sql_containers_id" {
  value       = [for sql_container_id in azurerm_cosmosdb_sql_container.this : zipmap([sql_container_id.name], [sql_container_id.id])]
  description = "SQL API Container IDs"
}

# Output Private Endpoint Private IP Address
output "pe_private_ip_address" {
  description = "SQL API Container IDs"
  value       = try(module.cosmos_private_endpoint[0].private_ip_address, null)
}
