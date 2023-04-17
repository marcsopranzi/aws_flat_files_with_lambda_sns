# AWS Serverless ETL - Lambda - SNS

## AIM.
This is a serverless project to load flat files, process them, notify users and save the file as parquet for further ingestion in a database.

## How it works.
We use terraform to deploy AWS `Lambdas`, `SNS` and `S3` in *us-east-1*. The region can be updated in the Terraform variables and can be modified from within the Lambda's `Python3` code. The only manual steps are to set the password in AWS Secret Manager and in Slack. In Slack create channel and enable the webhooks, steps can be found here: https://docs.servicenow.com/en-US/bundle/utah-it-service-management/page/product/site-reliability-ops/task/create-webhook-url-channel-slack.html. In this project we are using *Slack* but others can be easily set up. Both the secret name and key are *slack-secret* 

In this scenario once the users upload a flat file to `S3` a trigger activates `Lambda`. `Lambda` will get the IM webhook password from AWS `Secret Manager` and proceed with the file manipulation using `Pandas`. It will later save the data in a different bucket with a date prefix, and inform users with an `AWS SNS` Push Notification Service once the task is finished.

## Further steps.
Add a `Lambda` step to ingest the data into `RDS` .
