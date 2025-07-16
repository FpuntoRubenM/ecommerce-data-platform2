# /**
 * =============================================================================
 * MÓDULO IAM - ROLES Y POLÍTICAS DE SEGURIDAD
 * =============================================================================
 * 
 * Autor: Ruben Martin
 * Fecha: 2025-07-16
 * Versión: 2.0.0
 * 
 * Descripción: Módulo para gestión de roles y políticas IAM siguiendo el
 * principio de menor privilegio. Incluye roles específicos para cada servicio
 * con permisos mínimos necesarios.
 * 
 * Principios de seguridad implementados:
 * - Principio de menor privilegio
 * - Separación de responsabilidades
 * - Auditoría y trazabilidad
 * - Rotación de credenciales
 * 
 * =============================================================================
 */

# Obtener información de la cuenta AWS actual
data "aws_caller_identity" "current" {}

# Obtener información de la región actual
data "aws_region" "current" {}

# =============================================================================
# ROL PARA KINESIS DATA STREAMS
# =============================================================================

# Documento de política de confianza para Kinesis
data "aws_iam_policy_document" "kinesis_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["kinesis.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.common_name]
    }
  }
}

# Rol IAM para Kinesis Data Streams
resource "aws_iam_role" "kinesis_role" {
  name               = "${var.common_name}-kinesis-role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_assume_role.json
  description        = "Rol IAM para Kinesis Data Streams - Creado por Ruben Martin"
  
  tags = merge(var.common_tags, {
    Name        = "${var.common_name}-kinesis-role"
    Service     = "Kinesis"
    Purpose     = "DataStreaming"
    SecurityLevel = "Standard"
  })
}

# Documento de política para Kinesis Data Streams
data "aws_iam_policy_document" "kinesis_policy" {
  # Permisos para Kinesis Data Streams
  statement {
    effect = "Allow"
    
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
      "kinesis:ListShards"
    ]
    
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${var.common_name}-*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
  
  # Permisos para CloudWatch Logs
  statement {
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesis/${var.common_name}*"
    ]
  }
  
  # Permisos para KMS (cifrado)
  statement {
    effect = "Allow"
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["kinesis.${var.aws_region}.amazonaws.com"]
    }
  }
}

# Política IAM para Kinesis
resource "aws_iam_policy" "kinesis_policy" {
  name        = "${var.common_name}-kinesis-policy"
  description = "Política para Kinesis Data Streams con permisos mínimos - Autor: Ruben Martin"
  policy      = data.aws_iam_policy_document.kinesis_policy.json
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-kinesis-policy"
    Service = "Kinesis"
  })
}

# Adjuntar política al rol de Kinesis
resource "aws_iam_role_policy_attachment" "kinesis_policy_attachment" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = aws_iam_policy.kinesis_policy.arn
}

# =============================================================================
# ROL PARA KINESIS DATA FIREHOSE
# =============================================================================

# Documento de política de confianza para Firehose
data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.common_name]
    }
  }
}

# Rol IAM para Kinesis Data Firehose
resource "aws_iam_role" "firehose_role" {
  name               = "${var.common_name}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  description        = "Rol IAM para Kinesis Data Firehose - Creado por Ruben Martin"
  
  tags = merge(var.common_tags, {
    Name          = "${var.common_name}-firehose-role"
    Service       = "Firehose"
    Purpose       = "DataDelivery"
    SecurityLevel = "Standard"
  })
}

# Documento de política para Firehose
data "aws_iam_policy_document" "firehose_policy" {
  # Permisos para S3
  statement {
    effect = "Allow"
    
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }
  
  # Permisos para Kinesis Data Streams (origen)
  statement {
    effect = "Allow"
    
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${var.common_name}-*"
    ]
  }
  
  # Permisos para CloudWatch Logs
  statement {
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesisfirehose/${var.common_name}*"
    ]
  }
  
  # Permisos para KMS
  statement {
    effect = "Allow"
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [
        "s3.${var.aws_region}.amazonaws.com",
        "firehose.${var.aws_region}.amazonaws.com"
      ]
    }
  }
  
  # Permisos para Redshift (carga de datos)
  statement {
    effect = "Allow"
    
    actions = [
      "redshift:DescribeClusters",
      "redshift:DescribeClusterParameters"
    ]
    
    resources = [
      "arn:aws:redshift:${var.aws_region}:${var.account_id}:cluster:${var.common_name}-*"
    ]
  }
}

# Política IAM para Firehose
resource "aws_iam_policy" "firehose_policy" {
  name        = "${var.common_name}-firehose-policy"
  description = "Política para Kinesis Data Firehose con permisos específicos - Autor: Ruben Martin"
  policy      = data.aws_iam_policy_document.firehose_policy.json
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-firehose-policy"
    Service = "Firehose"
  })
}

# Adjuntar política al rol de Firehose
resource "aws_iam_role_policy_attachment" "firehose_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

# =============================================================================
# ROL PARA REDSHIFT
# =============================================================================

# Documento de política de confianza para Redshift
data "aws_iam_policy_document" "redshift_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.common_name]
    }
  }
}

# Rol IAM para Redshift
resource "aws_iam_role" "redshift_role" {
  name               = "${var.common_name}-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume_role.json
  description        = "Rol IAM para Amazon Redshift - Creado por Ruben Martin"
  
  tags = merge(var.common_tags, {
    Name          = "${var.common_name}-redshift-role"
    Service       = "Redshift"
    Purpose       = "DataWarehouse"
    SecurityLevel = "High"
  })
}

# Documento de política para Redshift
data "aws_iam_policy_document" "redshift_policy" {
  # Permisos para S3 (lectura de datos)
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
  
  # Permisos para CloudWatch Logs
  statement {
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/redshift/${var.common_name}*"
    ]
  }
  
  # Permisos para KMS
  statement {
    effect = "Allow"
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [
        "s3.${var.aws_region}.amazonaws.com",
        "redshift.${var.aws_region}.amazonaws.com"
      ]
    }
  }
  
  # Permisos para Enhanced VPC Routing
  statement {
    effect = "Allow"
    
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

# Política IAM para Redshift
resource "aws_iam_policy" "redshift_policy" {
  name        = "${var.common_name}-redshift-policy"
  description = "Política para Amazon Redshift con permisos mínimos - Autor: Ruben Martin"
  policy      = data.aws_iam_policy_document.redshift_policy.json
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-redshift-policy"
    Service = "Redshift"
  })
}

# Adjuntar política al rol de Redshift
resource "aws_iam_role_policy_attachment" "redshift_policy_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_policy.arn
}

# =============================================================================
# ROL PARA KINESIS ANALYTICS
# =============================================================================

# Documento de política de confianza para Kinesis Analytics
data "aws_iam_policy_document" "analytics_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

# Rol IAM para Kinesis Analytics
resource "aws_iam_role" "analytics_role" {
  name               = "${var.common_name}-analytics-role"
  assume_role_policy = data.aws_iam_policy_document.analytics_assume_role.json
  description        = "Rol IAM para Kinesis Data Analytics - Creado por Ruben Martin"
  
  tags = merge(var.common_tags, {
    Name          = "${var.common_name}-analytics-role"
    Service       = "KinesisAnalytics"
    Purpose       = "DataProcessing"
    SecurityLevel = "Standard"
  })
}

# Documento de política para Kinesis Analytics
data "aws_iam_policy_document" "analytics_policy" {
  # Permisos para Kinesis Data Streams (lectura)
  statement {
    effect = "Allow"
    
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${var.common_name}-*"
    ]
  }
  
  # Permisos para Kinesis Data Streams (escritura a streams de salida)
  statement {
    effect = "Allow"
    
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${var.common_name}-*-output"
    ]
  }
  
  # Permisos para CloudWatch Logs
  statement {
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesisanalytics/${var.common_name}*"
    ]
  }
}

# Política IAM para Kinesis Analytics
resource "aws_iam_policy" "analytics_policy" {
  name        = "${var.common_name}-analytics-policy"
  description = "Política para Kinesis Data Analytics - Autor: Ruben Martin"
  policy      = data.aws_iam_policy_document.analytics_policy.json
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-analytics-policy"
    Service = "KinesisAnalytics"
  })
}

# Adjuntar política al rol de Analytics
resource "aws_iam_role_policy_attachment" "analytics_policy_attachment" {
  role       = aws_iam_role.analytics_role.name
  policy_arn = aws_iam_policy.analytics_policy.arn
}

# =============================================================================
# ROL PARA CLOUDWATCH Y MONITOREO
# =============================================================================

# Documento de política de confianza para CloudWatch
data "aws_iam_policy_document" "monitoring_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com",
        "monitoring.amazonaws.com",
        "logs.amazonaws.com"
      ]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

# Rol IAM para servicios de monitoreo
resource "aws_iam_role" "monitoring_role" {
  name               = "${var.common_name}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role.json
  description        = "Rol IAM para servicios de monitoreo - Creado por Ruben Martin"
  
  tags = merge(var.common_tags, {
    Name          = "${var.common_name}-monitoring-role"
    Service       = "CloudWatch"
    Purpose       = "Monitoring"
    SecurityLevel = "Standard"
  })
}

# Política administrada para CloudWatch
resource "aws_iam_role_policy_attachment" "monitoring_cloudwatch" {
  role       = aws_iam_role.monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# =============================================================================
# GRUPO IAM PARA DESARROLLADORES
# =============================================================================

# Grupo IAM para desarrolladores con acceso limitado
resource "aws_iam_group" "developers" {
  name = "${var.common_name}-developers"
  path = "/"
}

# Documento de política para desarrolladores
data "aws_iam_policy_document" "developers_policy" {
  # Permisos de solo lectura para la mayoría de servicios
  statement {
    effect = "Allow"
    
    actions = [
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
      "s3:GetObject",
      "s3:ListBucket",
      "redshift:DescribeClusters",
      "redshift:DescribeClusterParameters",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
  
  # Denegar acciones destructivas
  statement {
    effect = "Deny"
    
    actions = [
      "kinesis:DeleteStream",
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "redshift:DeleteCluster",
      "kms:ScheduleKeyDeletion"
    ]
    
    resources = ["*"]
  }
}

# Política para desarrolladores
resource "aws_iam_policy" "developers_policy" {
  name        = "${var.common_name}-developers-policy"
  description = "Política de solo lectura para desarrolladores - Autor: Ruben Martin"
  policy      = data.aws_iam_policy_document.developers_policy.json
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-developers-policy"
    Purpose = "DeveloperAccess"
  })
}

# Adjuntar política al grupo de desarrolladores
resource "aws_iam_group_policy_attachment" "developers_policy_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developers_policy.arn
}

# =============================================================================
# VARIABLES DEL MÓDULO
# =============================================================================

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

variable "s3_bucket_arn" {
  description = "ARN del bucket S3"
  type        = string
}

variable "account_id" {
  description = "ID de la cuenta AWS"
  type        = string
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
}

# =============================================================================
# OUTPUTS DEL MÓDULO
# =============================================================================

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

/**
 * =============================================================================
 * NOTAS DE SEGURIDAD - AUTOR: RUBEN MARTIN
 * =============================================================================
 * 
 * 1. PRINCIPIO DE MENOR PRIVILEGIO:
 *    - Cada rol tiene solo los permisos mínimos necesarios
 *    - Condiciones adicionales para limitar el alcance
 *    - Separación clara de responsabilidades entre servicios
 * 
 * 2. MONITOREO Y AUDITORÍA:
 *    - Todos los roles están etiquetados para auditoría
 *    - CloudTrail registrará el uso de estos roles
 *    - Políticas restrictivas para desarrolladores
 * 
 * 3. CIFRADO Y SEGURIDAD:
 *    - Permisos KMS restringidos por servicio
 *    - Forzar cifrado en S3 a través de condiciones
 *    - ExternalId para prevenir ataques confused deputy
 * 
 * 4. MEJORES PRÁCTICAS:
 *    - Uso de assume role en lugar de usuarios con claves
 *    - Políticas administradas cuando sea apropiado
 *    - Documentación clara del propósito de cada rol
 * 
 * 5. REVISIONES REGULARES:
 *    - Revisar permisos regularmente
 *    - Rotar external IDs periódicamente
 *    - Auditar uso de roles con CloudTrail
 * 
 * =============================================================================
 */ "modules/iam/main.tf"
