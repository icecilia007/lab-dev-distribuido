# -*- coding: utf-8 -*-
# File name infra/modules/ecr/variables.tf

variable "TagProject" {
  type = string
}

variable "TagEnv" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "region" {
  type = string
}

variable "repository_name" {
  description = "Nome do repositório ECR"
  type        = string
}

variable "image_tag_mutability" {
  description = "Mutabilidade da tag da imagem no ECR"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Ativa o scan da imagem no push"
  type        = bool
  default     = true
}

variable "days_lifecycle_policy" {
  description = "Número de imagens a reter no ciclo de vida"
  type        = number
  default     = 5
}


variable "folder" {
  description = "Pasta onde estão os arquivos para build da imagem"
  type        = string
  default     = ""
}

variable "files" {
  description = "Lista de arquivos a serem monitorados para trigger do build"
  type        = list(string)
  default     = []
}

variable "tag_image" {
  description = "Tag da imagem Docker"
  type        = string
  default     = "latest"
}
