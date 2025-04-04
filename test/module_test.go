package main

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"regexp"
	"testing"
)

func TestModule(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./unit-test",
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	maintenanceWindowIds := terraform.Output(t, terraformOptions, "maintenance_window_ids")
	patchResourceGroupArns := terraform.Output(t, terraformOptions, "patch_resource_group_arns")
	maintenanceWindowTargetIds := terraform.Output(t, terraformOptions, "maintenance_window_target_ids")
    iamPolicyArn := terraform.Output(t, terraformOptions, "iam_policy_arn")

	assert.Regexp(t, regexp.MustCompile(`^\[mw-[^,]+(,mw-[^,]+)*\]$`), maintenanceWindowIds)
	assert.Regexp(t, regexp.MustCompile(`^\[arn:aws:resource-groups:*`), patchResourceGroupArns)
	assert.Regexp(t, regexp.MustCompile(`^*`), maintenanceWindowTargetIds)
    assert.Regexp(t, regexp.MustCompile(`^arn:aws:iam:*`), iamPolicyArn)
}
