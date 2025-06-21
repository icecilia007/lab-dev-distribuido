# -*- coding: utf-8 -*-
# File name infra/modules/sqs/variables.tf

variable "TagProject" {
  type = string
}

variable "TagEnv" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "sqs_name" {
  description = "Nome da fila sqs"
  type        = string
}
