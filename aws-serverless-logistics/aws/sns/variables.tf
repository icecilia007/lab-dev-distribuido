# -*- coding: utf-8 -*-
# File name infra/modules/sns/variables.tf

variable "TagProject" {
  type = string
}

variable "TagEnv" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "Name" {
  type = string
}


variable "emails_sns" {
  description = "Lista de e-mails para receber notificações do SNS"
  type        = list(string)
}
