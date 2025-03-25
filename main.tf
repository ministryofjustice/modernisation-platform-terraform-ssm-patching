locals {
  create_bucket = var.use_existing_bucket == false ? { "reports" = true } : {}
}

module "s3-bucket" {
  for_each = local.create_bucket
  source   = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636" # v8.2.0

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  bucket_prefix       = "${var.application_name}-patch-manager"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = var.force_destroy_bucket
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  # Ignore this check on tfsec - it causes a fail on resources *. The resource is required for patching purposes
  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]

    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket["reports"].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default.arn]
    }
  }
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket["reports"].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}" : module.s3-bucket["reports"].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}
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
}

resource "aws_iam_role" "patch_manager" {
  # Ignore this check on tfsec - it causes a fail on resources *. The resource is required for patching purposes
  #tfsec:ignore:aws-iam-no-policy-wildcards

  name = "patch-manager-iam-role"
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

resource "aws_ssm_maintenance_window" "this" {
  for_each = { for patch_schedule in keys(var.patch_schedules) : patch_schedule => var.patch_schedules[patch_schedule] }
  name     = format("%s-%s-%s", var.application_name, "maintenance-window", each.key)
  schedule = each.value                      # (Required) The schedule of the Maintenance Window in the form of a cron expression.
  duration = var.maintenance_window_duration # (Required) The duration of the Maintenance Window in hours.
  cutoff   = var.maintenance_window_cutoff   # (Required) The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution.
}

resource "aws_ssm_maintenance_window_target" "this" {
  for_each      = { for patch_schedule in keys(var.patch_schedules) : patch_schedule => var.patch_schedules[patch_schedule] }
  window_id     = aws_ssm_maintenance_window.this[each.key].id
  name          = format("%s-%s", "maintenance-window-target", each.key)
  description   = "Targets of the maintenance window by tag key-value pair"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:${var.patch_tag_key}"
    values = [each.key]
  }
}

resource "aws_ssm_maintenance_window_task" "this" {
  for_each         = { for patch_schedule in keys(var.patch_schedules) : patch_schedule => var.patch_schedules[patch_schedule] }
  name             = format("%s-%s-%s", var.application_name, "patch-manager-task", each.key)
  description      = "Use AWS standard documents to patch the targeted instances in a controlled manner."
  max_concurrency  = 10
  max_errors       = 5
  priority         = 1
  task_type        = "AUTOMATION"
  task_arn         = "AWS-PatchInstanceWithRollback"
  window_id        = aws_ssm_maintenance_window.this[each.key].id
  service_role_arn = aws_iam_role.patch_manager.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.this[each.key].id]
  }

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "InstanceId"
        values = ["{{RESOURCE_ID}}"]
      }
      parameter {
        name   = "ReportS3Bucket"
        values = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}" : "${module.s3-bucket["reports"].bucket.id}"]
      }
    }
  }
}

########### Optionals ############

resource "aws_resourcegroups_group" "patch_manager" {
  for_each = { for patch_schedule in keys(var.patch_schedules) : patch_schedule => var.patch_schedules[patch_schedule] }
  name     = format("%s-%s-%s", var.application_name, "patch-manager", each.key)
  resource_query {
    query = <<JSON
{
   "ResourceTypeFilters":[
      "AWS::EC2::Instance"
   ],
   "TagFilters":[
      {
         "Key":"patch-manager",
         "Values":[${each.key}]
      }
   ]
}
JSON
  }
}

resource "aws_ssm_patch_baseline" "patch_manager" {
  name             = format("%s-%s-%s", var.application_name, var.operating_system, "baseline")
  description      = join(" ", ["Applies", join(", ", var.patch_classification), "to", var.operating_system, "OS."])
  operating_system = var.operating_system
  rejected_patches = var.rejected_patches

  approval_rule {
    approve_after_days = var.approval_days
    compliance_level   = var.compliance_level

    patch_filter {
      key    = "PRODUCT"
      values = var.product
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = var.patch_classification
    }

    patch_filter {
      key    = var.operating_system == "WINDOWS" ? "MSRC_SEVERITY" : "SEVERITY"
      values = var.severity
    }
  }
}

resource "aws_ssm_default_patch_baseline" "patch_manager" {
  baseline_id      = aws_ssm_patch_baseline.patch_manager.id
  operating_system = var.operating_system
}

# Definition updates (Defender anti-virus etc) do not require a reboot and should be applied daily.

resource "aws_ssm_maintenance_window" "definition_updates" {
  count    = (var.operating_system == "WINDOWS" && var.daily_definition_update == true) ? 1 : 0
  name     = format("%s-%s-%s", var.application_name, "maintenance-window", "definition-updates")
  schedule = "cron(0 8 * * *)" # Every day @8am, (Required) The schedule of the Maintenance Window in the form of a cron expression.
  duration = 2                 # (Required) This will only take a few mins max, but is counted in hours and needs to be +1 more than the cutoff.
  cutoff   = 1                 # (Required) The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution.
}

resource "aws_ssm_maintenance_window_target" "definition_updates" {
  count         = (var.operating_system == "WINDOWS" && var.daily_definition_update == true) ? 1 : 0
  window_id     = aws_ssm_maintenance_window.definition_updates[0].id
  name          = format("%s-%s", "maintenance-window-target", "definition-updates")
  description   = "Targets of the Windows definition updates maintenance window by tag key (any value)."
  resource_type = "INSTANCE"

  targets {
    key    = "tag:${var.patch_tag_key}"
    values = keys(var.patch_schedules)
  }
}

resource "aws_ssm_maintenance_window_task" "definition_updates" {
  count            = (var.operating_system == "WINDOWS" && var.daily_definition_update == true) ? 1 : 0
  name             = format("%s-%s-%s", var.application_name, "patch-manager-task", "definition-updates")
  description      = "Use AWS standard documents to patch the targeted instances in a controlled manner."
  max_concurrency  = 10
  max_errors       = 5
  priority         = 1
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
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
        name   = "InstanceId"
        values = ["{{RESOURCE_ID}}"]
      }
      parameter {
        name   = "ReportS3Bucket"
        values = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}" : "${module.s3-bucket["reports"].bucket.id}"]
      }
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["NoReboot"]
      }
      parameter {
        name   = "Classification"
        values = ["DefinitionUpdates"]
      }
    }
  }
}
