#!/bin/pwsh

$env:STACK_NAME='awsbootstrap' 
$env:REGION='us-east-1' 
$env:CLI_PROFILE='awsbootstrap'
$env:EC2_INSTANCE_TYPE='t2.micro' 

# S3 Bucket configuration for CodePipeline
# The below command is returing text that contains non-printable characters, not just the AWS account ID as expected.
#$env:AWS_ACCOUNT_ID= docker run --rm -it -v $env:userprofile\.aws:/root/.aws amazon/aws-cli sts get-caller-identity --profile awsbootstrap `
#  --query "Account" --output text 

#Instead of using Docker amazon-aws-cli
$env:AWS_ACCOUNT_ID=aws sts get-caller-identity --profile awsbootstrap --query "Account" --output text
$env:CODEPIPELINE_BUCKET=$env:STACK_NAME + '-' + $env:REGION + '-codepipeline-' + $env:AWS_ACCOUNT_ID

# Generate a personal access token with repo and admin:repo_hook
#    permissions from https://github.com/settings/tokens
$env:GH_ACCESS_TOKEN= Get-Content .\.github\aws-bootstrap-access-token -Raw
$env:GH_OWNER= Get-Content .\.github\aws-bootstrap-owner -Raw
$env:GH_REPO= Get-Content .\.github\aws-bootstrap-repo -Raw
$env:GH_BRANCH='main'

# Deploys static resources
Write-Output "`n`n=========== Deploying setup.yml ==========="
$env:STACK_NAME = $env:STACK_NAME + '-setup'
docker run --rm -it -v $env:userprofile\.aws:/root/.aws `
  -v $env:userprofile\code\aws-bootstrap:/root/aws-bootstrap amazon/aws-cli cloudformation deploy `
  --region $env:REGION `
  --profile $env:CLI_PROFILE `
  --stack-name $env:STACK_NAME `
  --template-file '/root/aws-bootstrap/setup.yml' `
  --no-fail-on-empty-changeset `
  --capabilities CAPABILITY_NAMED_IAM `
  --parameter-overrides `
    CodePipelineBucket=$env:CODEPIPELINE_BUCKET

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
    EC2InstanceType=$env:EC2_INSTANCE_TYPE `
    GitHubOwner=$env:GH_OWNER `
    GitHubRepo=$env:GH_REPO `
    GitHubBranch=$env:GH_BRANCH `
    GitHubPersonalAccessToken=$env:GH_ACCESS_TOKEN `
    CodePipelineBucket=$env:CODEPIPELINE_BUCKET