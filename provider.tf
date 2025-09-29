terraform{
    required_version = ">= 1.9"
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = ">=3.116" # This is the earliest version that supports burst_capacity_enabled
        }
    }
}