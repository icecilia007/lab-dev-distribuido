
# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "logistics"
}

variable "jwt_secret" {
    description = "JWT secret key"
    type        = string
    default = "your-jwt-secret-key"
}