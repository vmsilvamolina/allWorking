# DevOps Demo — Deploy de Ambiente en AWS

Proyecto de demostración para el curso de DevOps. Contiene una aplicación Go desplegada en AWS ECS Fargate, con infraestructura gestionada por Terraform y un pipeline CI/CD en GitHub Actions con scans de seguridad integrados.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                      GitHub Actions                     │
│                                                         │
│  code-scan ──► build & push ──► image-scan ──► deploy   │
│  (Semgrep)      (ECR)           (Trivy)        (ECS)    │
└─────────────────────────────────────────────────────────┘
                          │
                    ┌─────▼──────┐
                    │  Amazon    │
                    │    ECR     │  ← web-app-{env}:{sha}
                    └─────┬──────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                        AWS VPC                          │
│                                                         │
│  Internet ──► ALB (público) ──► ECS Fargate (privado)   │
│                                   └── Task: web-app     │
│                                       Puerto: 8080      │
└─────────────────────────────────────────────────────────┘
```

**Ambientes disponibles:**

| Ambiente  | Rama Git  | CIDR VPC     | CPU / Mem       | Réplicas |
|-----------|-----------|--------------|-----------------|----------|
| `dev`     | `dev`     | 10.0.0.0/16  | 256 / 512 MB    | 1        |
| `staging` | `staging` | 10.1.0.0/16  | 512 / 1024 MB   | 1        |
| `prod`    | `main`    | 10.2.0.0/16  | 1024 / 2048 MB  | 2        |

---

## Estructura del proyecto

```
.
├── .github/
│   └── workflows/
│       ├── app.yaml        # Pipeline CI/CD de la aplicación
│       └── infra.yaml      # Pipeline de infraestructura Terraform
├── app/
│   ├── Dockerfile          # Multi-stage build: golang → alpine
│   └── main.go             # Servidor HTTP en Go (puerto 8080)
├── environments/
│   ├── dev/                # Variables y backend para dev
│   ├── staging/            # Variables y backend para staging
│   └── prod/               # Variables y backend para prod
└── modules/
    ├── ecr/                # Repositorio ECR
    ├── ecs/                # Cluster ECS
    ├── ecs_service/        # Servicio, task definition, ALB, SGs
    └── networking/         # VPC, subnets, route tables
```

---

## Pre-requisitos

Antes de desplegar, verificar que se tiene:

- [ ] Cuenta AWS con permisos para crear VPC, ECS, ECR, IAM, ALB
- [ ] [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) instalado y configurado
- [ ] [Terraform >= 1.5](https://developer.hashicorp.com/terraform/install) instalado
- [ ] [Docker](https://docs.docker.com/get-docker/) instalado (para pruebas locales)
- [ ] Repositorio en GitHub con Actions habilitado
- [ ] Bucket S3 creado para el estado de Terraform (ver paso 1)

---

## Paso 1 — Configurar el backend de Terraform

El estado de Terraform se almacena en S3. Crear el bucket antes de inicializar:

```bash
# Crear el bucket (nombre debe ser único globalmente)
aws s3api create-bucket \
  --bucket mi-proyecto-tfstate \
  --region us-east-1

# Habilitar versionado (permite recuperar estados anteriores)
aws s3api put-bucket-versioning \
  --bucket mi-proyecto-tfstate \
  --versioning-configuration Status=Enabled
```

Luego editar `environments/dev/terraform.tf` y completar el nombre del bucket:

```hcl
backend "s3" {
  bucket  = "mi-proyecto-tfstate"   # ← completar aquí
  key     = "dev/terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
}
```

> **Nota para el curso:** Si no se dispone de un bucket S3, se puede eliminar el bloque `backend "s3"` completo. Terraform usará un archivo local `terraform.tfstate`. Funciona para demo pero **no** es apto para trabajo en equipo.

---

## Paso 2 — Configurar secretos en GitHub

Ir a **Settings → Secrets and variables → Actions** y agregar:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key de la cuenta AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret key de la cuenta AWS |
| `AWS_SESSION_TOKEN` | Session token (requerido en cuentas de laboratorio) |
| `SEMGREP_APP_TOKEN` | *(Opcional)* Token de Semgrep Cloud para dashboard |

> **Importante:** Las credenciales con `AWS_SESSION_TOKEN` son temporales (expiran). Para ambientes permanentes se recomienda migrar a autenticación OIDC (ver sección de buenas prácticas al final).

---

## Paso 3 — Desplegar la infraestructura

El workflow de infraestructura se puede ejecutar de dos formas:

### Opción A — Via GitHub Actions (recomendado)

1. Ir a **Actions → Terraform CI/CD → Run workflow**
2. Seleccionar el ambiente: `dev`
3. Hacer click en **Run workflow**

El pipeline ejecuta automáticamente: `init` → `fmt` → `validate` → `plan` → `apply`.

### Opción B — Localmente (útil para debugging)

```bash
# Pararse en el directorio del ambiente
cd environments/dev

# Inicializar providers y backend
terraform init

# Verificar formato
terraform fmt -check -recursive

# Ver qué va a crear
terraform plan -var-file="terraform.tfvars"

# Aplicar (crea toda la infraestructura)
terraform apply -var-file="terraform.tfvars"
```

Al finalizar, Terraform imprime los outputs:

```
Outputs:

alb_dns_name       = "http://web-app-dev-alb-1234567890.us-east-1.elb.amazonaws.com"
ecr_repository_url = "123456789.dkr.ecr.us-east-1.amazonaws.com/web-app-dev"
```

> Guardar el `alb_dns_name` — es la URL pública de la aplicación.

---

## Paso 4 — Desplegar la aplicación

### Opción A — Via GitHub Actions (recomendado)

Hacer push a la rama `dev`:

```bash
git checkout dev
# ... hacer algún cambio en app/
git add app/
git commit -m "feat: actualizar mensaje de bienvenida"
git push origin dev
```

El pipeline se dispara automáticamente y ejecuta estos 4 jobs en secuencia:

```
[1] code-scan   → Semgrep analiza el código Go
[2] build-push  → Construye la imagen y la sube a ECR con tag = git SHA
[3] image-scan  → Trivy escanea la imagen en busca de CVEs
[4] deploy      → Registra nueva task definition y actualiza el servicio ECS
```

Se puede seguir el progreso en **Actions → App CI/CD**.

### Opción B — Build y push manual (solo para pruebas)

```bash
# Autenticarse en ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Construir la imagen
docker build -t web-app-dev ./app

# Etiquetar con el repositorio ECR
docker tag web-app-dev:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/web-app-dev:latest

# Subir la imagen
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/web-app-dev:latest
```

---

## Paso 5 — Verificar el despliegue

### Verificar que la aplicación responde

```bash
# Reemplazar con el DNS del ALB del output de Terraform
curl http://web-app-dev-alb-1234567890.us-east-1.elb.amazonaws.com/
# Esperado: <h1>Hello from ECS!</h1><p>Host: xxxxxxxx</p>

curl http://web-app-dev-alb-1234567890.us-east-1.elb.amazonaws.com/health
# Esperado: ok
```

### Verificar el estado del servicio ECS

```bash
aws ecs describe-services \
  --cluster ecs-cluster-dev \
  --services web-app-dev \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,TaskDef:taskDefinition}' \
  --output table
```

### Ver logs de la aplicación

```bash
# Listar los log streams disponibles
aws logs describe-log-streams \
  --log-group-name /ecs/web-app-dev \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Ver los últimos logs en tiempo real
aws logs tail /ecs/web-app-dev --follow
```

### Ver imágenes en ECR

```bash
aws ecr list-images \
  --repository-name web-app-dev \
  --query 'imageIds[*]' \
  --output table
```

---

## Paso 6 — Probar la app localmente (antes de desplegar)

```bash
# Construir la imagen
docker build -t web-app-local ./app

# Correr el contenedor
docker run -p 8080:8080 web-app-local

# Verificar en otra terminal
curl http://localhost:8080/
curl http://localhost:8080/health
```

---

## Paso 7 — Desplegar un ambiente diferente

Para desplegar `staging` o `prod`, el proceso es idéntico cambiando la rama o el input:

```bash
# Desplegar infraestructura de staging
# → Actions → Terraform CI/CD → Run workflow → staging

# Desplegar app en staging
git checkout staging
git merge dev          # traer los cambios desde dev
git push origin staging
```

O bien via `workflow_dispatch` seleccionando el ambiente en el dropdown de GitHub Actions.

---

## Pipeline CI/CD — Flujo completo

```
Push a rama dev / staging / main
            │
            ▼
    ┌───────────────┐
    │  code-scan    │  Semgrep --config=auto
    │  (Semgrep)    │  Falla si hay vulnerabilidades en el código
    └───────┬───────┘
            │ éxito
            ▼
    ┌───────────────┐
    │ build & push  │  docker build + push a ECR
    │               │  Tags: :<git-sha>  y  :latest
    └───────┬───────┘
            │ éxito
            ▼
    ┌───────────────┐
    │  image-scan   │  Trivy: CRITICAL + HIGH
    │  (Trivy)      │  Falla si hay CVEs con fix disponible
    └───────┬───────┘
            │ éxito
            ▼
    ┌───────────────┐
    │    deploy     │  Nueva task definition con imagen :<sha>
    │               │  aws ecs wait services-stable
    └───────────────┘
```

---

## Módulos Terraform — Referencia rápida

| Módulo | Recursos que crea |
|--------|-------------------|
| `networking` | VPC, subnets públicas/privadas, Internet Gateway, Route Tables, NAT Gateway |
| `ecs` | ECS Cluster (Fargate) |
| `ecr` | Repositorio ECR con scan on push activado |
| `ecs_service` | Task Definition, ECS Service, ALB, Target Group, Security Groups, CloudWatch Log Group |

---

## Destruir la infraestructura

> ⚠️ Esto elimina **todos** los recursos del ambiente. No usar en prod sin revisión previa.

```bash
cd environments/dev
terraform destroy -var-file="terraform.tfvars"
```

---

## Buenas prácticas implementadas

- **Separación de ambientes** — cada ambiente tiene su propia VPC, ECR, cluster y servicio.
- **Imágenes tagueadas por SHA** — trazabilidad completa entre código, imagen y despliegue.
- **Security gates** — Semgrep bloquea antes del build; Trivy bloquea antes del deploy.
- **Task definition versionada** — cada deploy registra una nueva revisión; rollback con un comando.
- **Logs centralizados** — CloudWatch Log Group `/ecs/{app_name}` con retención de 7 días.
- **Red privada** — los contenedores ECS corren en subnets privadas; solo el ALB es público.

---

## Próximos pasos recomendados

1. **Migrar a OIDC** — reemplazar las credenciales estáticas de AWS por un IAM Role federado con GitHub Actions.
2. **ECR Lifecycle Policy** — agregar en `modules/ecr/main.tf` para expirar imágenes viejas automáticamente.
3. **GitHub Environments** — configurar `required_reviewers` en prod para requerir aprobación manual antes del deploy.
4. **Pin de imagen base** — usar digest fijo en el Dockerfile: `FROM alpine:3.19@sha256:<digest>`.
5. **HTTPS en el ALB** — agregar un listener en puerto 443 con certificado ACM.
