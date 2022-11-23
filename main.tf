data "aws_vpc" "shared" {
  tags = {
    "Name" = var.vpc_all
  }
}

# Terraform module which creates S3 Bucket resources for Load Balancer Access Logs on AWS.

module "s3-bucket" {
  count  = var.existing_bucket_name == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  bucket_prefix       = "${var.application_name}-ssm-patching-logs"
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
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]
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

    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]

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
      var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}" : module.s3-bucket[0].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}


###################################################################
############################# SSM #################################
###################################################################

###### IAM  #####

data "aws_iam_policy_document" "ssm-admin-policy-doc" {
  statement {
    actions = ["s3:*",
                "ec2:*",
                "ssm:*",
                "cloudwatch:*",
                "cloudformation:*",
                "iam:*",
                "lambda:*"
            ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm-patching-iam-policy" {
  name        = "ssm-patching-iam-policy"
  description = "IAM Policy for the AWS-PatchAsgInstance automation script that runs as part of the module"
  path        = "/"
  policy      = data.aws_iam_policy_document.ssm-admin-policy-doc.json
}

resource "aws_iam_role" "ssm-patching-iam-role" {
  name        = "ssm-patching-iam-role"
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

resource "aws_iam_role_policy_attachment" "ssm-admin-automation" {
  role       = aws_iam_role.ssm-patching-iam-role.name
  policy_arn = aws_iam_policy.ssm-patching-iam-policy.arn
}


###### ssm maintenance window #####

resource "aws_ssm_maintenance_window" "ssm-maintenance-window" {
  name     = "${var.application_name}-maintenance-window"
  schedule = "${var.patch_schedule}"
  duration = 4
  cutoff   = 8
}

###### ssm maintenance target #####

resource "aws_ssm_maintenance_window_target" "ssm-maintenance-window-target" {
  window_id     = aws_ssm_maintenance_window.ssm-maintenance-window.id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patching"
    values = ["yes"]
  }
}

###### ssm automation task #####

resource "aws_ssm_maintenance_window_task" "ssm-maintenance-window-automation-task" {
  name             = "${var.application_name}-automation-patching-task"
  max_concurrency  = 20
  max_errors       = 10
  priority         = 1
  task_type        = "AUTOMATION"
  task_arn         = "AWS-PatchAsgInstance"
  window_id        = aws_ssm_maintenance_window.ssm-maintenance-window.id
  service_role_arn = aws_iam_role.ssm-patching-iam-role.arn

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.ssm-maintenance-window-target.*.id
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
        values = ["${var.application_name}-ssm-patching-logs"]
      }
    }
  }
}


########### Optionals ############

###### Resource Group  #####

resource "aws_resourcegroups_group" "patch-resource-group" {
  name = "${var.application_name}-patch-group"
  resource_query {
    query = <<JSON
{
	"ResourceTypeFilters": [
		"AWS::EC2::Instance"
	],
	"TagFilters": [{
		"Key": "Patching",
		"Values": ["yes", "true", "YES", "Yes", "TRUE"]
	}]
}
JSON
  }
}

###### Approval rule #####

resource "aws_ssm_patch_baseline" "patch-baseline-poc" {
  name             = "${var.application_name}-baseline"
  operating_system = var.operating_system

  approval_rule {
    approve_after_days = var.approval_days
    compliance_level   = var.compliance_level

    patch_filter {
      key    = "CLASSIFICATION"
      values = var.patch_classification
    }
  }
}