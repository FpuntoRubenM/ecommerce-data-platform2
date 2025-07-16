# 🏪 E-commerce Data Platform en AWS

[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ruben%20Martin-blue?style=flat-square)](https://github.com/FpuntoRubenM)

**Autor:** Ruben Martin  
**Versión:** 2.0.0  
**Fecha:** 2025-07-16  

> 🚀 Plataforma de datos de comercio electrónico construida en AWS siguiendo las mejores prácticas del **AWS Well-Architected Framework**.

## 📸 Arquitectura

```mermaid
graph TB
    A[Data Sources] --> B[Kinesis Data Streams]
    B --> C[Kinesis Data Analytics]
    B --> D[Kinesis Data Firehose]
    D --> E[Amazon S3]
    D --> F[Amazon Redshift]
    E --> G[Lambda Processor]
    G --> E
    F --> H[BI Dashboard]
    
    subgraph "Security Layer"
        I[KMS Encryption]
        J[VPC + Private Subnets]
        K[IAM Roles]
    end
    
    subgraph "Monitoring"
        L[CloudWatch]
        M[SNS Alerts]
    end





# 1. Clonar repositorio
git clone https://github.com/FpuntoRubenM/ecommerce-data-platform.git
cd ecommerce-data-platform

# 2. Configurar variables
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

# 3. Desplegar
make init
make plan ENV=dev
make apply ENV=dev
ecommerce-data-platform/
├── main.tf                     # Infraestructura principal
├── variables.tf                # Variables y validaciones
├── terraform.tfvars.example    # Ejemplo de configuración
├── modules/
│   ├── iam/                    # Roles y políticas IAM
│   ├── s3/                     # Bucket S3 y Lambda processor
│   ├── kms/                    # Claves de cifrado
│   ├── kinesis/                # Streams y Firehose
│   ├── redshift/               # Data Warehouse
│   └── monitoring/             # CloudWatch y alertas
├── tests/                      # Tests automatizados
├── docs/                       # Documentación adicional
└── .github/workflows/          # CI/CD con GitHub Actions



### **4. Crear Workflow de GitHub Actions**

```bash
mkdir -p .github/workflows

cat > .github/workflows/terraform.yml << 'EOF'
name: 'Terraform CI/CD Pipeline'

# Autor: Ruben Martin
# Descripción: Pipeline automatizado para despliegue de infraestructura

on:
  push:
    branches: [ "main", "develop" ]
  pull_request:
    branches: [ "main" ]

permissions:
  contents: read
  pull-requests: write

env:
  TF_VERSION: '1.5.0'
  AWS_REGION: 'us-east-1'

jobs:
  terraform-check:
    name: 'Terraform Check'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

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

    - name: Run Checkov Security Scan
      uses: bridgecrewio/checkov-action@master
      with:
        directory: .
        framework: terraform
        output_format: sarif
        download_external_modules: true

  terraform-plan:
    name: 'Terraform Plan'
    runs-on: ubuntu-latest
    needs: terraform-check
    if: github.event_name == 'pull_request'
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

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
      run: |
        terraform plan -var="environment=dev" -no-color -out=tfplan
        terraform show -no-color tfplan > plan_output.txt

    - name: Comment PR
      uses: actions/github-script@v6
      if: github.event_name == 'pull_request'
      with:
        script: |
          const fs = require('fs');
          const plan = fs.readFileSync('plan_output.txt', 'utf8');
          const maxGitHubBodyCharacters = 65536;
          
          function chunkSubstr(str, size) {
            const numChunks = Math.ceil(str.length / size);
            const chunks = new Array(numChunks);
            for (let i = 0, o = 0; i < numChunks; ++i, o += size) {
              chunks[i] = str.substr(o, size);
            }
            return chunks;
          }
          
          const body = `## Terraform Plan 🚀
          **Autor: Ruben Martin**
          
          \`\`\`terraform
          ${plan}
          \`\`\`
          
          *Pusheado por: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;
          
          if (body.length > maxGitHubBodyCharacters) {
            const truncatedBody = body.substr(0, maxGitHubBodyCharacters) + "\n... (truncated)";
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: truncatedBody
            });
          } else {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });
          }

  terraform-apply:
    name: 'Terraform Apply'
    runs-on: ubuntu-latest
    needs: terraform-check
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

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

    - name: Terraform Apply
      run: terraform apply -var="environment=prod" -auto-approve

    - name: Notify Success
      if: success()
      run: |
        echo "✅ Deployment successful by Ruben Martin!"
        echo "🚀 E-commerce Data Platform deployed to production"
