output "patch-resource-group-arn" {
  description = "patch-resource-group-arn from the patching resource group"
  value       = module.ssm-auto-patching.patch-resource-group-arn
}

output "maintenance-window-id" {
  description = ""
  value       = module.ssm-auto-patching.maintenance-window-id
}

output "maintenance-window-target-id" {
  description = ""
  value       = module.ssm-auto-patching.maintenance-window-target-id
}