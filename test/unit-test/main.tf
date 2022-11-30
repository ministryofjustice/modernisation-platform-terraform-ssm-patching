module "ssm-auto-patching" {
  source = "../../"
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids["testing-test"]
  application_name = local.application_name
  patch_schedule = "cron(30 17 ? * MON *)"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}