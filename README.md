# Modernisation Platform Terraform SSM Patching

[![Standards Icon]][Standards Link] [![Format Code Icon]][Format Code Link] [![Scorecards Icon]][Scorecards Link] [![SCA Icon]][SCA Link] [![Terraform SCA Icon]][Terraform SCA Link]

## Usage

To use this module, you must have instances with the SSM agent installed (Comes as default with many AMIS), as well as have a tag of "Patching: Yes"

We're looking to add more functionality with tagging, so these requirements may change in further releases.

```hcl

module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref="
  count  = local.environment == "development" ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = local.application_name
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

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3-bucket"></a> [s3-bucket](#module\_s3-bucket) | github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket | 8688bc15a08fbf5a4f4eef9b7433c5a417df8df1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.ssm-patching-iam-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ssm-patching-iam-role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm-admin-automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_resourcegroups_group.patch-resource-group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_default_patch_baseline.ssm-default-patch-baseline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_default_patch_baseline) | resource |
| [aws_ssm_maintenance_window.ssm-maintenance-window](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_target.ssm-maintenance-window-target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_task.ssm-maintenance-window-automation-task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_patch_baseline.ssm-patch-baseline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_patch_baseline) | resource |
| [aws_elb_service_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm-admin-policy-doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | Account number of current environment | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application | `string` | n/a | yes |
| <a name="input_approval_days"></a> [approval\_days](#input\_approval\_days) | Number of days before the package is approved, used by the approval rule only, and is not required for the automation script | `string` | `"7"` | no |
| <a name="input_compliance_level"></a> [compliance\_level](#input\_compliance\_level) | Select the level of compliance, used by the approval rule only, and is not required for the automation script. By default it's CRITICAL | `string` | `"CRITICAL"` | no |
| <a name="input_existing_bucket_name"></a> [existing\_bucket\_name](#input\_existing\_bucket\_name) | The name of the existing bucket name. If no bucket is provided one will be created for them. | `string` | `""` | no |
| <a name="input_force_destroy_bucket"></a> [force\_destroy\_bucket](#input\_force\_destroy\_bucket) | A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_operating_system"></a> [operating\_system](#input\_operating\_system) | Operating system on the ec2 instance, used by the approval rule only, and is not required for the automation script | `string` | `"CENTOS"` | no |
| <a name="input_patch_classification"></a> [patch\_classification](#input\_patch\_classification) | Windows Options=(CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades), Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage) | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_patch_key"></a> [patch\_key](#input\_patch\_key) | Defaults as tag:Patching, but can be customised if pre existing tags and values want to be used | `string` | `"Patching"` | no |
| <a name="input_patch_schedule"></a> [patch\_schedule](#input\_patch\_schedule) | Crontab on when to run the automation script. | `string` | `"cron(00 22 ? * MON *)"` | no |
| <a name="input_patch_tag"></a> [patch\_tag](#input\_patch\_tag) | Defaults as yes, but can be customised if pre existing tags and values want to be used | `string` | `"Yes"` | no |
| <a name="input_product"></a> [product](#input\_product) | The specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022 | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_rejected_patches"></a> [rejected\_patches](#input\_rejected\_patches) | List of patches to be rejected | `list(string)` | `[]` | no |
| <a name="input_severity"></a> [severity](#input\_severity) | Severity of the patch e.g. Critical, Important, Medium, Low | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | When creating multiple patch schedules per environment, a suffix can be used to differentiate resources | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to be used by all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam-policy-arn"></a> [iam-policy-arn](#output\_iam-policy-arn) | The policy arn for the IAM policy used by the automation script |
| <a name="output_maintenance-window-id"></a> [maintenance-window-id](#output\_maintenance-window-id) | The maintenance window id |
| <a name="output_maintenance-window-target-id"></a> [maintenance-window-target-id](#output\_maintenance-window-target-id) | The target id for the maintenance window |
| <a name="output_patch-resource-group-arn"></a> [patch-resource-group-arn](#output\_patch-resource-group-arn) | The resource group arn for patching |
<!-- END_TF_DOCS -->

[Standards Link]: https://github-community.cloud-platform.service.justice.gov.uk/repository-standards/modernisation-platform-terraform-ssm-patching "Repo standards badge."
[Standards Icon]: https://github-community.cloud-platform.service.justice.gov.uk/repository-standards/api/modernisation-platform-terraform-ssm-patching/badge
[Format Code Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/format-code.yml?labelColor=231f20&style=for-the-badge&label=Formate%20Code
[Format Code Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/format-code.yml
[Scorecards Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/scorecards.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Scorecards
[Scorecards Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/scorecards.yml
[SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Secure%20Code%20Analysis
[SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/code-scanning.yml
[Terraform SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Terraform%20Static%20Code%20Analysis
[Terraform SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/terraform-static-analysis.yml
