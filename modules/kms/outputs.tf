output "key_id" {
  description = "ID de la clave KMS principal"
  value       = aws_kms_key.main.key_id
}

output "key_arn" {
  description = "ARN de la clave KMS principal"
  value       = aws_kms_key.main.arn
}

output "key_alias" {
  description = "Alias de la clave KMS principal"
  value       = aws_kms_alias.main.name
}

output "s3_key_id" {
  description = "ID de la clave KMS para S3"
  value       = aws_kms_key.s3.key_id
}

output "s3_key_arn" {
  description = "ARN de la clave KMS para S3"
  value       = aws_kms_key.s3.arn
}

output "redshift_key_id" {
  description = "ID de la clave KMS para Redshift"
  value       = aws_kms_key.redshift.key_id
}

output "redshift_key_arn" {
  description = "ARN de la clave KMS para Redshift"
  value       = aws_kms_key.redshift.arn
}

output "logs_key_id" {
  description = "ID de la clave KMS para CloudWatch Logs"
  value       = aws_kms_key.logs.key_id
}

output "logs_key_arn" {
  description = "ARN de la clave KMS para CloudWatch Logs"
  value       = aws_kms_key.logs.arn
}

output "all_key_ids" {
  description = "Mapa de todos los IDs de claves KMS"
  value = {
    main     = aws_kms_key.main.key_id
    s3       = aws_kms_key.s3.key_id
    redshift = aws_kms_key.redshift.key_id
    logs     = aws_kms_key.logs.key_id
  }
}

output "all_key_arns" {
  description = "Mapa de todos los ARNs de claves KMS"
  value = {
    main     = aws_kms_key.main.arn
    s3       = aws_kms_key.s3.arn
    redshift = aws_kms_key.redshift.arn
    logs     = aws_kms_key.logs.arn
  }
}
