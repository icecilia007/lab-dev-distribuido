#!/bin/bash
set -e

echo "🚀 Deploying AWS Serverless Logistics Platform..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Initialize Terraform
echo "📋 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📊 Planning Terraform deployment..."
terraform plan -var-file="terraform.tfvars"

# Ask for confirmation
echo "🤔 Do you want to proceed with the deployment? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🏗️  Applying Terraform configuration..."
    terraform apply -var-file="terraform.tfvars" -auto-approve
    
    echo "✅ Deployment completed!"
    echo ""
    echo "📄 Outputs:"
    terraform output
    
    echo ""
    echo "🎯 Next steps:"
    echo "1. Update your Flutter app with the new API Gateway URL"
    echo "2. Test the endpoints using the provided URLs"
    echo "3. Monitor the Lambda functions in AWS Console"
else
    echo "❌ Deployment cancelled."
    exit 1
fi