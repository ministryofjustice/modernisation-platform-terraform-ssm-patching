# Modernisation Platform Terraform SSM Patching

[![Standards Icon]][Standards Link] [![Format Code Icon]][Format Code Link] [![Scorecards Icon]][Scorecards Link] [![SCA Icon]][SCA Link] [![Terraform SCA Icon]][Terraform SCA Link]

## Usage

To use this module, instances must have the SSM agent installed (installed by default with many AMI'S).  To use the module default schedule, you must also have a tag of "patch-manager: group1" on an instance to associate it to the patch schedule.  The tag name, values and associated schedules can all be customised as required.  The tag value drives the naming suffix which is important when multiple patch groups are defined.

Version 4 is essentially a re-write with many improvements and required changes to input arguments to fully integrate multiple patch groups, OSes and shared resources to reduce the amount of duplicate resources required with only a single module call needed per account.  If upgrading be sure to review the Inputs section / release notes.

By default the module will create 1 patch group and associated schedule, the classifications by OS need to be specified.

```hcl

# Basic Example

module "ssm-patching" {
  source                = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref="
  providers             = { aws.bucket-replication = aws }
  count                 = local.environment == "development" ? 1 : 0
  providers             = { aws.bucket-replication = aws }
  account_number        = local.environment_management.account_ids[terraform.workspace]
  environment           = "development"
  application_name      = local.application_name
  patch_classifications = {
    WINDOWS = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"]
  }
  tags                  = merge(local.tags, { Name = "ssm-patching-module" }, )
}

```

However, it is expected you may want to add multiple patch groups with your own schedules, the example below shows 2 groups.

```hcl

# Example with 2 patch groups with associated schedules and 2 supported OSes with associated classifications.

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
  environment                 = local.environment                                             # Required
  patch_schedules             = local.patch_manager.patch_schedules
  maintenance_window_cutoff   = local.patch_manager.maintenance_window_cutoff
  maintenance_window_duration = local.patch_manager.maintenance_window_duration
  patch_classifications       = local.patch_manager.patch_classifications                     # Required
  daily_definition_update     = local.patch_manager.daily_definition_update
  tags                        = merge(local.tags, { Name = "ssm-patching-module" },)
}

```

This v4 removes the archiving of reports to S3 bucket to reduce complexity and cost, as all results and Patch compliance findings are exported to Security Hub by default.

<!--- BEGIN_TF_DOCS --->


<!--- END_TF_DOCS --->

## Looking for issues?
If you're looking to raise an issue with this module, please create a new issue in the [Modernisation Platform repository](https://github.com/ministryofjustice/modernisation-platform/issues).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.90 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.90 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_resourcegroups_group.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |
| [aws_ssm_default_patch_baseline.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_default_patch_baseline) | resource |
| [aws_ssm_maintenance_window.definition_updates](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_target.definition_updates](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_target.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_task.definition_updates](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_maintenance_window_task.patch_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_patch_baseline.patch_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_patch_baseline) | resource |
| [aws_iam_policy_document.patch-manager-policy-doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | Account number of current environment | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application | `string` | n/a | yes |
| <a name="input_approval_days"></a> [approval\_days](#input\_approval\_days) | A map of environment and number of days before the package is approved, used by the approval rule only, and is not required for the automation script | `map(number)` | <pre>{<br/>  "development": 0,<br/>  "preproduction": 5,<br/>  "production": 7,<br/>  "test": 3<br/>}</pre> | no |
| <a name="input_compliance_level"></a> [compliance\_level](#input\_compliance\_level) | Select the level of compliance, used by the approval rule only, and is not required for the automation script. By default it's CRITICAL | `string` | `"CRITICAL"` | no |
| <a name="input_daily_definition_update"></a> [daily\_definition\_update](#input\_daily\_definition\_update) | Create an additional schedule for Windows instances to update definitions every day (no reboot required), Uses tag:os-type = Windows as targets. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Current environment, used to drive the default approval days | `string` | n/a | yes |
| <a name="input_maintenance_window_cutoff"></a> [maintenance\_window\_cutoff](#input\_maintenance\_window\_cutoff) | The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution. | `number` | `2` | no |
| <a name="input_maintenance_window_duration"></a> [maintenance\_window\_duration](#input\_maintenance\_window\_duration) | The duration of the Maintenance Window in hours. | `number` | `4` | no |
| <a name="input_patch_classifications"></a> [patch\_classifications](#input\_patch\_classifications) | Maps an OS against a list of patch classification catagories | `map(list(string))` | n/a | yes |
| <a name="input_patch_schedules"></a> [patch\_schedules](#input\_patch\_schedules) | A map of target group(s) to crontab schedule(s) to define the maintenance window(s) where the patch process will run. | `map(any)` | <pre>{<br/>  "group1": "cron(00 22 ? * MON *)"<br/>}</pre> | no |
| <a name="input_patch_tag_key"></a> [patch\_tag\_key](#input\_patch\_tag\_key) | Defaults as tag:patch-manager, but can be customised to use a different tag | `string` | `"patch-manager"` | no |
| <a name="input_product"></a> [product](#input\_product) | The specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022 | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_rejected_patches"></a> [rejected\_patches](#input\_rejected\_patches) | List of patches to be rejected | `list(string)` | `[]` | no |
| <a name="input_severity"></a> [severity](#input\_severity) | Severity of the patch e.g. Critical, Important, Medium, Low | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to be used by all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_policy_arn"></a> [iam\_policy\_arn](#output\_iam\_policy\_arn) | The policy arn for the IAM policy used by the automation script |
| <a name="output_maintenance_window_ids"></a> [maintenance\_window\_ids](#output\_maintenance\_window\_ids) | The maintenance window id(s) |
| <a name="output_maintenance_window_target_ids"></a> [maintenance\_window\_target\_ids](#output\_maintenance\_window\_target\_ids) | The target id(s) for the maintenance window |
| <a name="output_patch_resource_group_arns"></a> [patch\_resource\_group\_arns](#output\_patch\_resource\_group\_arns) | The resource group arn(s) for patching |
<!-- END_TF_DOCS -->

[Standards Link]: https://github-community.service.justice.gov.uk/repository-standards/modernisation-platform-terraform-ssm-patching "Repo standards badge."
[Standards Icon]: https://github-community.service.justice.gov.uk/repository-standards/api/modernisation-platform-terraform-ssm-patching/badge
[Format Code Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/format-code.yml?labelColor=231f20&style=for-the-badge&label=Formate%20Code
[Format Code Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/format-code.yml
[Scorecards Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/scorecards.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Scorecards
[Scorecards Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/scorecards.yml
[SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Secure%20Code%20Analysis
[SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/code-scanning.yml
[Terraform SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-ssm-patching/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Terraform%20Static%20Code%20Analysis
[Terraform SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching/actions/workflows/terraform-static-analysis.yml
