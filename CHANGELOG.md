## v4.0.0 Enabling multiple OSes and Schedules

FEATURES:

This release sees many improvements and minor fixes and requires some changes to input arguments to integrate multiple patch groups/schedules for single or multiple OSes with a per OS baseline all based on a single module call per AWS account. This dramamatically reduces the amount of associated duplicate resources required to support multiple schedules and/or OSes in each account.

When targeting the "WINDOWS" OS it also optionally creates a separate definition-only update schedule (that doesn't require reboots) which allows defender etc to receive updates on an MS recommended daily basis.

As documented in the updated README.md, including more comprehensive usage examples.

NOTES:

This version removes the archiving of reports to S3 bucket to reduce complexity and cost, as all results and Patch compliance findings are exported to Security Hub by default.

Variable changes:

- environment (string), added to drive the default approval days (Required)
- approval_days map(number), was a string, now a map of numbers based on the environment with appropriate defaults.
- patch_schedule (string), has been replaced with patch_schedules map(string), this maps named patch groups, from the value of the patch_tag_key tag, with a cron schedule.
- suffix has been dropped, this is derived from the patch_schedule key.
- patch_classification (string), has been replaced with patch_classifications map(list(string)), this maps OS with a list of classifications. (Required)
- maintenance_window_cutoff and maintenance_window_duration (number) are now optionally configurable rather than hard coded.
- patch_tag_key replaces patch_key for clarity.
- daily_definition_update added to optionally control the creation of the daily Windows OS definition update schedule.
