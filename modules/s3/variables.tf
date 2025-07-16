variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
}

variable "common_name" {
  description = "Nombre común para recursos"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "retention_days" {
  description = "Días de retención para lifecycle policy"
  type        = number
}

variable "glacier_days" {
  description = "Días para transición a Glacier"
  type        = number
}

variable "kms_key_id" {
  description = "ID de la clave KMS para cifrado"
  type        = string
}

variable "vpc_endpoint_id" {
  description = "ID del VPC endpoint para S3"
  type        = string
}
