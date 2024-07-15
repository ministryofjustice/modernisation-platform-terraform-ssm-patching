output "patch-resource-group-arn" {
  description = "The resource group arn for patching"
  value       = try(aws_resourcegroups_group.patch-resource-group.arn, "")
}

output "maintenance-window-id" {
  description = "The maintenance window id"
  value       = try(aws_ssm_maintenance_window.ssm-maintenance-window.id, "")
}

output "maintenance-window-target-id" {
  description = "The target id for the maintenance window"
  value       = try(aws_ssm_maintenance_window_target.ssm-maintenance-window-target.id, "")
}

output "iam-policy-arn" {
  description = "The policy arn for the IAM policy used by the automation script"
  value       = try(aws_iam_role_policy_attachment.ssm-admin-automation.policy_arn, "")
}

output "baselines" {
  description = "The baselines for the patching"
  value = {
    "oracle-linux-8-patch-baseline"  = aws_ssm_patch_baseline.oracle_linux_8_baseline
    "oracle-database-patch-baseline" = aws_ssm_patch_baseline.oracle-database-patch-baseline
  }
}
