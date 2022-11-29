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

	maintenanceWindowId := terraform.Output(t, terraformOptions, "maintenance-window-id")
	patchResourceGroupArn := terraform.Output(t, terraformOptions, "patch-resource-group-arn")

	assert.Regexp(t, regexp.MustCompile(`^*`), maintenanceWindowId)
	assert.Regexp(t, regexp.MustCompile(`^*`), patchResourceGroupArn)
}