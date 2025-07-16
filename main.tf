# /**
 * =============================================================================
 * ECOMMERCE DATA PLATFORM - INFRAESTRUCTURA PRINCIPAL
 * =============================================================================
 * 
 * Autor: Ruben Martin
 * Fecha: 2025-07-16
 * Versión: 2.0.0
 * 
 * Descripción: Infraestructura mejorada para plataforma de datos de comercio 
 * electrónico en AWS siguiendo las mejores prácticas del AWS Well-Architected 
 * Framework.
 * 
 * Pilares Well-Architected implementados:
 * - Excelencia Operacional: Automatización, monitoreo y alertas
 * - Seguridad: Cifrado, IAM roles específicos, VPC endpoints
 * - Confiabilidad: Multi-AZ, backups automáticos, recuperación ante desastres
 * - Eficiencia de Rendimiento: Auto-scaling, recursos optimizados
 * - Optimización de Costos: Políticas de lifecycle, tagging para cost allocation
 * - Sostenibilidad: Recursos eficientes, políticas de retención
 * 
 * =============================================================================
 */

# Configuración de Terraform con versionado y backend remoto
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  # Backend remoto para el estado de Terraform (descomenta y configura según tu setup)
  # backend "s3" {
  #   bucket         = "tu-bucket-terraform-state"
  #   key            = "ecommerce-data-platform/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# Configuración del proveedor AWS
provider "aws" {
  region = var.aws_region
  
  # Tags por defecto para todos los recursos
  default_tags {
    tags = {
      Project      = var.project_name
      Environment  = var.environment
      Owner        = "Ruben Martin"
      ManagedBy    = "Terraform"
      CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
      CostCenter   = var.cost_center
    }
  }
}

# Obtener información de la zona de disponibilidad actual
data "aws_availability_zones" "available" {
  state = "available"
}

# Obtener información de la región actual
data "aws_region" "current" {}

# Obtener información de la cuenta AWS actual
data "aws_caller_identity" "current" {}

# Generar sufijo aleatorio para recursos únicos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# =============================================================================
# VARIABLES LOCALES
# =============================================================================

locals {
  # Nombre común para todos los recursos
  common_name = "${var.project_name}-${var.environment}"
  
  # Tags comunes para todos los recursos
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Author      = "Ruben Martin"
    ManagedBy   = "Terraform"
    Region      = data.aws_region.current.name
  }
  
  # Configuración de retención de datos por entorno
  retention_config = {
    dev     = { days = 7, glacier_days = 30 }
    staging = { days = 30, glacier_days = 90 }
    prod    = { days = 365, glacier_days = 2555 } # 7 años
  }
  
  # Configuración de monitoreo por entorno
  monitoring_config = {
    dev     = { detailed_monitoring = false, alarm_threshold = 80 }
    staging = { detailed_monitoring = true, alarm_threshold = 75 }
    prod    = { detailed_monitoring = true, alarm_threshold = 70 }
  }
}

# =============================================================================
# NETWORKING - VPC Y SUBNETS
# =============================================================================

# VPC para aislar los recursos de la plataforma
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-vpc"
    Type = "Network"
  })
}

# Internet Gateway para acceso a internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-igw"
  })
}

# Subnets privadas para Redshift (Multi-AZ para alta disponibilidad)
resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-private-subnet-${count.index + 1}"
    Type = "Private"
    Tier = "Data"
  })
}

# Subnets públicas para NAT Gateway
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

# Elastic IP para NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-nat-eip"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway para acceso a internet desde subnets privadas
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-nat-gateway"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# Route Table para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-public-rt"
  })
}

# Route Table para subnets privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-private-rt"
  })
}

# Asociación de route tables con subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# SECURITY - GRUPOS DE SEGURIDAD
# =============================================================================

# Security Group para Redshift
resource "aws_security_group" "redshift" {
  name_prefix = "${local.common_name}-redshift-"
  description = "Security group para Amazon Redshift - Autor: Ruben Martin"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "Redshift port from VPC"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-redshift-sg"
    Type = "Security"
  })
}

# Security Group para VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.common_name}-vpc-endpoints-"
  description = "Security group para VPC endpoints - Autor: Ruben Martin"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-vpc-endpoints-sg"
    Type = "Security"
  })
}

# =============================================================================
# VPC ENDPOINTS PARA MEJOR SEGURIDAD Y RENDIMIENTO
# =============================================================================

# VPC Endpoint para S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-s3-endpoint"
    Type = "VPCEndpoint"
  })
}

# VPC Endpoint para Kinesis
resource "aws_vpc_endpoint" "kinesis_streams" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kinesis-streams"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-kinesis-endpoint"
    Type = "VPCEndpoint"
  })
}

# VPC Endpoint para Kinesis Firehose
resource "aws_vpc_endpoint" "kinesis_firehose" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kinesis-firehose"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-firehose-endpoint"
    Type = "VPCEndpoint"
  })
}

# Asociación del VPC endpoint S3 con las route tables
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.public.id
}

# =============================================================================
# LLAMADAS A MÓDULOS ESPECIALIZADOS
# =============================================================================

# Módulo de IAM para roles y políticas
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de IAM
  s3_bucket_arn = module.s3.bucket_arn
  account_id    = data.aws_caller_identity.current.account_id
  aws_region    = data.aws_region.current.name
}

# Módulo de S3 para almacenamiento
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de S3
  retention_days    = local.retention_config[var.environment].days
  glacier_days      = local.retention_config[var.environment].glacier_days
  kms_key_id        = module.kms.key_id
  vpc_endpoint_id   = aws_vpc_endpoint.s3.id
}

# Módulo de KMS para cifrado
module "kms" {
  source = "./modules/kms"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de KMS
  account_id = data.aws_caller_identity.current.account_id
}

# Módulo de Kinesis para streaming
module "kinesis" {
  source = "./modules/kinesis"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de Kinesis
  kinesis_role_arn    = module.iam.kinesis_role_arn
  firehose_role_arn   = module.iam.firehose_role_arn
  s3_bucket_arn       = module.s3.bucket_arn
  kms_key_id          = module.kms.key_id
  redshift_cluster_id = module.redshift.cluster_identifier
  
  # Configuración de shards por entorno
  shard_count = var.environment == "prod" ? 4 : 2
}

# Módulo de Redshift para data warehouse
module "redshift" {
  source = "./modules/redshift"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de Redshift
  subnet_group_name   = aws_redshift_subnet_group.main.name
  security_group_ids  = [aws_security_group.redshift.id]
  kms_key_id          = module.kms.key_id
  
  # Configuración de tamaño por entorno
  node_type    = var.environment == "prod" ? "dc2.large" : "dc2.large"
  cluster_type = var.environment == "prod" ? "multi-node" : "single-node"
  number_of_nodes = var.environment == "prod" ? 2 : 1
  
  # Credenciales
  master_username = var.redshift_master_username
  master_password = var.redshift_master_password
}

# Módulo de monitoreo
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de monitoreo
  sns_topic_arn           = module.notifications.sns_topic_arn
  kinesis_stream_name     = module.kinesis.stream_name
  firehose_stream_name    = module.kinesis.firehose_stream_name
  redshift_cluster_id     = module.redshift.cluster_identifier
  s3_bucket_name          = module.s3.bucket_name
  
  # Configuración de alertas
  alarm_threshold = local.monitoring_config[var.environment].alarm_threshold
  notification_email = var.notification_email
}

# Módulo de notificaciones
module "notifications" {
  source = "./modules/notifications"
  
  project_name = var.project_name
  environment  = var.environment
  common_name  = local.common_name
  common_tags  = local.common_tags
  
  # Configuración específica de notificaciones
  notification_email = var.notification_email
  kms_key_id         = module.kms.key_id
}

# =============================================================================
# REDSHIFT SUBNET GROUP
# =============================================================================

# Subnet group para Redshift (requerido para cluster en VPC)
resource "aws_redshift_subnet_group" "main" {
  name       = "${local.common_name}-redshift-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = merge(local.common_tags, {
    Name = "${local.common_name}-redshift-subnet-group"
    Type = "Database"
  })
}

# =============================================================================
# OUTPUTS
# =============================================================================

# Outputs principales de la infraestructura
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis Data Streams"
  value       = module.kinesis.stream_name
}

output "firehose_stream_name" {
  description = "Nombre del stream de Kinesis Data Firehose"
  value       = module.kinesis.firehose_stream_name
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = module.s3.bucket_name
}

output "redshift_endpoint" {
  description = "Endpoint del cluster Redshift"
  value       = module.redshift.cluster_endpoint
  sensitive   = true
}

output "redshift_cluster_id" {
  description = "ID del cluster Redshift"
  value       = module.redshift.cluster_identifier
}

output "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  value       = module.notifications.sns_topic_arn
}

output "kms_key_id" {
  description = "ID de la clave KMS para cifrado"
  value       = module.kms.key_id
}

output "deployment_info" {
  description = "Información del despliegue"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = data.aws_region.current.name
    author       = "Ruben Martin"
    deployed_at  = timestamp()
  }
}

/**
 * =============================================================================
 * NOTAS IMPORTANTES - AUTOR: RUBEN MARTIN
 * =============================================================================
 * 
 * 1. SEGURIDAD:
 *    - Todos los datos están cifrados en reposo y en tránsito
 *    - VPC endpoints para comunicación segura
 *    - IAM roles con principio de menor privilegio
 *    - Security groups restrictivos
 * 
 * 2. ALTA DISPONIBILIDAD:
 *    - Recursos desplegados en múltiples AZs
 *    - Backups automáticos configurados
 *    - Monitoreo y alertas implementados
 * 
 * 3. ESCALABILIDAD:
 *    - Kinesis configurado para auto-scaling
 *    - Redshift puede escalarse según necesidades
 *    - S3 con lifecycle policies optimizadas
 * 
 * 4. COSTOS:
 *    - Recursos dimensionados por entorno
 *    - Políticas de retención configuradas
 *    - Tagging para cost allocation
 * 
 * 5. MONITOREO:
 *    - CloudWatch metrics y alarms
 *    - Notificaciones SNS configuradas
 *    - Logs estructurados
 * 
 * =============================================================================
 */ "main.tf"
