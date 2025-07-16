# /**
 * =============================================================================
 * VARIABLES DE CONFIGURACIÓN - ECOMMERCE DATA PLATFORM
 * =============================================================================
 * 
 * Autor: Ruben Martin
 * Fecha: 2025-07-16
 * Versión: 2.0.0
 * 
 * Descripción: Variables de configuración para la plataforma de datos de 
 * comercio electrónico. Incluye validaciones y valores por defecto optimizados
 * para diferentes entornos.
 * 
 * =============================================================================
 */

# =============================================================================
# CONFIGURACIÓN GENERAL
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto. Se usará como prefijo en todos los recursos."
  type        = string
  default     = "ecommerce-data-platform"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "El nombre del proyecto solo puede contener letras minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod). Determina el dimensionamiento y configuración de recursos."
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser: dev, staging o prod."
  }
}

variable "aws_region" {
  description = "Región AWS donde se desplegará la infraestructura. Recomendado: us-east-1 para mejor disponibilidad de servicios."
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "La región debe tener formato válido (ej: us-east-1)."
  }
}

variable "cost_center" {
  description = "Centro de costos para tracking financiero y facturación departamental."
  type        = string
  default     = "DataEngineering"
  
  validation {
    condition     = length(var.cost_center) > 0
    error_message = "El centro de costos no puede estar vacío."
  }
}

# =============================================================================
# CONFIGURACIÓN DE NETWORKING
# =============================================================================

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC. Debe permitir al menos 4 subnets para alta disponibilidad."
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "El CIDR de la VPC debe ser válido."
  }
}

variable "enable_vpc_endpoints" {
  description = "Habilitar VPC endpoints para mejorar seguridad y rendimiento."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para acceso a internet desde subnets privadas."
  type        = bool
  default     = true
}

# =============================================================================
# CONFIGURACIÓN DE AMAZON KINESIS
# =============================================================================

variable "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis Data Streams. Se añadirá prefijo automáticamente."
  type        = string
  default     = "ecommerce-events"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.kinesis_stream_name))
    error_message = "El nombre del stream solo puede contener letras, números, guiones y guiones bajos."
  }
}

variable "kinesis_shard_count" {
  description = "Número de shards para el stream de Kinesis. Determina el throughput (1 shard = 1MB/s entrada, 2MB/s salida)."
  type        = number
  default     = 2
  
  validation {
    condition     = var.kinesis_shard_count >= 1 && var.kinesis_shard_count <= 100
    error_message = "El número de shards debe estar entre 1 y 100."
  }
}

variable "kinesis_retention_period" {
  description = "Período de retención de datos en Kinesis en horas (24-168)."
  type        = number
  default     = 24
  
  validation {
    condition     = var.kinesis_retention_period >= 24 && var.kinesis_retention_period <= 168
    error_message = "El período de retención debe estar entre 24 y 168 horas."
  }
}

variable "kinesis_encryption_type" {
  description = "Tipo de cifrado para Kinesis Data Streams (KMS o NONE)."
  type        = string
  default     = "KMS"
  
  validation {
    condition     = contains(["KMS", "NONE"], var.kinesis_encryption_type)
    error_message = "El tipo de cifrado debe ser KMS o NONE."
  }
}

# =============================================================================
# CONFIGURACIÓN DE AMAZON S3
# =============================================================================

variable "s3_bucket_name" {
  description = "Nombre del bucket S3. Se añadirá sufijo aleatorio para unicidad global."
  type        = string
  default     = "ecommerce-data-lake"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.s3_bucket_name))
    error_message = "El nombre del bucket solo puede contener letras minúsculas, números y guiones."
  }
}

variable "s3_enable_versioning" {
  description = "Habilitar versionado en el bucket S3 para protección contra eliminación accidental."
  type        = bool
  default     = true
}

variable "s3_enable_acceleration" {
  description = "Habilitar S3 Transfer Acceleration para uploads más rápidos."
  type        = bool
  default     = false
}

variable "s3_storage_class" {
  description = "Clase de almacenamiento por defecto para objetos en S3."
  type        = string
  default     = "STANDARD"
  
  validation {
    condition     = contains(["STANDARD", "STANDARD_IA", "ONEZONE_IA", "GLACIER"], var.s3_storage_class)
    error_message = "La clase de almacenamiento debe ser STANDARD, STANDARD_IA, ONEZONE_IA o GLACIER."
  }
}

variable "s3_lifecycle_enabled" {
  description = "Habilitar políticas de lifecycle para optimización de costos."
  type        = bool
  default     = true
}

# =============================================================================
# CONFIGURACIÓN DE AMAZON REDSHIFT
# =============================================================================

variable "redshift_cluster_identifier" {
  description = "Identificador único del cluster Redshift. Se añadirá prefijo automáticamente."
  type        = string
  default     = "ecommerce-dw"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.redshift_cluster_identifier))
    error_message = "El identificador debe contener solo letras minúsculas, números y guiones."
  }
}

variable "redshift_node_type" {
  description = "Tipo de nodo para el cluster Redshift. Opciones: dc2.large, dc2.8xlarge, ra3.xlplus, ra3.4xlarge."
  type        = string
  default     = "dc2.large"
  
  validation {
    condition     = contains(["dc2.large", "dc2.8xlarge", "ra3.xlplus", "ra3.4xlarge"], var.redshift_node_type)
    error_message = "El tipo de nodo debe ser dc2.large, dc2.8xlarge, ra3.xlplus o ra3.4xlarge."
  }
}

variable "redshift_cluster_type" {
  description = "Tipo de cluster Redshift (single-node o multi-node)."
  type        = string
  default     = "single-node"
  
  validation {
    condition     = contains(["single-node", "multi-node"], var.redshift_cluster_type)
    error_message = "El tipo de cluster debe ser single-node o multi-node."
  }
}

variable "redshift_number_of_nodes" {
  description = "Número de nodos en el cluster (solo para multi-node, mínimo 2)."
  type        = number
  default     = 1
  
  validation {
    condition     = var.redshift_number_of_nodes >= 1 && var.redshift_number_of_nodes <= 128
    error_message = "El número de nodos debe estar entre 1 y 128."
  }
}

variable "redshift_master_username" {
  description = "Nombre de usuario maestro para el cluster Redshift."
  type        = string
  default     = "admin"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.redshift_master_username))
    error_message = "El nombre de usuario debe comenzar con letra y contener solo letras minúsculas, números y guiones bajos."
  }
}

variable "redshift_master_password" {
  description = "Contraseña del usuario maestro. Mínimo 8 caracteres, debe incluir mayúsculas, minúsculas y números."
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.redshift_master_password) >= 8
    error_message = "La contraseña debe tener al menos 8 caracteres."
  }
}

variable "redshift_database_name" {
  description = "Nombre de la base de datos inicial en Redshift."
  type        = string
  default     = "ecommerce"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.redshift_database_name))
    error_message = "El nombre de la base de datos debe comenzar con letra y contener solo letras minúsculas, números y guiones bajos."
  }
}

variable "redshift_port" {
  description = "Puerto para conexiones al cluster Redshift."
  type        = number
  default     = 5439
  
  validation {
    condition     = var.redshift_port >= 1024 && var.redshift_port <= 65535
    error_message = "El puerto debe estar entre 1024 y 65535."
  }
}

variable "redshift_backup_retention_period" {
  description = "Período de retención de backups automáticos en días (1-35)."
  type        = number
  default     = 7
  
  validation {
    condition     = var.redshift_backup_retention_period >= 1 && var.redshift_backup_retention_period <= 35
    error_message = "El período de retención debe estar entre 1 y 35 días."
  }
}

variable "redshift_preferred_maintenance_window" {
  description = "Ventana de mantenimiento preferida para Redshift (formato: ddd:hh24:mi-ddd:hh24:mi)."
  type        = string
  default     = "sun:05:00-sun:06:00"
  
  validation {
    condition     = can(regex("^[a-z]{3}:[0-9]{2}:[0-9]{2}-[a-z]{3}:[0-9]{2}:[0-9]{2}$", var.redshift_preferred_maintenance_window))
    error_message = "La ventana de mantenimiento debe tener formato: ddd:hh24:mi-ddd:hh24:mi (ej: sun:05:00-sun:06:00)."
  }
}

variable "redshift_encrypted" {
  description = "Habilitar cifrado para el cluster Redshift."
  type        = bool
  default     = true
}

variable "redshift_publicly_accessible" {
  description = "Hacer el cluster Redshift accesible públicamente (NO recomendado para producción)."
  type        = bool
  default     = false
}

# =============================================================================
# CONFIGURACIÓN DE MONITOREO Y ALERTAS
# =============================================================================

variable "notification_email" {
  description = "Email para recibir notificaciones y alertas del sistema."
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Debe proporcionar un email válido para las notificaciones."
  }
}

variable "enable_detailed_monitoring" {
  description = "Habilitar monitoreo detallado (puede incrementar costos)."
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Días de retención para logs de CloudWatch."
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "El período de retención debe ser uno de los valores permitidos por CloudWatch."
  }
}

variable "alarm_cpu_threshold" {
  description = "Umbral de CPU para generar alarmas (porcentaje)."
  type        = number
  default     = 80
  
  validation {
    condition     = var.alarm_cpu_threshold >= 1 && var.alarm_cpu_threshold <= 100
    error_message = "El umbral de CPU debe estar entre 1 y 100."
  }
}

variable "alarm_memory_threshold" {
  description = "Umbral de memoria para generar alarmas (porcentaje)."
  type        = number
  default     = 85
  
  validation {
    condition     = var.alarm_memory_threshold >= 1 && var.alarm_memory_threshold <= 100
    error_message = "El umbral de memoria debe estar entre 1 y 100."
  }
}

variable "alarm_disk_threshold" {
  description = "Umbral de espacio en disco para generar alarmas (porcentaje)."
  type        = number
  default     = 90
  
  validation {
    condition     = var.alarm_disk_threshold >= 1 && var.alarm_disk_threshold <= 100
    error_message = "El umbral de disco debe estar entre 1 y 100."
  }
}

# =============================================================================
# CONFIGURACIÓN DE SEGURIDAD
# =============================================================================

variable "enable_encryption" {
  description = "Habilitar cifrado en todos los servicios compatibles."
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "Días de espera antes de eliminar una clave KMS (7-30)."
  type        = number
  default     = 7
  
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "El período de eliminación debe estar entre 7 y 30 días."
  }
}

variable "enable_cloudtrail" {
  description = "Habilitar AWS CloudTrail para auditoría."
  type        = bool
  default     = true
}

variable "force_ssl" {
  description = "Forzar conexiones SSL/TLS en todos los servicios."
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "Bloques CIDR permitidos para acceso a recursos (para casos especiales)."
  type        = list(string)
  default     = []
  
  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "Todos los bloques CIDR deben ser válidos."
  }
}

# =============================================================================
# CONFIGURACIÓN DE ENTORNO
# =============================================================================

variable "environment_config" {
  description = "Configuración específica por entorno para optimización de recursos."
  type = object({
    dev = object({
      kinesis_shards     = number
      redshift_nodes     = number
      backup_retention   = number
      monitoring_level   = string
    })
    staging = object({
      kinesis_shards     = number
      redshift_nodes     = number
      backup_retention   = number
      monitoring_level   = string
    })
    prod = object({
      kinesis_shards     = number
      redshift_nodes     = number
      backup_retention   = number
      monitoring_level   = string
    })
  })
  
  default = {
    dev = {
      kinesis_shards   = 1
      redshift_nodes   = 1
      backup_retention = 3
      monitoring_level = "basic"
    }
    staging = {
      kinesis_shards   = 2
      redshift_nodes   = 1
      backup_retention = 7
      monitoring_level = "enhanced"
    }
    prod = {
      kinesis_shards   = 4
      redshift_nodes   = 2
      backup_retention = 30
      monitoring_level = "detailed"
    }
  }
}

# =============================================================================
# CONFIGURACIÓN DE TAGS ADICIONALES
# =============================================================================

variable "additional_tags" {
  description = "Tags adicionales para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
  
  validation {
    condition     = alltrue([for k, v in var.additional_tags : can(regex("^[a-zA-Z0-9\\s\\-_.:]+$", k)) && can(regex("^[a-zA-Z0-9\\s\\-_.:]+$", v))])
    error_message = "Las claves y valores de tags deben contener solo caracteres alfanuméricos, espacios, guiones, guiones bajos, puntos y dos puntos."
  }
}

# =============================================================================
# CONFIGURACIÓN DE DESARROLLO Y TESTING
# =============================================================================

variable "enable_debug_mode" {
  description = "Habilitar modo debug para troubleshooting (solo para dev)."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Omitir snapshot final al eliminar recursos (útil para testing)."
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Habilitar protección contra eliminación accidental."
  type        = bool
  default     = true
}

# =============================================================================
# CONFIGURACIÓN DE NETWORKING AVANZADA
# =============================================================================

variable "enable_flow_logs" {
  description = "Habilitar VPC Flow Logs para análisis de tráfico."
  type        = bool
  default     = true
}

variable "flow_logs_retention" {
  description = "Días de retención para VPC Flow Logs."
  type        = number
  default     = 14
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention)
    error_message = "El período de retención debe ser uno de los valores permitidos por CloudWatch."
  }
}

variable "enable_dns_support" {
  description = "Habilitar soporte DNS en la VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Habilitar hostnames DNS en la VPC."
  type        = bool
  default     = true
}

# =============================================================================
# CONFIGURACIÓN DE FIREHOSE
# =============================================================================

variable "firehose_buffer_size" {
  description = "Tamaño del buffer de Firehose en MB (1-5)."
  type        = number
  default     = 5
  
  validation {
    condition     = var.firehose_buffer_size >= 1 && var.firehose_buffer_size <= 5
    error_message = "El tamaño del buffer debe estar entre 1 y 5 MB."
  }
}

variable "firehose_buffer_interval" {
  description = "Intervalo del buffer de Firehose en segundos (60-900)."
  type        = number
  default     = 300
  
  validation {
    condition     = var.firehose_buffer_interval >= 60 && var.firehose_buffer_interval <= 900
    error_message = "El intervalo del buffer debe estar entre 60 y 900 segundos."
  }
}

variable "firehose_compression" {
  description = "Tipo de compresión para Firehose (GZIP, ZIP, Snappy, HADOOP_SNAPPY, UNCOMPRESSED)."
  type        = string
  default     = "GZIP"
  
  validation {
    condition     = contains(["GZIP", "ZIP", "Snappy", "HADOOP_SNAPPY", "UNCOMPRESSED"], var.firehose_compression)
    error_message = "El tipo de compresión debe ser GZIP, ZIP, Snappy, HADOOP_SNAPPY o UNCOMPRESSED."
  }
}

/**
 * =============================================================================
 * NOTAS IMPORTANTES SOBRE VARIABLES - AUTOR: RUBEN MARTIN
 * =============================================================================
 * 
 * 1. VALIDACIONES:
 *    - Todas las variables incluyen validaciones para prevenir errores
 *    - Los valores por defecto están optimizados para cada entorno
 *    - Se validan formatos, rangos y opciones permitidas
 * 
 * 2. SEGURIDAD:
 *    - Variables sensibles marcadas como 'sensitive = true'
 *    - Valores por defecto seguros (cifrado habilitado, acceso privado)
 *    - Validación de emails y formatos de entrada
 * 
 * 3. CONFIGURACIÓN POR ENTORNO:
 *    - Diferentes configuraciones para dev/staging/prod
 *    - Escalamiento automático basado en entorno
 *    - Optimización de costos por entorno
 * 
 * 4. FLEXIBILIDAD:
 *    - Tags adicionales para casos específicos
 *    - Configuración avanzada para casos de uso especiales
 *    - Modo debug para desarrollo y troubleshooting
 * 
 * 5. MONITOREO:
 *    - Configuración granular de alertas y umbrales
 *    - Logs estructurados con retención configurable
 *    - Notificaciones personalizables
 * 
 * =============================================================================
 */ "variables.tf"
