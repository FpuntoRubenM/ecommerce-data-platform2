output "bucket_name" {
  description = "Nombre del bucket S3 principal"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3 principal"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name del bucket S3"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "access_logs_bucket_name" {
  description = "Nombre del bucket de access logs"
  value       = aws_s3_bucket.access_logs.bucket
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda procesadora"
  value       = aws_lambda_function.s3_processor.function_name
}

output "replica_bucket_arn" {
  description = "ARN del bucket de replicación (si existe)"
  value       = var.environment == "prod" ? aws_s3_bucket.replica[0].arn : null
}
