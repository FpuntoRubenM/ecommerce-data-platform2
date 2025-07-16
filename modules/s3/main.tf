# /**
 * =============================================================================
 * MÓDULO S3 - ALMACENAMIENTO SEGURO Y OPTIMIZADO
 * =============================================================================
 * 
 * Autor: Ruben Martin
 * Fecha: 2025-07-16
 * Versión: 2.0.0
 * 
 * Descripción: Módulo para configuración de Amazon S3 como data lake con 
 * todas las características de seguridad, optimización de costos y 
 * cumplimiento de mejores prácticas.
 * 
 * Características implementadas:
 * - Cifrado en reposo con KMS
 * - Versionado para protección de datos
 * - Lifecycle policies para optimización de costos
 * - Block public access para seguridad
 * - Logging y monitoring integrado
 * - Replicación cross-region (opcional)
 * 
 * =============================================================================
 */

# Generar sufijo aleatorio para unicidad global del bucket
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# =============================================================================
# BUCKET PRINCIPAL PARA DATA LAKE
# =============================================================================

# Bucket S3 principal para el data lake
resource "aws_s3_bucket" "main" {
  bucket        = "${var.common_name}-datalake-${random_string.bucket_suffix.result}"
  force_destroy = var.environment == "dev" ? true : false
  
  tags = merge(var.common_tags, {
    Name         = "${var.common_name}-datalake"
    Purpose      = "DataLake"
    DataClass    = "Analytical"
    Backup       = "Required"
    Compliance   = "Required"
  })
}

# =============================================================================
# CONFIGURACIÓN DE CIFRADO
# =============================================================================

# Configuración de cifrado server-side con KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    
    bucket_key_enabled = true
  }
  
  depends_on = [aws_s3_bucket.main]
}

# =============================================================================
# CONFIGURACIÓN DE VERSIONADO
# =============================================================================

# Habilitar versionado para protección contra eliminación accidental
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status = "Enabled"
  }
  
  depends_on = [aws_s3_bucket.main]
}

# =============================================================================
# CONFIGURACIÓN DE ACCESO PÚBLICO
# =============================================================================

# Bloquear todo acceso público (security by default)
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  depends_on = [aws_s3_bucket.main]
}

# =============================================================================
# CONFIGURACIÓN DE LIFECYCLE POLICIES
# =============================================================================

# Política de lifecycle para optimización de costos
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  # Regla para datos raw (datos originales sin procesar)
  rule {
    id     = "raw_data_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = "raw/"
    }
    
    # Transición a Standard-IA después de 30 días
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    # Transición a Glacier después de 90 días
    transition {
      days          = var.glacier_days
      storage_class = "GLACIER"
    }
    
    # Transición a Deep Archive después de 1 año
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
    
    # Eliminar versiones no actuales después de configuración por entorno
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    
    noncurrent_version_transition {
      noncurrent_days = var.glacier_days
      storage_class   = "GLACIER"
    }
    
    # Eliminar versiones antiguas después del período de retención
    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }
    
    # Limpiar uploads incompletos después de 7 días
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  
  # Regla para datos procesados (menor retención)
  rule {
    id     = "processed_data_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = "processed/"
    }
    
    # Transición más rápida para datos procesados
    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
    
    # Eliminar después de período más corto
    expiration {
      days = var.retention_days / 2
    }
  }
  
  # Regla para logs y metadatos
  rule {
    id     = "logs_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = "logs/"
    }
    
    # Retención más corta para logs
    expiration {
      days = 90
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
  
  depends_on = [aws_s3_bucket.main]
}

# =============================================================================
# CONFIGURACIÓN DE CORS
# =============================================================================

# Configuración CORS para acceso desde aplicaciones web
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  
  depends_on = [aws_s3_bucket.main]
}

# =============================================================================
# CONFIGURACIÓN DE LOGGING
# =============================================================================

# Bucket para access logs
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.common_name}-access-logs-${random_string.bucket_suffix.result}"
  force_destroy = true
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-access-logs"
    Purpose = "AccessLogs"
  })
}

# Configuración de logging para el bucket principal
resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id
  
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
  
  depends_on = [
    aws_s3_bucket.main,
    aws_s3_bucket.access_logs
  ]
}

# Cifrado para bucket de logs
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
  
  depends_on = [aws_s3_bucket.access_logs]
}

# Bloquear acceso público al bucket de logs
resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  depends_on = [aws_s3_bucket.access_logs]
}

# =============================================================================
# POLÍTICAS DE BUCKET
# =============================================================================

# Política de bucket para forzar cifrado y SSL
data "aws_iam_policy_document" "bucket_policy" {
  # Denegar acceso no cifrado
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = ["s3:*"]
    
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  
  # Forzar cifrado server-side
  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = ["s3:PutObject"]
    
    resources = ["${aws_s3_bucket.main.arn}/*"]
    
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
  
  # Denegar objetos sin cifrado
  statement {
    sid    = "DenyUnEncryptedObjectUploads"
    effect = "Deny"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = ["s3:PutObject"]
    
    resources = ["${aws_s3_bucket.main.arn}/*"]
    
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
  
  # Permitir acceso desde VPC endpoint específico
  statement {
    sid    = "AllowVPCEndpointAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"
      values   = [var.vpc_endpoint_id]
    }
  }
}

# Aplicar política al bucket
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
  
  depends_on = [
    aws_s3_bucket.main,
    aws_s3_bucket_public_access_block.main
  ]
}

# =============================================================================
# CONFIGURACIÓN DE NOTIFICACIONES
# =============================================================================

# Configuración de notificaciones para eventos del bucket
resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id
  
  # Notificación para objetos creados en la carpeta raw
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
    filter_suffix       = ".json"
  }
  
  depends_on = [
    aws_s3_bucket.main,
    aws_lambda_function.s3_processor
  ]
}

# =============================================================================
# FUNCIÓN LAMBDA PARA PROCESAMIENTO
# =============================================================================

# Función Lambda para procesar archivos subidos a S3
resource "aws_lambda_function" "s3_processor" {
  filename         = "s3_processor.zip"
  function_name    = "${var.common_name}-s3-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.main.bucket
      KMS_KEY_ID  = var.kms_key_id
      ENVIRONMENT = var.environment
    }
  }
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-s3-processor"
    Service = "Lambda"
    Purpose = "DataProcessing"
  })
  
  depends_on = [data.archive_file.lambda_zip]
}

# Crear archivo ZIP para Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "s3_processor.zip"
  
  source {
    content = templatefile("${path.module}/lambda/s3_processor.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# Rol IAM para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.common_name}-lambda-s3-processor-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-lambda-role"
    Service = "Lambda"
  })
}

# Política para Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.common_name}-lambda-s3-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_id
      }
    ]
  })
}

# Permiso para S3 de invocar Lambda
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

# =============================================================================
# MÉTRICAS PERSONALIZADAS DE CLOUDWATCH
# =============================================================================

# Métrica personalizada para tamaño del bucket
resource "aws_cloudwatch_log_metric_filter" "bucket_size" {
  name           = "${var.common_name}-bucket-size-metric"
  log_group_name = "/aws/s3/${aws_s3_bucket.main.bucket}"
  pattern        = "[timestamp, request_id, remote_ip = \"bucket-size\", ...]"
  
  metric_transformation {
    name      = "S3BucketSize"
    namespace = "${var.project_name}/S3"
    value     = "1"
  }
}

# Métrica para número de objetos
resource "aws_cloudwatch_log_metric_filter" "object_count" {
  name           = "${var.common_name}-object-count-metric"
  log_group_name = "/aws/s3/${aws_s3_bucket.main.bucket}"
  pattern        = "[timestamp, request_id, remote_ip = \"object-count\", ...]"
  
  metric_transformation {
    name      = "S3ObjectCount"
    namespace = "${var.project_name}/S3"
    value     = "1"
  }
}

# =============================================================================
# REPLICACIÓN CROSS-REGION (OPCIONAL PARA PROD)
# =============================================================================

# Bucket de replicación para disaster recovery
resource "aws_s3_bucket" "replica" {
  count         = var.environment == "prod" ? 1 : 0
  bucket        = "${var.common_name}-replica-${random_string.bucket_suffix.result}"
  force_destroy = false
  
  tags = merge(var.common_tags, {
    Name    = "${var.common_name}-replica"
    Purpose = "DisasterRecovery"
  })
}

# Configuración de replicación
resource "aws_s3_bucket_replication_configuration" "replication" {
  count  = var.environment == "prod" ? 1 : 0
  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.main.id
  
  rule {
    id     = "replicate_all"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.replica[0].arn
      storage_class = "STANDARD_IA"
      
      encryption_configuration {
        replica_kms_key_id = var.kms_key_id
      }
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.main]
}

# Rol IAM para replicación
resource "aws_iam_role" "replication" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.common_name}-replication-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# Política para replicación
resource "aws_iam_role_policy" "replication" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.common_name}-replication-policy"
  role  = aws_iam_role.replication[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.main.arn
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.replica[0].arn}/*"
      }
    ]
  })
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

# =============================================================================
# OUTPUTS DEL MÓDULO
# =============================================================================

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

/**
 * =============================================================================
 * ARCHIVOS ADICIONALES REQUERIDOS - AUTOR: RUBEN MARTIN
 * =============================================================================
 * 
 * Este módulo requiere los siguientes archivos adicionales:
 * 
 * 1. modules/s3/lambda/s3_processor.py - Función Lambda para procesamiento
 * 2. modules/s3/variables.tf - Variables del módulo
 * 3. modules/s3/outputs.tf - Outputs del módulo
 * 
 * =============================================================================
 * 
 * CARACTERÍSTICAS IMPLEMENTADAS:
 * 
 * 1. SEGURIDAD:
 *    - Cifrado obligatorio con KMS
 *    - Block public access habilitado
 *    - Políticas restrictivas de bucket
 *    - SSL/TLS obligatorio
 * 
 * 2. OPTIMIZACIÓN DE COSTOS:
 *    - Lifecycle policies por tipo de datos
 *    - Transiciones automáticas a clases más baratas
 *    - Limpieza de uploads incompletos
 *    - Eliminación de versiones antiguas
 * 
 * 3. ALTA DISPONIBILIDAD:
 *    - Versionado habilitado
 *    - Replicación cross-region en producción
 *    - Logging de accesos
 *    - Monitoreo con CloudWatch
 * 
 * 4. OPERACIONES:
 *    - Procesamiento automático con Lambda
 *    - Métricas personalizadas
 *    - Notificaciones de eventos
 *    - Estructura organizacional por carpetas
 * 
 * 5. CUMPLIMIENTO:
 *    - Auditoría completa de accesos
 *    - Retención configurable por entorno
 *    - Cifrado end-to-end
 *    - Tags para governance
 * 
 * =============================================================================
 */ "modules/s3/main.tf"
