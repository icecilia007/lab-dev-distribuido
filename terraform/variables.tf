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

variable "sender_emails" {
  description = "Lista de endereços de email para verificação no SES"
  type        = list(string)
  default     = [
    "arihenriquedev@hotmail.com",
    "icsbarbosa@sga.pucminas.br",
    "g2002souzajardim@gmail.com",
    "1457902@sga.pucminas.br",
    "g2002souzajardimaugusto@gmail.com"
  ]

  validation {
    condition = length(var.sender_emails) > 0
    error_message = "A lista de emails não pode estar vazia."
  }

  validation {
    condition = alltrue([
      for email in var.sender_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "Todos os emails devem ter um formato válido."
  }
}