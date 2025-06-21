#!/bin/bash
# -*- coding: utf-8 -*-
# File name modules/lambda_image/script.sh

FOLDER="${FOLDER}"
AWS_REGION="${AWS_REGION}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
ECR_REPO_NAME="${ECR_REPO_NAME}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
echo "FOLDER - $FOLDER"
echo "AWS_REGION - $AWS_REGION"
echo "AWS_ACCOUNT_ID - $AWS_ACCOUNT_ID"
echo "ECR_REPO_NAME - $ECR_REPO_NAME"
echo "IMAGE_TAG - $IMAGE_TAG"

ECR_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

CURRENT_ARCH=$(uname -m)
case $CURRENT_ARCH in
    x86_64)
        BUILD_PLATFORM="linux/amd64"
        echo "Detected x86_64 architecture - building for linux/amd64"
        ;;
    aarch64|arm64)
        BUILD_PLATFORM="linux/arm64"
        echo "Detected ARM64 architecture - building for linux/arm64"
        ;;
    *)
        BUILD_PLATFORM="linux/amd64"
        echo "Warning: Unknown architecture $CURRENT_ARCH, defaulting to linux/amd64"
        ;;
esac

ls -a
echo "pasta atual"
cd "../"
cd "$FOLDER"
ls -a

aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Building Docker image for platform: $BUILD_PLATFORM"
docker build --platform $BUILD_PLATFORM -t ${ECR_REPO_NAME} .
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REPO_URL}:${IMAGE_TAG}
docker push ${ECR_REPO_URL}:${IMAGE_TAG}

cd -

echo "Build and push completed successfully!"
echo "Image built for: $BUILD_PLATFORM"
echo "Image available at: ${ECR_REPO_URL}:${IMAGE_TAG}"
