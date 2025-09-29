data "azurerm_monitor_diagnostic_categories" "this" {
    resource_id = azurerm_cosmosdb_account.db.id
}