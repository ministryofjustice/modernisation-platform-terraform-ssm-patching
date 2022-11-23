# Modernisation Platform Terraform Module Template 

[![repo standards badge](https://img.shields.io/badge/dynamic/json?color=blue&style=for-the-badge&logo=github&label=MoJ%20Compliant&query=%24.result&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fmodernisation-platform-terraform-module-template)](https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-github-repositories.html#modernisation-platform-terraform-module-template "Link to report")

## Usage

```hcl

module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref="
  count  = local.environment == "development" ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = local.application_name
  vpc_all                    = "garden-sandbox"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

```
<!--- BEGIN_TF_DOCS --->


<!--- END_TF_DOCS --->

## Looking for issues?
If you're looking to raise an issue with this module, please create a new issue in the [Modernisation Platform repository](https://github.com/ministryofjustice/modernisation-platform/issues).

<!-- BEGIN_TF_DOCS -->
## Requirements

The module will create an automation task, and maintenance window, maintenance target as well as IAM docs and policies to run the automation task.
In this maintenance window, any ec2 instance with SSM installed and a tag called 'Patching' with the value of 'Yes' or 'True' will attempt to be patched.

Optionally, if you would like to patch manually, and view the process, this module also builds a resource group and approval rule, useable by patch manager in ssm

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3-bucket"></a> [s3-bucket](#module\_s3-bucket) | github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket | v6.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.ssm-patching-iam-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ssm-patching-iam-role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm-admin-automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_resourcegroups_group.patch-resource-group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_maintenance_window.ssm-maintenance-window](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_target.ssm-maintenance-window-target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_task.ssm-maintenance-window-automation-task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_patch_baseline.patch-baseline-poc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_patch_baseline) | resource |
| [aws_elb_service_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm-admin-policy-doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_vpc.shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | Account number of current environment | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application | `string` | n/a | yes |
| <a name="input_approval_days"></a> [approval\_days](#input\_approval\_days) | Number of days before the package is approved | `string` | `"7"` | no |
| <a name="input_compliance_level"></a> [compliance\_level](#input\_compliance\_level) | Select the level of compliance | `string` | `"HIGH"` | no |
| <a name="input_existing_bucket_name"></a> [existing\_bucket\_name](#input\_existing\_bucket\_name) | The name of the existing bucket name. If no bucket is provided one will be created for them. | `string` | `""` | no |
| <a name="input_force_destroy_bucket"></a> [force\_destroy\_bucket](#input\_force\_destroy\_bucket) | A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_operating_system"></a> [operating\_system](#input\_operating\_system) | Operating system on the ec2 instance | `string` | `"CENTOS"` | no |
| <a name="input_patch_classification"></a> [patch\_classification](#input\_patch\_classification) | Operating system on the ec2 instance | `list(string)` | <pre>[<br>  "Security"<br>]</pre> | no |
| <a name="input_patch_schedule"></a> [patch\_schedule](#input\_patch\_schedule) | Crontab on when to run the automation script | `string` | `"cron(00 08 ? * MON *)"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to be used by all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_all"></a> [vpc\_all](#input\_vpc\_all) | The full name of the VPC (including environment) used to create resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
