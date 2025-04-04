module "ssm_auto_patching" {
  source = "../../"
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids["testing-test"]
  application_name = local.application_name
  environment      = "test"
  patch_schedules = {
    group1 = "cron(30 17 ? * MON *)"
  }
  patch_classifications = {
    WINDOWS = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"]
  }
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}
