output "patch_resource_group_arns" {
  description = "The resource group arn for patching"
  value       = module.ssm_auto_patching.patch_resource_group_arns
}

output "maintenance_window_ids" {
  description = "The maintenance window id"
  value       = module.ssm_auto_patching.maintenance_window_ids
}

output "maintenance_window_target_ids" {
  description = "The target id for the maintenance window"
  value       = module.ssm_auto_patching.maintenance_window_target_ids
}

output "iam_policy_arn" {
  description = "The policy arn for the IAM policy used by the automation script"
  value       = module.ssm_auto_patching.iam_policy_arn
}
