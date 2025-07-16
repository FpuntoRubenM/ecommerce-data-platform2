# # 🏪 E-commerce Data Platform en AWS

**Autor:** Ruben Martin  
**Versión:** 2.0.0  
**Fecha:** 2025-07-16  

## 📋 Descripción del Proyecto

Plataforma de datos de comercio electrónico construida en AWS siguiendo las mejores prácticas del **AWS Well-Architected Framework**. Esta infraestructura permite capturar, procesar y analizar datos de e-commerce en tiempo real utilizando servicios nativos de AWS.

### 🎯 Objetivos

- **Captura en tiempo real** de eventos de e-commerce
- **Procesamiento escalable** de grandes volúmenes de datos
- **Almacenamiento optimizado** con políticas de lifecycle
- **Análisis avanzado** con capacidades de Business Intelligence
- **Seguridad robusta** con cifrado end-to-end
- **Monitoreo completo** con alertas proactivas

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │    │   Kinesis Data  │    │   Kinesis Data  │
│                 │───▶│    Streams      │───▶│   Analytics     │
│ • Web Events    │    │                 │    │                 │
│ • Mobile Apps   │    │ • Real-time     │    │ • SQL Queries   │
│ • APIs          │    │ • Scalable      │    │ • Transformations│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Amazon S3     │    │   Kinesis Data  │    │   Amazon        │
│                 │◀───│   Firehose      │    │   Redshift      │
│ • Data Lake     │    │                 │    │                 │
│ • Raw Data      │    │ • Buffering     │    │ • Data Warehouse│
│ • Processed     │    │ • Compression   │    │ • Analytics     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🔧 Componentes Principales

| Servicio | Propósito | Características |
|----------|-----------|-----------------|
| **Amazon Kinesis Data Streams** | Ingesta de datos en tiempo real | Auto-scaling, retención configurable |
| **Amazon Kinesis Data Analytics** | Procesamiento de stream | SQL en tiempo real, detección de anomalías |
| **Amazon Kinesis Data Firehose** | Entrega de datos | Compresión automática, buffering inteligente |
| **Amazon S3** | Data Lake | Lifecycle policies, versionado, cifrado |
| **Amazon Redshift** | Data Warehouse | Columnar, compresión, escalable |
| **AWS Lambda** | Procesamiento serverless | Enriquecimiento, validación automática |
| **Amazon CloudWatch** | Monitoreo | Métricas, logs, alertas |

## 🛡️ Pilares del Well-Architected Framework

### 1. **Excelencia Operacional**
- ✅ Infraestructura como código con Terraform
- ✅ Automatización completa del despliegue
- ✅ Monitoreo proactivo con CloudWatch
- ✅ Alertas configurables por entorno
- ✅ Logging estructurado para troubleshooting

### 2. **Seguridad**
- ✅ Cifrado en reposo con AWS KMS
- ✅ Cifrado en tránsito con TLS/SSL
- ✅ VPC endpoints para comunicación privada
- ✅ IAM roles con principio de menor privilegio
- ✅ Network segmentation con subnets privadas

### 3. **Confiabilidad**
- ✅ Deployment multi-AZ
- ✅ Backups automáticos configurados
- ✅ Recuperación ante desastres
- ✅ Auto-scaling basado en demanda
- ✅ Health checks automatizados

### 4. **Eficiencia de Rendimiento**
- ✅ Servicios nativos optimizados
- ✅ Caching inteligente
- ✅ Compresión automática de datos
- ✅ Particionado eficiente en Redshift
- ✅ Paralelización de procesamiento

### 5. **Optimización de Costos**
- ✅ Políticas de lifecycle en S3
- ✅ Reserved Instances para Redshift
- ✅ Spot Instances para desarrollo
- ✅ Tagging para cost allocation
- ✅ Monitoring de costos automatizado

### 6. **Sostenibilidad**
- ✅ Recursos dimensionados por entorno
- ✅ Auto-shutdown en desarrollo
- ✅ Políticas de retención optimizadas
- ✅ Servicios serverless cuando es posible

## 🚀 Inicio Rápido

### Prerrequisitos

```bash
# Instalar Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales AWS
aws configure
```

### Despliegue

```bash
# 1. Clonar el repositorio
git clone https://github.com/FpuntoRubenM/ecommerce-data-platform.git
cd ecommerce-data-platform

# 2. Configurar variables
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores específicos

# 3. Inicializar Terraform
terraform init

# 4. Planificar el despliegue
terraform plan -var="environment=dev"

# 5. Aplicar la infraestructura
terraform apply -var="environment=dev"
```

## ⚙️ Configuración por Entornos

### 🔬 Desarrollo (dev)
```hcl
environment = "dev"
kinesis_shard_count = 1
redshift_node_type = "dc2.large"
redshift_cluster_type = "single-node"
enable_detailed_monitoring = false
backup_retention_period = 3
```

### 🧪 Staging
```hcl
environment = "staging"
kinesis_shard_count = 2
redshift_node_type = "dc2.large"
redshift_cluster_type = "single-node"
enable_detailed_monitoring = true
backup_retention_period = 7
```

### 🏭 Producción
```hcl
environment = "prod"
kinesis_shard_count = 4
redshift_node_type = "dc2.8xlarge"
redshift_cluster_type = "multi-node"
redshift_number_of_nodes = 2
enable_detailed_monitoring = true
backup_retention_period = 30
enable_deletion_protection = true
```

## 📊 Estructura de Datos

### Eventos de E-commerce Soportados

#### 🛒 Transacciones
```json
{
  "event_type": "purchase",
  "timestamp": "2025-07-16T10:30:00Z",
  "transaction_id": "txn_12345",
  "customer_id": "cust_67890",
  "items": [
    {
      "product_id": "prod_111",
      "quantity": 2,
      "unit_price": 29.99,
      "category": "electronics"
    }
  ],
  "total_amount": 59.98,
  "currency": "USD",
  "payment_method": "credit_card",
  "shipping_address": {
    "country": "ES",
    "city": "Madrid",
    "postal_code": "28001"
  }
}
```

#### 👤 Eventos de Usuario
```json
{
  "event_type": "page_view",
  "timestamp": "2025-07-16T10:30:00Z",
  "user_id": "user_12345",
  "session_id": "sess_67890",
  "page_url": "/product/electronics/smartphone",
  "referrer": "https://google.com",
  "user_agent": "Mozilla/5.0...",
  "device_type": "mobile"
}
```

#### 📦 Productos
```json
{
  "product_id": "prod_111",
  "name": "Smartphone Pro Max",
  "category": "electronics",
  "brand": "TechBrand",
  "price": 899.99,
  "currency": "USD",
  "stock_quantity": 150,
  "attributes": {
    "color": "black",
    "storage": "256GB",
    "screen_size": "6.7"
  },
  "created_at": "2025-07-16T10:30:00Z",
  "updated_at": "2025-07-16T10:30:00Z"
}
```

## 🔍 Monitoreo y Alertas

### Métricas Clave

| Métrica | Umbral | Acción |
|---------|--------|--------|
| **Kinesis IncomingRecords** | > 1000/min | Scale up shards |
| **Firehose DeliveryErrors** | > 1% | Investigar y alertar |
| **Redshift CPU** | > 80% | Scale up cluster |
| **S3 Storage** | > 1TB | Revisar lifecycle policies |
| **Lambda Errors** | > 5% | Alertar al equipo |

### 📧 Configuración de Alertas

```bash
# Configurar email de notificaciones
aws sns create-topic --name ecommerce-alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:ecommerce-alerts \
  --protocol email \
  --notification-endpoint ruben.martin@tuempresa.com
```

## 💾 Backup y Recuperación

### Estrategia de Backup

| Componente | Frecuencia | Retención | Ubicación |
|------------|------------|-----------|-----------|
| **Redshift** | Automático (24h) | 7-30 días | S3 cross-region |
| **S3 Data** | Continuo (versionado) | Según lifecycle | Glacier/Deep Archive |
| **Configuración** | Manual | Permanente | Git repository |

### 🔄 Procedimiento de Recuperación

```bash
# Restaurar cluster Redshift
aws redshift restore-from-cluster-snapshot \
  --cluster-identifier ecommerce-dw-restored \
  --snapshot-identifier ecommerce-dw-snapshot-2025-07-16

# Verificar integridad de datos
psql -h redshift-cluster.region.redshift.amazonaws.com \
     -U admin -d ecommerce \
     -c "SELECT COUNT(*) FROM transactions WHERE date >= '2025-07-15';"
```

## 🔐 Seguridad

### Cifrado

- **En reposo:** AES-256 con AWS KMS
- **En tránsito:** TLS 1.2+
- **Claves:** Rotación automática anual

### Control de Acceso

```bash
# Crear usuario desarrollador
aws iam create-user --user-name developer-juan
aws iam add-user-to-group --user-name developer-juan --group-name ecommerce-data-platform-dev-developers

# Generar credenciales de acceso
aws iam create-access-key --user-name developer-juan
```

### Auditoría

- **CloudTrail:** Registro de todas las API calls
- **VPC Flow Logs:** Monitoreo de tráfico de red
- **CloudWatch Logs:** Logs de aplicaciones centralizados

## 🔧 Operaciones

### Comandos Útiles

```bash
# Ver estado de la infraestructura
terraform show

# Verificar configuración
terraform validate

# Planificar cambios
terraform plan -var="environment=prod"

# Aplicar cambios específicos
terraform apply -target=module.kinesis

# Ver outputs importantes
terraform output

# Destruir entorno de desarrollo
terraform destroy -var="environment=dev" -auto-approve
```

### 📈 Escalamiento

#### Kinesis Data Streams
```bash
# Aumentar shards manualmente
aws kinesis update-shard-count \
  --stream-name ecommerce-data-platform-prod-ecommerce-events \
  --target-shard-count 8 \
  --scaling-type UNIFORM_SCALING
```

#### Redshift
```bash
# Resize cluster
aws redshift modify-cluster \
  --cluster-identifier ecommerce-data-platform-prod-ecommerce-dw \
  --node-type dc2.8xlarge \
  --number-of-nodes 4
```

### 🔍 Troubleshooting

#### Problemas Comunes

**1. Kinesis Throttling**
```bash
# Verificar métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=ecommerce-events \
  --start-time 2025-07-16T09:00:00Z \
  --end-time 2025-07-16T10:00:00Z \
  --period 300 \
  --statistics Sum
```

**2. Firehose Delivery Errors**
```bash
# Revisar logs de error
aws logs filter-log-events \
  --log-group-name /aws/kinesisfirehose/ecommerce-data-firehose \
  --filter-pattern "ERROR"
```

**3. Redshift Connection Issues**
```bash
# Verificar security group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*redshift*"

# Test de conectividad
telnet redshift-cluster.region.redshift.amazonaws.com 5439
```

## 📊 Análisis de Datos

### Consultas SQL de Ejemplo

#### Análisis de Ventas
```sql
-- Top 10 productos más vendidos
SELECT 
    p.product_name,
    SUM(t.quantity) as total_quantity,
    SUM(t.total_amount) as revenue
FROM transactions t
JOIN products p ON t.product_id = p.product_id
WHERE t.transaction_date >= '2025-07-01'
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;
```

#### Análisis de Comportamiento
```sql
-- Funnel de conversión por hora
SELECT 
    EXTRACT(hour FROM timestamp) as hour,
    COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
    COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END) as add_to_cart,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) as purchases,
    ROUND(
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN event_type = 'page_view' THEN 1 END), 0), 2
    ) as conversion_rate
FROM events
WHERE DATE(timestamp) = '2025-07-16'
GROUP BY hour
ORDER BY hour;
```

#### Segmentación de Clientes
```sql
-- RFM Analysis
WITH customer_metrics AS (
    SELECT 
        customer_id,
        MAX(transaction_date) as last_purchase,
        COUNT(*) as frequency,
        SUM(total_amount) as monetary
    FROM transactions
    WHERE transaction_date >= '2025-01-01'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        NTILE(5) OVER (ORDER BY last_purchase DESC) as recency_score,
        NTILE(5) OVER (ORDER BY frequency) as frequency_score,
        NTILE(5) OVER (ORDER BY monetary) as monetary_score
    FROM customer_metrics
)
SELECT 
    customer_id,
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 3 AND frequency_score <= 2 THEN 'Potential Loyalists'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        ELSE 'Others'
    END as customer_segment
FROM rfm_scores;
```

## 🧪 Testing

### Tests de Infraestructura

```bash
# Validar configuración Terraform
terraform validate

# Formato de código
terraform fmt -recursive

# Linting con tflint
tflint --init
tflint

# Security scanning con Checkov
checkov -f main.tf
```

### Tests de Datos

```python
# test_data_quality.py - Ruben Martin
import boto3
import json
import pytest
from datetime import datetime

def test_kinesis_stream_exists():
    """Verificar que el stream de Kinesis existe y está activo"""
    kinesis = boto3.client('kinesis', region_name='us-east-1')
    
    response = kinesis.describe_stream(
        StreamName='ecommerce-data-platform-dev-ecommerce-events'
    )
    
    assert response['StreamDescription']['StreamStatus'] == 'ACTIVE'
    assert response['StreamDescription']['Shards']

def test_s3_bucket_encryption():
    """Verificar que el bucket S3 tiene cifrado habilitado"""
    s3 = boto3.client('s3')
    
    response = s3.get_bucket_encryption(
        Bucket='ecommerce-data-platform-dev-datalake-12345678'
    )
    
    assert 'ServerSideEncryptionConfiguration' in response
    rules = response['ServerSideEncryptionConfiguration']['Rules']
    assert any(rule['ApplyServerSideEncryptionByDefault']['SSEAlgorithm'] == 'aws:kms' 
              for rule in rules)

def test_redshift_cluster_health():
    """Verificar que el cluster Redshift está disponible"""
    redshift = boto3.client('redshift')
    
    response = redshift.describe_clusters(
        ClusterIdentifier='ecommerce-data-platform-dev-ecommerce-dw'
    )
    
    cluster = response['Clusters'][0]
    assert cluster['ClusterStatus'] == 'available'
    assert cluster['Encrypted'] == True
```

### Tests de Pipeline

```python
# test_data_pipeline.py - Ruben Martin
import json
import boto3
from moto import mock_kinesis, mock_s3

@mock_kinesis
@mock_s3
def test_end_to_end_pipeline():
    """Test completo del pipeline de datos"""
    # Setup
    kinesis = boto3.client('kinesis', region_name='us-east-1')
    s3 = boto3.client('s3', region_name='us-east-1')
    
    # Crear recursos mock
    kinesis.create_stream(StreamName='test-stream', ShardCount=1)
    s3.create_bucket(Bucket='test-bucket')
    
    # Datos de prueba
    test_event = {
        "event_type": "purchase",
        "timestamp": datetime.utcnow().isoformat(),
        "customer_id": "test_customer_123",
        "amount": 99.99
    }
    
    # Enviar datos a Kinesis
    response = kinesis.put_record(
        StreamName='test-stream',
        Data=json.dumps(test_event),
        PartitionKey='test_customer_123'
    )
    
    assert response['ResponseMetadata']['HTTPStatusCode'] == 200
```

## 📱 APIs y SDKs

### API de Ingesta

```python
# ingest_api.py - Ruben Martin
import boto3
import json
from datetime import datetime

class EcommerceDataIngester:
    """
    Cliente para enviar datos al pipeline de e-commerce
    Autor: Ruben Martin
    """
    
    def __init__(self, stream_name, region='us-east-1'):
        self.kinesis = boto3.client('kinesis', region_name=region)
        self.stream_name = stream_name
    
    def send_transaction(self, transaction_data):
        """Enviar datos de transacción"""
        # Validar datos requeridos
        required_fields = ['customer_id', 'amount', 'currency']
        for field in required_fields:
            if field not in transaction_data:
                raise ValueError(f"Campo requerido faltante: {field}")
        
        # Enriquecer con timestamp
        transaction_data['timestamp'] = datetime.utcnow().isoformat()
        transaction_data['event_type'] = 'transaction'
        
        # Enviar a Kinesis
        response = self.kinesis.put_record(
            StreamName=self.stream_name,
            Data=json.dumps(transaction_data),
            PartitionKey=transaction_data['customer_id']
        )
        
        return response['SequenceNumber']
    
    def send_user_event(self, event_data):
        """Enviar evento de usuario"""
        event_data['timestamp'] = datetime.utcnow().isoformat()
        
        response = self.kinesis.put_record(
            StreamName=self.stream_name,
            Data=json.dumps(event_data),
            PartitionKey=event_data.get('user_id', 'anonymous')
        )
        
        return response['SequenceNumber']

# Ejemplo de uso
ingester = EcommerceDataIngester('ecommerce-data-platform-prod-ecommerce-events')

# Enviar transacción
transaction = {
    'customer_id': 'cust_12345',
    'amount': 129.99,
    'currency': 'USD',
    'items': [
        {'product_id': 'prod_567', 'quantity': 1, 'price': 129.99}
    ]
}
sequence_number = ingester.send_transaction(transaction)
print(f"Transacción enviada: {sequence_number}")
```

### SDK JavaScript

```javascript
// ecommerce-analytics.js - Ruben Martin
class EcommerceAnalytics {
    constructor(config) {
        this.apiGatewayUrl = config.apiGatewayUrl;
        this.apiKey = config.apiKey;
    }
    
    // Rastrear evento de página
    trackPageView(pageData) {
        return this.sendEvent('page_view', {
            page_url: pageData.url,
            referrer: document.referrer,
            user_agent: navigator.userAgent,
            timestamp: new Date().toISOString()
        });
    }
    
    // Rastrear evento de producto
    trackProductView(productData) {
        return this.sendEvent('product_view', {
            product_id: productData.id,
            product_name: productData.name,
            category: productData.category,
            price: productData.price
        });
    }
    
    // Rastrear transacción
    trackPurchase(transactionData) {
        return this.sendEvent('purchase', transactionData);
    }
    
    async sendEvent(eventType, data) {
        const payload = {
            event_type: eventType,
            ...data,
            session_id: this.getSessionId(),
            user_id: this.getUserId()
        };
        
        try {
            const response = await fetch(`${this.apiGatewayUrl}/events`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': this.apiKey
                },
                body: JSON.stringify(payload)
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('Error enviando evento:', error);
            throw error;
        }
    }
    
    getSessionId() {
        // Implementar lógica de sesión
        return sessionStorage.getItem('session_id') || 'anonymous';
    }
    
    getUserId() {
        // Implementar lógica de usuario
        return localStorage.getItem('user_id') || null;
    }
}

// Uso
const analytics = new EcommerceAnalytics({
    apiGatewayUrl: 'https://api.tudominio.com',
    apiKey: 'tu-api-key'
});

// Rastrear automáticamente page views
analytics.trackPageView({ url: window.location.href });
```

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml - Ruben Martin
name: Deploy E-commerce Data Platform

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  TF_VERSION: 1.5.0
  AWS_REGION: us-east-1

jobs:
  validate:
    name: Validate Terraform
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
      
      - name: Terraform Init
        run: terraform init -backend=false
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Run Security Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform

  deploy-dev:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/develop'
    environment: development
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Plan
        run: terraform plan -var="environment=dev" -out=tfplan
      
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
      
      - name: Run Integration Tests
        run: |
          pip install pytest boto3 moto
          pytest tests/ -v

  deploy-prod:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID_PROD }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY_PROD }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Plan
        run: terraform plan -var="environment=prod" -out=tfplan
      
      - name: Manual Approval
        uses: trstringer/manual-approval@v1
        with:
          secret: ${{ github.TOKEN }}
          approvers: ruben-martin
          minimum-approvals: 1
          issue-title: "Deploy to Production"
      
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
      
      - name: Notify Success
        uses: 8398a7/action-slack@v3
        with:
          status: success
          text: "🚀 Production deployment successful!"
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## 📋 Checklist de Despliegue

### Pre-despliegue
- [ ] ✅ Credenciales AWS configuradas
- [ ] ✅ Variables de entorno definidas
- [ ] ✅ Permisos IAM verificados
- [ ] ✅ Límites de servicio revisados
- [ ] ✅ Backup de configuración existente

### Despliegue
- [ ] ✅ `terraform validate` exitoso
- [ ] ✅ `terraform plan` revisado
- [ ] ✅ Tests de seguridad pasados
- [ ] ✅ `terraform apply` ejecutado
- [ ] ✅ Outputs verificados

### Post-despliegue
- [ ] ✅ Health checks pasados
- [ ] ✅ Métricas en CloudWatch operativas
- [ ] ✅ Alertas configuradas
- [ ] ✅ Tests de integración exitosos
- [ ] ✅ Documentación actualizada

## 🤝 Contribuciones

### Guía para Desarrolladores

1. **Fork del repositorio**
2. **Crear rama feature:** `git checkout -b feature/nueva-funcionalidad`
3. **Commitear cambios:** `git commit -am 'Agregar nueva funcionalidad'`
4. **Push a la rama:** `git push origin feature/nueva-funcionalidad`
5. **Crear Pull Request**

### Estándares de Código

- **Terraform:** Seguir [estándares de HashiCorp](https://www.terraform.io/docs/language/syntax/style.html)
- **Python:** PEP 8 compliance
- **SQL:** Mayúsculas para keywords, snake_case para nombres
- **Documentación:** Comentarios en español, autor claramente identificado

## 📞 Soporte

### Contacto

**👨‍💻 Autor:** Ruben Martin  
**📧 Email:** ruben.martin@tuempresa.com  
**🔗 LinkedIn:** [Ruben Martin](https://linkedin.com/in/ruben-martin)  

### Issues Conocidos

| Issue | Descripción | Workaround | Status |
|-------|-------------|------------|--------|
| #001 | Latencia en Kinesis Analytics | Aumentar memory allocation | ✅ Resuelto |
| #002 | Timeout en Lambda para archivos grandes | Implementar procesamiento por chunks | 🔄 En progreso |

### FAQ

**Q: ¿Cómo cambio el número de shards en Kinesis?**  
A: Modifica la variable `kinesis_shard_count` en `terraform.tfvars` y ejecuta `terraform apply`.

**Q: ¿Puedo usar mi propia clave KMS?**  
A: Sí, modifica el módulo KMS para usar una clave existente en lugar de crear una nueva.

**Q: ¿Cómo escalo el cluster Redshift?**  
A: Actualiza las variables `redshift_node_type` y `redshift_number_of_nodes` y aplica los cambios.

---

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Agradecimientos

- **AWS Well-Architected Framework** por las mejores prácticas
- **Terraform Community** por los módulos y ejemplos
- **Equipo de Data Engineering** por el feedback y testing

---

**📅 Última actualización:** 2025-07-16  
**✨ Creado con ❤️ por Ruben Martin** "README.md"
