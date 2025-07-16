output "kinesis_role_arn" {
  description = "ARN del rol IAM para Kinesis Data Streams"
  value       = aws_iam_role.kinesis_role.arn
}

output "firehose_role_arn" {
  description = "ARN del rol IAM para Kinesis Data Firehose"
  value       = aws_iam_role.firehose_role.arn
}

output "redshift_role_arn" {
  description = "ARN del rol IAM para Amazon Redshift"
  value       = aws_iam_role.redshift_role.arn
}

output "analytics_role_arn" {
  description = "ARN del rol IAM para Kinesis Data Analytics"
  value       = aws_iam_role.analytics_role.arn
}

output "monitoring_role_arn" {
  description = "ARN del rol IAM para servicios de monitoreo"
  value       = aws_iam_role.monitoring_role.arn
}

output "developers_group_name" {
  description = "Nombre del grupo IAM para desarrolladores"
  value       = aws_iam_group.developers.name
}
