variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "sender_email" {
  description = "Email address for sending notifications (will be verified in SES)"
  type        = string
  default     = "arihenriquedev@hotmail.com"
}