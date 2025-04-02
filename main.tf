data "aws_iam_policy_document" "patch-manager-policy-doc" {

  # Not relevant to what we are doing. This sets a high level access policy
  #checkov:skip=CKV_AWS_110: "Ensure IAM policies does not allow privilege escalation"
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_107: "Ensure IAM policies does not allow credentials exposure"
  #checkov:skip=CKV_AWS_108: "Ensure IAM policies does not allow data exfiltration"
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"

  statement {

    # Ignore this check on tfsec - it causes a fail on resources *. The resource is required for patching purposes
    #tfsec:ignore:aws-iam-no-policy-wildcards
    actions = ["s3:*",
      "ec2:*",
      "ssm:*",
      "cloudwatch:*",
      "cloudformation:*",
      "iam:*",
      "lambda:*"
    ]
    # Ignore this check on tfsec - it causes a fail on resources *. The resource is required for patching purposes
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
}

resource "aws_iam_policy" "patch_manager" {
  name        = "patch-manager-iam-policy"
  description = "IAM Policy for the AWS-PatchAsgInstance automation script that runs as part of the module"
  path        = "/"
  policy      = data.aws_iam_policy_document.patch-manager-policy-doc.json
  tags        = var.tags
}

resource "aws_iam_role" "patch_manager" {
  # Ignore this check on tfsec - it causes a fail on resources *. The resource is required for patching purposes
  #tfsec:ignore:aws-iam-no-policy-wildcards

  name = "patch-manager-iam-role"
  tags = var.tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "ssm.amazonaws.com",
            "iam.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_manager" {
  role       = aws_iam_role.patch_manager.name
  policy_arn = aws_iam_policy.patch_manager.arn
}

resource "aws_ssm_maintenance_window" "patch_manager" {
  for_each = var.patch_schedules
  name     = format("%s-%s-%s", var.application_name, "maintenance-window", each.key)
  schedule = each.value
  duration = var.maintenance_window_duration
  cutoff   = var.maintenance_window_cutoff
  tags     = var.tags
}

resource "aws_ssm_maintenance_window_target" "patch_manager" {
  for_each      = var.patch_schedules
  window_id     = aws_ssm_maintenance_window.patch_manager[each.key].id
  name          = format("%s-%s", "maintenance-window-target", each.key)
  description   = "Targets of the maintenance window by tag key-value pair"
  resource_type = "INSTANCE"
  targets {
    key    = "tag:${var.patch_tag_key}"
    values = [each.key]
  }
}

resource "aws_ssm_maintenance_window_task" "patch_task" {
  for_each         = var.patch_schedules
  name             = format("%s-%s-%s", var.application_name, "patch-manager-task", each.key)
  description      = "Use AWS standard documents to patch the targeted instances in a controlled manner."
  max_concurrency  = 10
  max_errors       = 5
  priority         = 1
  task_type        = "AUTOMATION"
  task_arn         = "AWS-PatchInstanceWithRollback"
  window_id        = aws_ssm_maintenance_window.patch_manager[each.key].id
  service_role_arn = aws_iam_role.patch_manager.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_manager[each.key].id]
  }

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "InstanceId"
        values = ["{{RESOURCE_ID}}"]
      }
    }
  }
}

########### Optionals ############

resource "aws_resourcegroups_group" "patch_manager" {
  for_each = var.patch_schedules
  name     = format("%s-%s-%s", var.application_name, "patch-manager", each.key)
  tags     = var.tags
  resource_query {
    query = <<JSON
{
   "ResourceTypeFilters":[
      "AWS::EC2::Instance"
   ],
   "TagFilters":[
      {
         "Key":"${var.patch_tag_key}",
         "Values":["${each.key}"]
      }
   ]
}
JSON
  }
}

resource "aws_ssm_patch_baseline" "patch_manager" {
  for_each = var.patch_classifications

  name             = format("%s-%s-%s", var.application_name, each.key, "baseline")
  description      = join(" ", ["Applies", join(", ", lookup(var.patch_classifications, each.key)), "catagories to", each.key, "OS."])
  operating_system = each.key
  rejected_patches = var.rejected_patches
  tags             = var.tags

  approval_rule {
    approve_after_days = lookup(var.approval_days, var.environment)
    compliance_level   = var.compliance_level

    patch_filter {
      key    = "PRODUCT"
      values = var.product
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = lookup(var.patch_classifications, each.key)
    }

    patch_filter {
      key    = each.key == "WINDOWS" ? "MSRC_SEVERITY" : "SEVERITY"
      values = var.severity
    }
  }
}

resource "aws_ssm_default_patch_baseline" "patch_manager" {
  for_each = var.patch_classifications

  baseline_id      = aws_ssm_patch_baseline.patch_manager[each.key].id
  operating_system = each.key
}

# Definition updates (Defender anti-virus etc) do not require a reboot and should be applied daily.

resource "aws_ssm_maintenance_window" "definition_updates" {
  count    = (var.daily_definition_update == true) ? 1 : 0
  name     = format("%s-%s-%s", var.application_name, "maintenance-window", "definition-updates")
  schedule = "cron(0 8 * * ? *)" # Every day @8am, (Required) The schedule of the Maintenance Window in the form of a cron expression.
  duration = 2                   # (Required) This will only take a few mins max, but is counted in hours and needs to be +1 more than the cutoff.
  cutoff   = 1                   # (Required) The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution.
  tags     = var.tags
}

resource "aws_ssm_maintenance_window_target" "definition_updates" {
  count         = (var.daily_definition_update == true) ? 1 : 0
  window_id     = aws_ssm_maintenance_window.definition_updates[0].id
  name          = format("%s-%s", "maintenance-window-target", "definition-updates")
  description   = "Targets of the Windows definition updates maintenance window by tag key (any value)."
  resource_type = "INSTANCE"

  targets {
    key    = "tag:os-type"
    values = ["Windows"]
  }
}

resource "aws_ssm_maintenance_window_task" "definition_updates" {
  count            = (var.daily_definition_update == true) ? 1 : 0
  name             = format("%s-%s-%s", var.application_name, "patch-manager-task", "definition-updates")
  description      = "Use AWS standard documents to patch the targeted instances in a controlled manner."
  max_concurrency  = 10
  max_errors       = 5
  priority         = 1
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-InstallWindowsUpdates"
  window_id        = aws_ssm_maintenance_window.definition_updates[0].id
  service_role_arn = aws_iam_role.patch_manager.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.definition_updates[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      document_version = "$LATEST"
      parameter {
        name   = "Action"
        values = ["Install"]
      }
      parameter {
        name   = "AllowReboot"
        values = ["False"]
      }
      parameter {
        name   = "Categories"
        values = ["DefinitionUpdates"]
      }
    }
  }
}
