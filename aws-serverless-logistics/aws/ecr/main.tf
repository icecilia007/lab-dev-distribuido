# -*- coding: utf-8 -*-
# File name infra/modules/ecr/main.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_ecr_repository" "this" {
  name                 = lower("${var.TagEnv}-${var.TagProject}-${var.repository_name}")
  image_tag_mutability = var.image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
  tags = var.tags
}


resource "aws_ecr_lifecycle_policy" "delete" {
  repository = aws_ecr_repository.this.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only the most recent images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.days_lifecycle_policy}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}


resource "null_resource" "run_script" {
  for_each = toset(var.files)
  triggers = {
    file = filesha256("${path.root}/../${var.folder}/${each.key}")
  }
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/script.sh && ${path.module}/script.sh"
    environment = {
      FOLDER         = var.folder
      AWS_REGION     = var.region
      AWS_ACCOUNT_ID = local.aws_account_id
      ECR_REPO_NAME  = aws_ecr_repository.this.name
      IMAGE_TAG      = var.tag_image
    }
    interpreter = ["/bin/bash", "-c"]
  }
}
