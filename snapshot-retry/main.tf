resource "azurerm_resource_group" "res-0" {
  location = "westeurope"
  name     = "FunctionsRG"
}
resource "azurerm_storage_account" "res-1" {
  access_tier                     = "Hot"
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  location                        = "westeurope"
  name                            = "foundationalstore"
  resource_group_name             = azurerm_resource_group.res-0.name
  blob_properties {
    container_delete_retention_policy {
    }
    delete_retention_policy {
    }
  }
  queue_properties {
    hour_metrics {
      enabled = false
      version = "1.0"
    }
    logging {
      delete  = false
      read    = false
      version = "1.0"
      write   = false
    }
    minute_metrics {
      enabled = false
      version = "1.0"
    }
  }
  share_properties {
    retention_policy {
    }
  }
}
resource "azurerm_storage_container" "res-3" {
  default_encryption_scope = "$account-encryption-key"
  name                     = "githubeventslogs"
  storage_account_id       = "/subscriptions/5f04c695-b6c6-4f21-8e29-acdd0aa5160c/resourceGroups/FunctionsRG/providers/Microsoft.Storage/storageAccounts/foundationalstore"
  depends_on = [
    # One of azurerm_storage_account.res-1,azurerm_storage_account_queue_properties.res-5 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_storage_account_queue_properties" "res-5" {
  storage_account_id = azurerm_storage_account.res-1.id
  hour_metrics {
    version = "1.0"
  }
  logging {
    delete  = false
    read    = false
    version = "1.0"
    write   = false
  }
  minute_metrics {
    version = "1.0"
  }
}
resource "azurerm_storage_queue" "res-6" {
  name                 = "webjobs-blobtrigger-poison"
  storage_account_name = "foundationalstore"
  depends_on = [
    azurerm_storage_account_queue_properties.res-5,
  ]
}
resource "azurerm_storage_account" "res-8" {
  access_tier                     = "Hot"
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  allowed_copy_scope              = "All"
  default_to_oauth_authentication = true
  location                        = "westeurope"
  name                            = "functionsrgabbd"
  resource_group_name             = azurerm_resource_group.res-0.name
  blob_properties {
  }
  network_rules {
    bypass         = ["None"]
    default_action = "Allow"
  }
  queue_properties {
    hour_metrics {
      enabled = false
      version = "1.0"
    }
    logging {
      delete  = false
      read    = false
      version = "1.0"
      write   = false
    }
    minute_metrics {
      enabled = false
      version = "1.0"
    }
  }
  share_properties {
    retention_policy {
    }
  }
}
resource "azurerm_storage_container" "res-10" {
  default_encryption_scope = "$account-encryption-key"
  name                     = "azure-webjobs-hosts"
  storage_account_id       = "/subscriptions/5f04c695-b6c6-4f21-8e29-acdd0aa5160c/resourceGroups/FunctionsRG/providers/Microsoft.Storage/storageAccounts/functionsrgabbd"
  depends_on = [
    # One of azurerm_storage_account.res-8,azurerm_storage_account_queue_properties.res-14 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_storage_container" "res-11" {
  default_encryption_scope = "$account-encryption-key"
  name                     = "azure-webjobs-secrets"
  storage_account_id       = "/subscriptions/5f04c695-b6c6-4f21-8e29-acdd0aa5160c/resourceGroups/FunctionsRG/providers/Microsoft.Storage/storageAccounts/functionsrgabbd"
  depends_on = [
    # One of azurerm_storage_account.res-8,azurerm_storage_account_queue_properties.res-14 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_storage_share" "res-13" {
  access_tier        = "TransactionOptimized"
  name               = "foundationalfunctions8db1"
  quota              = 102400
  storage_account_id = "/subscriptions/5f04c695-b6c6-4f21-8e29-acdd0aa5160c/resourceGroups/FunctionsRG/providers/Microsoft.Storage/storageAccounts/functionsrgabbd"
  depends_on = [
    # One of azurerm_storage_account.res-8,azurerm_storage_account_queue_properties.res-14 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_storage_account_queue_properties" "res-14" {
  storage_account_id = azurerm_storage_account.res-8.id
  hour_metrics {
    version = "1.0"
  }
  logging {
    delete  = false
    read    = false
    version = "1.0"
    write   = false
  }
  minute_metrics {
    version = "1.0"
  }
}
resource "azurerm_storage_queue" "res-15" {
  name                 = "azure-webjobs-blobtrigger-foundationalfunctions"
  storage_account_name = "functionsrgabbd"
  depends_on = [
    azurerm_storage_account_queue_properties.res-14,
  ]
}
resource "azurerm_service_plan" "res-17" {
  location                     = "westeurope"
  maximum_elastic_worker_count = 1
  name                         = "ASP-FunctionsRG-9b17"
  os_type                      = "Windows"
  resource_group_name          = azurerm_resource_group.res-0.name
  sku_name                     = "Y1"
}
resource "azurerm_monitor_action_group" "res-18" {
  name                = "Application Insights Smart Detection"
  resource_group_name = azurerm_resource_group.res-0.name
  short_name          = "SmartDetect"
  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }
  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }
}
resource "azurerm_application_insights" "res-19" {
  application_type                     = "web"
  daily_data_cap_notifications_enabled = true
  ip_masking_enabled                   = true
  local_authentication_enabled         = true
  location                             = "westeurope"
  name                                 = "FoundationalFunctions"
  resource_group_name                  = azurerm_resource_group.res-0.name
  sampling_percentage                  = 0
  workspace_id                         = "/subscriptions/5f04c695-b6c6-4f21-8e29-acdd0aa5160c/resourceGroups/DefaultResourceGroup-WEU/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-5f04c695-b6c6-4f21-8e29-acdd0aa5160c-WEU"
}
resource "azurerm_windows_function_app" "res-20" {
  app_settings = {
    AzureWebJobsStorageForGitHubLogs = ""
    GitHubWebhookSecret              = ""
    foundationalstore_STORAGE        = ""
  }
  builtin_logging_enabled                  = false
  client_certificate_mode                  = "Required"
  ftp_publish_basic_authentication_enabled = false
  https_only                               = true
  key_vault_reference_identity_id          = "SystemAssigned"
  location                                 = "westeurope"
  name                                     = "FoundationalFunctions"
  resource_group_name                      = "functionsrg"
  service_plan_id                          = azurerm_service_plan.res-17.id
  storage_account_name                     = "functionsrgabbd"
  tags = {
    "hidden-link: /app-insights-resource-id" = "/subscriptions/5f04c695-b6c6-4f21-8e29-acdd0aa5160c/resourceGroups/FunctionsRG/providers/microsoft.insights/components/FoundationalFunctions"
  }
  webdeploy_publish_basic_authentication_enabled = false
  auth_settings {
    enabled                       = false
    token_refresh_extension_hours = 0
  }
  site_config {
    app_scale_limit                   = 200
    default_documents                 = ["Default.htm", "Default.html", "Default.asp", "index.htm", "index.html", "iisstart.htm", "default.aspx", "index.php"]
    ftps_state                        = "FtpsOnly"
    ip_restriction_default_action     = ""
    scm_ip_restriction_default_action = ""
    use_32_bit_worker                 = false
    worker_count                      = 1
    application_stack {
      dotnet_version          = "v10.0"
      powershell_core_version = "7.6"
    }
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }
}
resource "azurerm_function_app_function" "res-24" {
  config_json = jsonencode({
    bindings = [{
      authLevel = "function"
      direction = "in"
      methods   = ["get", "post"]
      name      = "Request"
      type      = "httpTrigger"
      }, {
      direction = "out"
      name      = "Response"
      type      = "http"
    }]
  })
  function_app_id = azurerm_windows_function_app.res-20.id
  name            = "http_githubevents_logger"
}
resource "azurerm_app_service_custom_hostname_binding" "res-25" {
  app_service_name    = "FoundationalFunctions"
  hostname            = "foundationalfunctions-eufdaqesftdyekfc.westeurope-01.azurewebsites.net"
  resource_group_name = "functionsrg"
  depends_on = [
    azurerm_windows_function_app.res-20,
  ]
}
