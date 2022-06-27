locals {
  diag_resource_list = (var.diagnostics != null) ? split("/", lower(var.diagnostics.destination)) : []

  parsed_diag = (var.diagnostics != null) ? {
    log_analytics_id   = contains(local.diag_resource_list, "microsoft.operationalinsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : azurerm_storage_account.mysql[0].id
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = var.diagnostics.metrics
    log                = var.diagnostics.logs
    } : {
    log_analytics_id   = null
    storage_account_id = null
    event_hub_auth_id  = null
    metric             = []
    log                = []
  }
}

data "azurerm_monitor_diagnostic_categories" "mysql_server" {
  count = (var.diagnostics != null) ? 1 : 0

  resource_id = azurerm_mysql_flexible_server.mysql.id
}

resource "azurerm_monitor_diagnostic_setting" "mysql_server" {
  count = (var.diagnostics != null) ? 1 : 0

  name                           = "${var.name}-mysql-diag"
  target_resource_id             = azurerm_mysql_flexible_server.mysql.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.mysql_server[0].logs

    content {
      category = log.value
      enabled  = contains(local.parsed_diag.log, "all") || contains(local.parsed_diag.log, log.value)

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.mysql_server[0].metrics

    content {
      category = metric.value
      enabled  = contains(local.parsed_diag.metric, "all") || contains(local.parsed_diag.metric, metric.value)

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }
}
