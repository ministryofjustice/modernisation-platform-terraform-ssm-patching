variable "account_number" {
  type        = string
  description = "Account number of current environment"
}
variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}
variable "application_name" {
  type        = string
  description = "Name of application"
}
variable "existing_bucket_name" {
  type        = string
  default     = ""
  description = "Name of an existing S3 bucket for reports. Required if use_existing_bucket is set to true"
}
variable "use_existing_bucket" {
  type        = bool
  default     = false
  description = "Boolean to determine if an S3 bucket should be built for reports."
}
variable "force_destroy_bucket" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
variable "operating_system" {
  type        = string
  description = "Operating system on the ec2 instance, used by the approval rule only, and is not required for the automation script"
  default     = "CENTOS"
}
variable "approval_days" {
  type        = number
  description = "Number of days before the package is approved, used by the approval rule only, and is not required for the automation script"
  default     = 5
}
variable "compliance_level" {
  type        = string
  description = "Select the level of compliance, used by the approval rule only, and is not required for the automation script. By default it's CRITICAL"
  default     = "CRITICAL"
}
variable "patch_classification" {
  type        = list(string)
  description = "Windows Options=(CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades), Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)"
  default     = ["*"]
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
  default     = {
    group1 = "cron(00 22 ? * MON *)"
  }
}
variable "patch_tag_key" {
  type        = string
  description = "Defaults as tag:patch-manager, but can be customised to use a different tag"
  default     =  "patch-manager" 
}
variable "maintenance_window_duration" {
  type        = number
  description = "The duration of the Maintenance Window in hours."
  default     = 2
}
variable "maintenance_window_cutoff" {
  type        = number
  description = "The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution."
  default     = 1
}
variable "daily_definition_update" {
  type        = bool
  description = "Create an additional schedule for Windows instances to update definitions every day (no reboot required), adds all defined windows patch groups as targets."
  default     = true
}