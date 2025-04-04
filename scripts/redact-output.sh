#!/bin/bash

# Based on: https://github.com/ministryofjustice/opg-org-infra/blob/main/scripts/redact_output.sh

sed -e 's/AWS_SECRET_ACCESS_KEY".*/<REDACTED>/g' \
    -e 's/AWS_ACCESS_KEY_ID".*/<REDACTED>/g' \
    -e 's/$AWS_SECRET_ACCESS_KEY".*/<REDACTED>/g' \
    -e 's/$AWS_ACCESS_KEY_ID".*/<REDACTED>/g' \
    -e 's/\[id=.*\]/\[id=<REDACTED>\]/g' \
    -e 's/::[0-9]\{12\}:/::REDACTED:/g' \
    -e 's/:[0-9]\{12\}:/:REDACTED:/g' \
    -e 's/mw-[0-9a-f]\{17\}/mw-REDACTED/g' \
    -e 's/[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}/REDACTED-xxxx-xxxx-xxxx-xxxxxxxxxxxx/g'
