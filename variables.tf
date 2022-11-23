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
variable "vpc_all" {
  type        = string
  description = "The full name of the VPC (including environment) used to create resources"
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
  description = "Operating system on the ec2 instance"
  default     = "CENTOS"
}
variable "approval_days" {
  type        = string
  description = "Number of days before the package is approved"
  default     = "7"
}
variable "compliance_level" {
  type        = string
  description = "Select the level of compliance"
  default     = "HIGH"
}
variable "patch_classification" {
  type        = list(string)
  description = "Operating system on the ec2 instance"
  default     = ["Security"]
}

variable "patch_schedule" {
  type        = string
  description = "Crontab on when to run the automation script"
  default     = "cron(00 08 ? * MON *)"
}