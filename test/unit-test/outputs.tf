output "patch-resource-group-arn" {
  description = "The resource group arn for patching"
  value       = module.ssm-auto-patching.patch-resource-group-arn
}

output "maintenance-window-id" {
  description = "The maintenance window id"
  value       = module.ssm-auto-patching.maintenance-window-id
}

output "maintenance-window-target-id" {
  description = "The target id for the maintenance window"
  value       = module.ssm-auto-patching.maintenance-window-target-id
}

output "iam-policy-arn" {
  description = "The policy arn for the IAM policy used by the automation script"
  value       = module.ssm-auto-patching.iam-policy-arn
}