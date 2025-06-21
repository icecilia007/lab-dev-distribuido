# -*- coding: utf-8 -*-
# File name infra/modules/iam/variables.tf

variable "TagProject" {
  type = string
}

variable "TagEnv" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "role_name" {
  description = "Nome da IAM Role"
  type        = string
}

variable "assume_role_policy" {
  description = "Policy JSON de assumção de role (assume role)"
  type        = string
}

variable "policy_name" {
  description = "Nome da IAM Policy"
  type        = string
  default     = ""
}

variable "policy_description" {
  description = "Descrição da IAM Policy"
  type        = string
  default     = ""
}

variable "policy_document" {
  description = "Documento JSON da policy"
  type        = string
  default     = ""
}

variable "attach_policies" {
  description = "Lista de ARNs de policies a serem associadas à role"
  type        = list(string)
  default     = []
}
