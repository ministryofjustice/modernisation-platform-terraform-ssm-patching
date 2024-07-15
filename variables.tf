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
  description = "The name of the existing bucket name. If no bucket is provided one will be created for them."
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
  type        = string
  description = "Number of days before the package is approved, used by the approval rule only, and is not required for the automation script"
  default     = "7"
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
variable "patch_schedule" {
  type        = string
  description = "Crontab on when to run the automation script. " # e.g. "cron(00 01 ? * MON *)"
  default     = "cron(00 22 ? * MON *)"
}
variable "patch_key" {
  type        = string
  description = "Defaults as tag:Patching, but can be customised if pre existing tags and values want to be used"
  default     = "Patching"
}
variable "patch_tag" {
  type        = string
  description = "Defaults as yes, but can be customised if pre existing tags and values want to be used"
  default     = "Yes"
}
variable "rejected_patches" {
  type        = list(string)
  description = "List of patches to be rejected"
  default     = []
}
variable "suffix" {
  type        = string
  description = "When creating multiple patch schedules per environment, a suffix can be used to differentiate resources"
  default     = ""
}