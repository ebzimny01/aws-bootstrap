#!/bin/pwsh

$env:STACK_NAME='awsbootstrap' 
$env:REGION='us-east-1' 
$env:CLI_PROFILE='awsbootstrap'
$env:EC2_INSTANCE_TYPE='t2.micro' 

# S3 Bucket configuration for CodePipeline
$env:AWS_ACCOUNT_ID='amazon/aws-cli sts get-caller-identity --profile awsbootstrap `
  --query "Account" --output text'
$env:CODEPIPELINE_BUCKET='$env:STACK_NAME-$env:REGION-codepipeline-$env:AWS_ACCOUNT_ID'

# Deploy the CloudFormation template
Write-Output "`n`n=========== Deploying main.yml ==========="
docker run --rm -it -v $env:userprofile\.aws:/root/.aws `
  -v $env:userprofile\code\aws-bootstrap:/root/aws-bootstrap amazon/aws-cli cloudformation deploy `
  --region $env:REGION `
  --profile $env:CLI_PROFILE `
  --stack-name $env:STACK_NAME `
  --template-file '/root/aws-bootstrap/main.yml' `
  --no-fail-on-empty-changeset `
  --capabilities CAPABILITY_NAMED_IAM `
  --parameter-overrides `
    EC2InstanceType=$env:EC2_INSTANCE_TYPE