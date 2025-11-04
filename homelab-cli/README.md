# Homelab CLI

Entorno containerizado minimalista para trabajar con Terraform, específicamente configurado para gestión de infraestructura en Proxmox.

## Características

- **Imagen Alpine minimalista** - Base Alpine Linux con Terraform instalado desde releases oficiales
- **Contenedor efímero** - Se elimina al salir, pero con persistencia de configuración
- **Verificación automática de actualizaciones** - Cada 7 días comprueba si hay nuevas versiones de Alpine
- **Persistencia de estado y plugins** - Los archivos de estado y plugins de Terraform se mantienen entre sesiones
- **Directorio de trabajo mapeado** - Tu carpeta `~/homelab/proxmox-terraform` está disponible en `/workspace`
- **Herramientas esenciales** - Incluye bash, git, curl, openssh-client para operaciones básicas

## Requisitos

- Docker instalado y en ejecución
- Directorio `~/homelab/proxmox-terraform` creado en tu sistema

## Instalación y Uso

### Uso rápido

```bash
cd homelab-cli
./run_homelab.sh
```

El script automáticamente:
1. Verifica si existe la imagen Docker
2. Comprueba actualizaciones de Alpine (cada 7 días)
3. Construye o reconstruye la imagen si es necesario
4. Inicia un contenedor temporal con tu workspace montado

### Primera ejecución

En la primera ejecución verás un mensaje de bienvenida con comandos útiles de Terraform:

```bash
🔧 Primera ejecución detectada.

📋 Entorno Homelab CLI listo con Terraform. Comandos útiles:
   • terraform init      - Inicializar el directorio de trabajo
   • terraform plan      - Ver cambios planificados
   • terraform apply     - Aplicar cambios
   • terraform destroy   - Destruir infraestructura
```

### Workflow típico

Dentro del contenedor:

```bash
# 1. Inicializar Terraform (primera vez o después de cambios de providers)
terraform init

# 2. Ver los cambios que se aplicarán
terraform plan

# 3. Aplicar la configuración
terraform apply

# 4. Ver el estado actual
terraform show

# 5. Destruir infraestructura (si es necesario)
terraform destroy
```

## Estructura de archivos

```
homelab-cli/
├── Dockerfile         # Imagen Alpine minimalista con Terraform
├── run_homelab.sh    # Script de ejecución con gestión de actualizaciones
└── README.md         # Esta documentación
```

## Persistencia

### Qué se persiste

- **Configuración de Terraform** (`~/.terraform.d/`) - Plugins y configuración global
- **Credenciales y configuraciones** - Todo en `/root` del contenedor
- **Archivos de estado** - Si usas estado local (recomendado: usar backend remoto)

### Qué NO se persiste

- El contenedor en sí (se elimina al salir con `exit`)
- Cambios en la imagen base (se actualiza automáticamente)

## Gestión

### Ver versión de Terraform

Al iniciar el contenedor, automáticamente se muestra la versión:

```bash
Terraform v1.10.3
on linux_amd64
```

### Actualizar versión de Terraform

Para usar una versión diferente de Terraform, edita el `Dockerfile` y cambia:

```dockerfile
ARG TERRAFORM_VERSION=1.10.3  # Cambia a la versión deseada
```

Luego reconstruye la imagen:

```bash
docker rmi homelab-cli
./run_homelab.sh
```

### Resetear toda la configuración

Para empezar desde cero, elimina el volumen de Docker:

```bash
docker volume rm homelab-home
```

**⚠️ Advertencia:** Esto eliminará todos los plugins descargados y configuraciones guardadas.

### Ver el contenido del volumen

Para inspeccionar qué hay guardado en el volumen persistente:

```bash
docker run --rm -v homelab-home:/data alpine ls -la /data
```

## Directorio de trabajo

El directorio `~/homelab/proxmox-terraform` en tu máquina local está mapeado a `/workspace` dentro del contenedor. Todos tus archivos `.tf`, variables y configuraciones deben estar allí.

**Ejemplo de estructura recomendada:**

```
~/homelab/proxmox-terraform/
├── main.tf              # Configuración principal
├── variables.tf         # Definición de variables
├── terraform.tfvars     # Valores de variables (¡no subir a git!)
├── providers.tf         # Configuración de providers
└── outputs.tf          # Outputs de la infraestructura
```

## Solución de problemas

### El script no encuentra el directorio de trabajo

```bash
❌ Error: El directorio ~/homelab/proxmox-terraform no existe.
```

**Solución:**
```bash
mkdir -p ~/homelab/proxmox-terraform
```

### Error al construir la imagen

Si hay problemas al construir:

```bash
docker system prune -a  # Limpia imágenes no usadas
./run_homelab.sh       # Intenta de nuevo
```

### Terraform se queja de plugins faltantes

Ejecuta dentro del contenedor:

```bash
terraform init -upgrade
```

## Personalización

### Cambiar el intervalo de verificación de actualizaciones

Edita `run_homelab.sh` y modifica:

```bash
UPDATE_CHECK_INTERVAL_DAYS=7  # Cambia a los días que prefieras
```

### Añadir herramientas adicionales

Edita el `Dockerfile` y añade paquetes en la línea `apk add`:

```dockerfile
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    vim \
    nano \
    jq \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    ...
```

### Usar otra versión de Terraform

Cambia el argumento `TERRAFORM_VERSION` en el `Dockerfile`:

```dockerfile
ARG TERRAFORM_VERSION=1.9.0  # Versión específica
```

## Ventajas del enfoque minimalista

Esta imagen usa Alpine Linux como base y descarga el binario oficial de Terraform, lo que resulta en:

- **Imagen más pequeña** - ~50-80 MB vs ~100-150 MB de la imagen oficial
- **Mayor control** - Eliges exactamente qué versión de Terraform usar
- **Más seguridad** - Solo las dependencias esenciales instaladas
- **Transparencia** - Sabes exactamente qué hay en la imagen

## Notas de seguridad

- **Credenciales sensibles:** No incluyas credenciales directamente en archivos `.tf`. Usa variables de entorno o archivos `.tfvars` (que debes añadir a `.gitignore`)
- **Estado de Terraform:** Para producción, considera usar un backend remoto (S3, Terraform Cloud, etc.) en lugar de estado local
- **Volumen persistente:** El volumen `homelab-home` puede contener información sensible. Manéjalo con cuidado.

## Referencias

- [Documentación oficial de Terraform](https://www.terraform.io/docs)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Alpine Linux](https://alpinelinux.org/)
- [HashiCorp Releases](https://releases.hashicorp.com/terraform/)
