# Modernisation Platform Terraform SSM Patching

[![Standards Icon]][Standards Link] [![Format Code Icon]][Format Code Link] [![Scorecards Icon]][Scorecards Link] [![SCA Icon]][SCA Link] [![Terraform SCA Icon]][Terraform SCA Link]

## Usage

To use this module, instances must have the SSM agent installed (installed by default with many AMI'S).  To use the module default schedule, you must also have a tag of "patch-manager: group1" on an instance to associate it to the patch schedule.  The tag name, values and associated schedules can all be customised as required.  The tag value drives the naming suffix which is important when multiple patch groups are defined.

Version 4 is essentially a re-write with many improvements and required changes to input arguments to fully integrate multiple patch groups and shared resources to reduce the amount of duplicate resources required, if upgrading be sure to review the release notes.

By default the module will create 1 patch group and associated schedule, the classifications by OS need to be specified.

```hcl

# Basic Example

module "ssm-patching" {
  source                = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref="
  providers             = { aws.bucket-replication = aws }
  count                 = local.environment == "development" ? 1 : 0
  providers             = { aws.bucket-replication = aws }
  account_number        = local.environment_management.account_ids[terraform.workspace]
  application_name      = local.application_name
  patch_classifications = {
    WINDOWS = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"]
  }
  tags                  = merge(local.tags, { Name = "ssm-patching-module" }, )
}

```

However, it is expected you may want to add multiple patch groups with your own schedules, the example below shows 2 groups.

```hcl

# Example with 2 patch groups with associated schedules and 2 supported OS'es with associated classifications.

locals {
  patch_manager = {
    patch_schedules = {
      group1 = "cron(00 03 ? * WED *)"
      group2 = "cron(00 03 ? * THU *)"
    }
    maintenance_window_duration = 4
    maintenance_window_cutoff   = 2
    daily_definition_update     = true
    patch_classifications = {
      REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"]
      WINDOWS                 = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"]
    }
  }
}  

module "patch_manager" {
  source                      = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref="
  providers                   = { aws.bucket-replication = aws }
  account_number              = local.environment_management.account_ids[terraform.workspace] # Required
  application_name            = local.application_name                                        # Required 
  patch_schedules             = local.patch_manager.patch_schedules
  maintenance_window_cutoff   = local.patch_manager.maintenance_window_cutoff
  maintenance_window_duration = local.patch_manager.maintenance_window_duration
  patch_classifications       = local.patch_manager.patch_classifications                     # Required
  daily_definition_update     = local.patch_manager.daily_definition_update
  tags                        = merge(local.tags, { Name = "ssm-patching-module" },)
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.90 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.90 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_resourcegroups_group.patch_manager[per group]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_default_patch_baseline.patch_manager[per OS]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_default_patch_baseline) | resource |
| [aws_ssm_maintenance_window.patch_manager[per group]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_target.patch_manager[per group]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_task.patch_manager[per group]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_patch_baseline.patch_manager[per OS]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_patch_baseline) | resource |
| [aws_elb_service_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | Account number of current environment. | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application, used in resource naming. | `string` | n/a | yes |
| <a name="input_approval_days"></a> [approval\_days](#input\_approval\_days) | A map of environment and number of days before the package is approved, used by the approval rule only, and is not required for the automation script | `map(number)` | `0 to 7` | no |
| <a name="input_compliance_level"></a> [compliance\_level](#input\_compliance\_level) | Select the level of compliance, used by the approval rule only, not required for the automation script. | `string` | `"CRITICAL"` | no |
| <a name="input_patch_classifications"></a> [patch\_classifications](#input\_patch\_classifications) | Maps an OS against a list of patch classification catagories.   Windows Options=(CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades), Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage) | `map(list(string))` | n/a | yes |
| <a name="input_patch_tag_key"></a> [patch\_tag\_key](#input\_patch\_tag\_key) | Defaults as tag:patch-manager, but can be customised to use a different tag key name.  Note the key value is now defined as part of the patch_schedules map.| `string` | `"patch-manager"` | no |
| <a name="input_patch_schedules"></a> [patch\_schedules](#input\_patch\_schedule) | A map of target group(s) to crontab schedule(s) to define the maintenance window(s) where the patch process will run. | `map(any)` | `group1 = "cron(00 22 ? * MON *)"` | no |
| <a name="input_product"></a> [product](#input\_product) | The specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022 | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_rejected_patches"></a> [rejected\_patches](#input\_rejected\_patches) | List of patches to be rejected | `list(string)` | `[]` | no |
| <a name="input_severity"></a> [severity](#input\_severity) | Severity of the patch e.g. Critical, Important, Medium, Low | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_maintenance_window_duration"></a> [maintenance\_window\_duration](#input\_maintenance\_window\_duration) | The duration of the Maintenance Window in hours. | `number` | `4` | no |
| <a name="input_maintenance_window_cutoff"></a> [maintenance\_window\_cutoff](#input\_maintenance\_window\_cutoff) | The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution. | `number` | `2` | no |
| <a name="daily_definition_update"></a> [daily\_definition\_update](#inputdaily\_definition\_update) | Create an additional schedule for Windows instances to update definitions every day (no reboot required), Uses tag:os-type = Windows as targets.| `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to be used by all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_policy_arn"></a> [iam_policy_arn](#output\_iam\_policy\_arn) | The policy arn for the IAM policy used by the automation script |
| <a name="output_maintenance_window_ids"></a> [maintenance_window_ids](#output\_maintenance\_window\_ids) | The maintenance window id's |
| <a name="output_maintenance_window_target_ids"></a> [maintenance_window_target_ids](#output\_maintenance\_window_target\_ids) | The target id's for the maintenance window |
| <a name="output_patch_resource_group_arns"></a> [patch_resource_group_arns](#output\_patch\_resource_group\_arns) | The resource group arn's created per patch group |
<!-- END_TF_DOCS -->

[Standards Link]: https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-report/modernisation-platform-terraform-ssm-patching "Repo standards badge."
[Standards Icon]: https://img.shields.io/endpoint?labelColor=231f20&color=005ea5&style=for-the-badge&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fendpoint%2Fmodernisation-platform&logo=data:image/png;base64,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
[Format Code Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/format-code.yml?labelColor=231f20&style=for-the-badge&label=Formate%20Code
[Format Code Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/format-code.yml
[Scorecards Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/scorecards.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Scorecards
[Scorecards Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/scorecards.yml
[SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Secure%20Code%20Analysis
[SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/code-scanning.yml
[Terraform SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Terraform%20Static%20Code%20Analysis
[Terraform SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/terraform-static-analysis.yml