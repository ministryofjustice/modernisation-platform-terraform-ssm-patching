output "patch-resource-group-arn" {
  description = "patch-resource-group"
  value       = try(aws_resourcegroups_group.patch-resource-group.arn, "")
}

output "maintenance-window-id" {
  description = ""
  value       = try(aws_ssm_maintenance_window.ssm-maintenance-window.id, "")
}

output "maintenance-window-target-id" {
  description = ""
  value       = try(aws_ssm_maintenance_window_target.ssm-maintenance-window-target.id, "")
}