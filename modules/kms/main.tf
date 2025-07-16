# /**
 * =============================================================================
 * MÓDULO KMS - GESTIÓN DE CLAVES DE CIFRADO
 * =============================================================================
 * 
 * Autor: Ruben Martin
 * Fecha: 2025-07-16
 * Versión: 2.0.0
 * 
 * Descripción: Módulo para gestión de claves KMS (Key Management Service)
 * para cifrado de datos en reposo y en tránsito. Implementa rotación 
 * automática, políticas de acceso granulares y auditoría completa.
 * 
 * Características implementadas:
 * - Rotación automática de claves
 * - Políticas de acceso basadas en roles
 * - Auditoría completa con CloudTrail
 * - Alias para facilitar gestión
 * - Claves específicas por servicio
 * - Protección contra eliminación accidental
 * 
 * =============================================================================
 */

# Obtener información de la cuenta AWS actual
data "aws_caller_identity" "current" {}

# Obtener información de la región actual
data "aws_region" "current" {}

# =============================================================================
# CLAVE KMS PRINCIPAL PARA LA PLATAFORMA
# =============================================================================

# Documento de política para la clave KMS principal
data "aws_iam_policy_document" "kms_key_policy" {
  # Permitir acceso completo a la cuenta root
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    
    actions   = ["kms:*"]
    resources = ["*"]
  }
  
  # Permitir a los administradores gestionar la clave
  statement {
    sid    = "AllowKeyAdministration"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-admin-role"
      ]
    }
    
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }
  }
  
  # Permitir uso de la clave para servicios específicos
  statement {
    sid    = "AllowServiceUsage"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-kinesis-role",
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-firehose-role",
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-redshift-role",
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-lambda-*"
      ]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${data.aws_region.current.name}.amazonaws.com",
        "kinesis.${data.aws_region.current.name}.amazonaws.com",
        "firehose.${data.aws_region.current.name}.amazonaws.com",
        "redshift.${data.aws_region.current.name}.amazonaws.com",
        "lambda.${data.aws_region.current.name}.amazonaws.com",
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
  
  # Permitir acceso desde servicios AWS específicos
  statement {
    sid    = "AllowAWSServices"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com",
        "kinesis.amazonaws.com",
        "firehose.amazonaws.com",
        "redshift.amazonaws.com",
        "lambda.amazonaws.com",
        "logs.amazonaws.com",
        "cloudwatch.amazonaws.com"
      ]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
  
  # Permitir acceso a roles específicos para S3
  statement {
    sid    = "AllowS3Roles"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-firehose-role",
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-lambda-*"
      ]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

# Clave KMS específica para S3
resource "aws_kms_key" "s3" {
  description              = "Clave KMS para S3 ${var.project_name} - Creada por Ruben Martin"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation     = true
  deletion_window_in_days = 10
  
  policy = data.aws_iam_policy_document.s3_kms_policy.json
  
  tags = merge(var.common_tags, {
    Name       = "${var.common_name}-s3-key"
    Purpose    = "S3Encryption"
    Service    = "S3"
    KeyType    = "ServiceSpecific"
    Author     = "Ruben Martin"
  })
}

# Alias para la clave de S3
resource "aws_kms_alias" "s3" {
  name          = "alias/${var.common_name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# =============================================================================
# CLAVE KMS ESPECÍFICA PARA REDSHIFT
# =============================================================================

# Documento de política para la clave de Redshift
data "aws_iam_policy_document" "redshift_kms_policy" {
  # Acceso completo para la cuenta root
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    
    actions   = ["kms:*"]
    resources = ["*"]
  }
  
  # Acceso específico para Redshift
  statement {
    sid    = "AllowRedshiftService"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
  
  # Permitir acceso al rol de Redshift
  statement {
    sid    = "AllowRedshiftRole"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:role/${var.common_name}-redshift-role"
      ]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
  }
}

# Clave KMS específica para Redshift
resource "aws_kms_key" "redshift" {
  description              = "Clave KMS para Redshift ${var.project_name} - Creada por Ruben Martin"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation     = true
  deletion_window_in_days = 10
  
  policy = data.aws_iam_policy_document.redshift_kms_policy.json
  
  tags = merge(var.common_tags, {
    Name       = "${var.common_name}-redshift-key"
    Purpose    = "RedshiftEncryption"
    Service    = "Redshift"
    KeyType    = "ServiceSpecific"
    Author     = "Ruben Martin"
  })
}

# Alias para la clave de Redshift
resource "aws_kms_alias" "redshift" {
  name          = "alias/${var.common_name}-redshift"
  target_key_id = aws_kms_key.redshift.key_id
}

# =============================================================================
# CLAVE KMS PARA CLOUDWATCH LOGS
# =============================================================================

# Documento de política para CloudWatch Logs
data "aws_iam_policy_document" "logs_kms_policy" {
  # Acceso completo para la cuenta root
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    
    actions   = ["kms:*"]
    resources = ["*"]
  }
  
  # Acceso específico para CloudWatch Logs
  statement {
    sid    = "AllowCloudWatchLogsService"
    effect = "Allow"
    
    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${var.account_id}:log-group:*"]
    }
  }
}

# Clave KMS para CloudWatch Logs
resource "aws_kms_key" "logs" {
  description              = "Clave KMS para CloudWatch Logs ${var.project_name} - Creada por Ruben Martin"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation     = true
  deletion_window_in_days = 7  # Menor tiempo para logs
  
  policy = data.aws_iam_policy_document.logs_kms_policy.json
  
  tags = merge(var.common_tags, {
    Name       = "${var.common_name}-logs-key"
    Purpose    = "LogsEncryption"
    Service    = "CloudWatchLogs"
    KeyType    = "ServiceSpecific"
    Author     = "Ruben Martin"
  })
}

# Alias para la clave de CloudWatch Logs
resource "aws_kms_alias" "logs" {
  name          = "alias/${var.common_name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# =============================================================================
# GRANTS PARA SERVICIOS ESPECÍFICOS
# =============================================================================

# Grant para Kinesis Data Firehose
resource "aws_kms_grant" "firehose_grant" {
  name              = "${var.common_name}-firehose-grant"
  key_id            = aws_kms_key.main.key_id
  grantee_principal = "arn:aws:iam::${var.account_id}:role/${var.common_name}-firehose-role"
  
  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "ReEncryptTo",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey"
  ]
  
  constraints {
    encryption_context_equals = {
      "aws:kinesis:arn" = "arn:aws:kinesis:${data.aws_region.current.name}:${var.account_id}:stream/${var.common_name}-*"
    }
  }
}

# Grant para Lambda functions
resource "aws_kms_grant" "lambda_grant" {
  name              = "${var.common_name}-lambda-grant"
  key_id            = aws_kms_key.s3.key_id
  grantee_principal = "arn:aws:iam::${var.account_id}:role/${var.common_name}-lambda-*"
  
  operations = [
    "Encrypt",
    "Decrypt",
    "GenerateDataKey",
    "DescribeKey"
  ]
  
  constraints {
    encryption_context_equals = {
      "aws:s3:arn" = "arn:aws:s3:::${var.common_name}-*"
    }
  }
}

# =============================================================================
# CLOUDWATCH ALARMS PARA MONITOREO DE CLAVES
# =============================================================================

# Alarma para uso excesivo de la clave principal
resource "aws_cloudwatch_metric_alarm" "kms_key_usage" {
  alarm_name          = "${var.common_name}-kms-high-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfRequestsSucceeded"
  namespace           = "AWS/KMS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"  # Ajustar según necesidades
  alarm_description   = "Uso excesivo de la clave KMS principal - Creado por Ruben Martin"
  alarm_actions       = []  # Se conectará con SNS en el módulo de notificaciones
  
  dimensions = {
    KeyId = aws_kms_key.main.key_id
  }
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-kms-usage-alarm"
    Purpose = "SecurityMonitoring"
    Author  = "Ruben Martin"
  })
}

# Alarma para errores de KMS
resource "aws_cloudwatch_metric_alarm" "kms_errors" {
  alarm_name          = "${var.common_name}-kms-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfRequestsFailed"
  namespace           = "AWS/KMS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Errores en operaciones KMS - Creado por Ruben Martin"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    KeyId = aws_kms_key.main.key_id
  }
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-kms-errors-alarm"
    Purpose = "ErrorMonitoring"
    Author  = "Ruben Martin"
  })
}

# =============================================================================
# MÉTRICAS PERSONALIZADAS PARA AUDITORÍA
# =============================================================================

# Log group para métricas de KMS
resource "aws_cloudwatch_log_group" "kms_audit" {
  name              = "/aws/kms/${var.common_name}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-kms-audit-logs"
    Purpose = "SecurityAudit"
    Author  = "Ruben Martin"
  })
}

# Filtro de métricas para operaciones de cifrado
resource "aws_cloudwatch_log_metric_filter" "kms_encrypt_operations" {
  name           = "${var.common_name}-kms-encrypt-operations"
  log_group_name = aws_cloudwatch_log_group.kms_audit.name
  pattern        = "[timestamp, request_id, event_name=\"Encrypt\", ...]"
  
  metric_transformation {
    name      = "KMSEncryptOperations"
    namespace = "${var.project_name}/Security"
    value     = "1"
    
    default_value = "0"
  }
}

# Filtro de métricas para operaciones de descifrado
resource "aws_cloudwatch_log_metric_filter" "kms_decrypt_operations" {
  name           = "${var.common_name}-kms-decrypt-operations"
  log_group_name = aws_cloudwatch_log_group.kms_audit.name
  pattern        = "[timestamp, request_id, event_name=\"Decrypt\", ...]"
  
  metric_transformation {
    name      = "KMSDecryptOperations"
    namespace = "${var.project_name}/Security"
    value     = "1"
    
    default_value = "0"
  }
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

variable "account_id" {
  description = "ID de la cuenta AWS"
  type        = string
}

# =============================================================================
# OUTPUTS DEL MÓDULO
# =============================================================================

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

/**
 * =============================================================================
 * NOTAS DE SEGURIDAD KMS - AUTOR: RUBEN MARTIN
 * =============================================================================
 * 
 * 1. ROTACIÓN DE CLAVES:
 *    - Rotación automática habilitada en todas las claves
 *    - AWS gestiona automáticamente las claves antiguas
 *    - No requiere actualización de aplicaciones
 * 
 * 2. POLÍTICAS DE ACCESO:
 *    - Principio de menor privilegio implementado
 *    - Acceso restringido por servicio y región
 *    - Condiciones específicas para cada tipo de operación
 * 
 * 3. AUDITORÍA Y MONITOREO:
 *    - CloudWatch Alarms para uso y errores
 *    - Log groups específicos para auditoría
 *    - Métricas personalizadas para operaciones críticas
 * 
 * 4. CLAVES ESPECÍFICAS POR SERVICIO:
 *    - Clave principal para uso general
 *    - Claves dedicadas para S3, Redshift y CloudWatch
 *    - Grants específicos para permisos granulares
 * 
 * 5. PROTECCIÓN CONTRA ELIMINACIÓN:
 *    - Ventana de eliminación configurable
 *    - Tags para identificación y governance
 *    - Alias para facilitar gestión
 * 
 * 6. CUMPLIMIENTO:
 *    - Cifrado obligatorio para todos los servicios
 *    - Políticas que deniegan acceso inseguro
 *    - Restricciones geográficas implementadas
 * 
 * =============================================================================
 */
      values   = [var.account_id]
    }
  }
  
  # Denegar acceso desde fuera de la región especificada
  statement {
    sid    = "DenyOutsideRegion"
    effect = "Deny"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = ["kms:*"]
    resources = ["*"]
    
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }
  }
  
  # Denegar acceso no cifrado
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = ["kms:*"]
    resources = ["*"]
    
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Clave KMS principal para la plataforma
resource "aws_kms_key" "main" {
  description              = "Clave KMS principal para ${var.project_name} - Creada por Ruben Martin"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  # Habilitar rotación automática anual
  enable_key_rotation = true
  
  # Período de eliminación (7-30 días)
  deletion_window_in_days = 10
  
  # Política de acceso a la clave
  policy = data.aws_iam_policy_document.kms_key_policy.json
  
  tags = merge(var.common_tags, {
    Name        = "${var.common_name}-main-key"
    Purpose     = "DataEncryption"
    KeyType     = "Primary"
    Rotation    = "Enabled"
    Author      = "Ruben Martin"
    Compliance  = "Required"
  })
}

# Alias para la clave principal
resource "aws_kms_alias" "main" {
  name          = "alias/${var.common_name}-main"
  target_key_id = aws_kms_key.main.key_id
}

# =============================================================================
# CLAVE KMS ESPECÍFICA PARA S3
# =============================================================================

# Documento de política para la clave de S3
data "aws_iam_policy_document" "s3_kms_policy" {
  # Acceso completo para la cuenta root
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    
    actions   = ["kms:*"]
    resources = ["*"]
  }
  
  # Acceso específico para S3
  statement {
    sid    = "AllowS3Service"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    
    resources = ["*"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount" "modules/kms/main.tf"
