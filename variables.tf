variable "account_number" {
  type        = string
  description = "Account number of current environment"
}
variable "application_name" {
  type        = string
  description = "Name of application"
}
variable "environment" {
  type        = string
  description = "Current environment, used to drive the default approval days"
}
variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}
variable "approval_days" {
  type        = map(number)
  description = "A map of environment and number of days before the package is approved, used by the approval rule only, and is not required for the automation script"
  default = {
    development   = 0
    test          = 3
    preproduction = 5
    production    = 7
  }
}
variable "compliance_level" {
  type        = string
  description = "Select the level of compliance, used by the approval rule only, and is not required for the automation script. By default it's CRITICAL"
  default     = "CRITICAL"
}
variable "patch_classifications" {
  type        = map(list(string))
  description = "Maps an OS against a list of patch classification catagories"
  # "Windows Options=(CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades), Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)"
}
variable "severity" {
  type        = list(string)
  description = "Severity of the patch e.g. Critical, Important, Medium, Low"
  default     = ["*"]
}
variable "product" {
  type        = list(string)
  description = "The specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022"
  default     = ["*"]
}
variable "rejected_patches" {
  type        = list(string)
  description = "List of patches to be rejected"
  default     = []
}
variable "patch_schedules" {
  type        = map(any)
  description = "A map of target group(s) to crontab schedule(s) to define the maintenance window(s) where the patch process will run."
  default = {
    group1 = "cron(00 22 ? * MON *)"
  }
}
variable "patch_tag_key" {
  type        = string
  description = "Defaults as tag:patch-manager, but can be customised to use a different tag"
  default     = "patch-manager"
}
variable "maintenance_window_duration" {
  type        = number
  description = "The duration of the Maintenance Window in hours."
  default     = 4
}
variable "maintenance_window_cutoff" {
  type        = number
  description = "The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution."
  default     = 2
}
variable "daily_definition_update" {
  type        = bool
  description = "Create an additional schedule for Windows instances to update definitions every day (no reboot required), Uses tag:os-type = Windows as targets."
  default     = false
}

variable "simple_patching" {
  type        = bool
  description = "Set to true to use AWS-RunPatchBaseline directly, instead of AWS-PatchInstanceWithRollback which is a wrapper that adds sophisticated orchestration and lambda logs etc."
  default     = false
}