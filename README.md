# Dockerfiles

Colección de configuraciones Docker y entornos de desarrollo containerizados.

## Proyectos

### [Ephemeral Shell](./ephimeral_shell)

Entorno de desarrollo efímero basado en Alpine Linux con persistencia inteligente de configuración.

**Características:**
- Contenedor temporal que se elimina al salir
- Persistencia de dotfiles y configuraciones usando volúmenes Docker
- Setup automático de dotfiles solo en la primera ejecución
- Verificación periódica de actualizaciones de Alpine (cada 7 días)
- Herramientas preinstaladas: zsh, oh-my-posh, fzf, zoxide
- Soporte para YubiKey SSH

**Uso rápido:**
```bash
cd ephimeral_shell
./run_temp_shell.sh
```

Ver [documentación completa](./ephimeral_shell/README.md) para más detalles.

### [Gemini CLI](./gemini-cli)

Entorno containerizado para usar Google Gemini AI CLI con Node.js 24 LTS y persistencia de autenticación.

**Características:**
- Contenedor efímero con persistencia de autenticación OAuth
- Node.js 24 LTS (soporte hasta abril 2028)
- Verificación periódica de actualizaciones de Node.js (cada 7 días)
- Entorno aislado que no interfiere con instalaciones locales
- Acceso completo a Gemini CLI de Google

**Uso rápido:**
```bash
cd gemini-cli
./run_gemini.sh
# Dentro del contenedor:
npx @google/generative-ai-cli auth
npx @google/generative-ai-cli chat
```

Ver [documentación completa](./gemini-cli/README.md) para más detalles.

### [Homelab CLI](./homelab-cli)

Entorno containerizado minimalista para gestión de infraestructura con Terraform, específicamente configurado para trabajar con Proxmox.

**Características:**
- Imagen Alpine minimalista con Terraform (~50-80 MB)
- Contenedor efímero con persistencia de configuración y plugins
- Verificación periódica de actualizaciones de Alpine (cada 7 días)
- Directorio de trabajo mapeado a `~/homelab/proxmox-terraform`
- Herramientas esenciales: bash, git, curl, openssh-client

**Uso rápido:**
```bash
cd homelab-cli
./run_homelab.sh
# Dentro del contenedor:
terraform init
terraform plan
terraform apply
```

Ver [documentación completa](./homelab-cli/README.md) para más detalles.

## Estructura

```
dockerfiles/
├── ephimeral_shell/    # Entorno de desarrollo temporal con Alpine Linux
├── gemini-cli/         # Entorno para Google Gemini AI CLI con Node.js
├── homelab-cli/        # Entorno minimalista para Terraform con gestión de infraestructura
└── README.md          # Este archivo
```

## Requisitos Generales

- Docker instalado y en ejecución
- Bash para ejecutar los scripts

## Contribuir

Este es un repositorio personal de configuraciones Docker. Los proyectos están optimizados para uso personal pero pueden servir como referencia.
