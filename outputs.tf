output "patch_resource_group_arns" {
  description = "The resource group arn(s) for patching"
  value       = try(aws_resourcegroups_group.patch_manager[*].arn, "")
}

output "maintenance_window_ids" {
  description = "The maintenance window id(s)"
  value       = try(aws_ssm_maintenance_window.patch_manager[*].id, "")
}

output "maintenance_window_target_ids" {
  description = "The target id(s) for the maintenance window"
  value       = try(aws_ssm_maintenance_window_target.patch_manager[*].id, "")
}

output "iam_policy_arn" {
  description = "The policy arn for the IAM policy used by the automation script"
  value       = try(aws_iam_role_policy_attachment.patch_manager.policy_arn, "")
}
