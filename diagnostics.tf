###################
### Diagnostics ###
###################

# Manages a Diagnostic Setting for an existing Resource.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting
#


resource "azurerm_monitor_diagnostic_setting" "mysql_server" {
  count = (var.diagnostics != null) ? 1 : 0

  name                           = "${var.name}-mysql-diag"
  target_resource_id             = azurerm_mysql_flexible_server.mysql.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.mysql_server[0].log_category_types

    content {
      category = enabled_log.value
      retention_policy {
        enabled = contains(local.parsed_diag.log, "all") || contains(local.parsed_diag.log, enabled_log)
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.mysql_server[0].metrics

    content {
      category = metric.value
      retention_policy {
        enabled = contains(local.parsed_diag.metric, "all") || contains(local.parsed_diag.metric, metric)
      }
    }
  }
}
