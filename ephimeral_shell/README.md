# Ephemeral Shell - Entorno de Desarrollo Temporal con Docker

Entorno de desarrollo efímero basado en Alpine Linux con soporte para dotfiles, YubiKey SSH y persistencia de configuración.

## Características

- **Contenedor efímero**: Se elimina automáticamente al salir (con `--rm`)
- **Persistencia inteligente**: Los dotfiles y configuraciones persisten entre sesiones usando volúmenes Docker
- **Setup automático**: Clona y configura tus dotfiles solo en la primera ejecución
- **Optimización de imagen**: No reconstruye la imagen Docker si ya existe
- **Verificación periódica**: Revisa actualizaciones de Alpine cada 7 días automáticamente
- **Soporte YubiKey**: Integración con agente SSH para claves de hardware
- **Shell moderno**: Incluye zsh, oh-my-posh, fzf y zoxide preinstalados

## Funcionamiento

### 1. Construcción de Imagen

- **Primera ejecución**: Construye la imagen `alpine-dev-test` con todas las dependencias
- **Ejecuciones posteriores**: Reutiliza la imagen existente para inicio rápido
- **Actualizaciones automáticas**: Cada 7 días verifica si hay nueva versión de Alpine y reconstruye si es necesario

### 2. Gestión de Dotfiles

- **Primera ejecución**: Clona dotfiles desde GitHub y ejecuta el script de instalación
- **Ejecuciones posteriores**: Detecta que los dotfiles ya existen y los reutiliza
- Los dotfiles se almacenan en el volumen persistente `alpine-dev-home`

### 3. Persistencia de Datos

- **Volumen Docker**: `alpine-dev-home` montado en `/root`
- **Persiste**: Dotfiles, historial de shell, configuraciones SSH, archivos en home
- **No persiste**: Binarios del sistema (están en la imagen Docker)

### 4. Herramientas Incluidas

Instaladas en el Dockerfile (siempre disponibles):
- **bash**, **zsh**: Shells
- **git**, **curl**, **wget**: Herramientas de red
- **openssh-client**: Cliente SSH con soporte para YubiKey
- **fzf**: Búsqueda difusa interactiva
- **zoxide**: Navegación inteligente de directorios
- **oh-my-posh**: Motor de temas para el prompt

## Requisitos

- Docker instalado y en ejecución
- (Opcional) Agente SSH configurado para usar YubiKey:
  ```bash
  eval $(ssh-agent -s)
  ssh-add ~/.ssh/id_ed25519_sk
  ```

## Uso

### Inicio Rápido

```bash
./run_temp_shell.sh
```

### Primera Ejecución

```
🔍 Verificando actualizaciones de Alpine...
⚙️ Imagen no encontrada. Construyendo la imagen Docker: alpine-dev-test
🚀 Ejecutando el contenedor temporal e interactivo...
🔧 Primera ejecución detectada. Configurando dotfiles...
✅ Dotfiles clonados exitosamente
✅ Dotfiles configurados exitosamente
```

### Ejecuciones Posteriores

```
✅ Imagen alpine-dev-test existe. Saltando verificación de actualizaciones.
   (Última verificación: hace 2 días, próxima en 5 días)
🚀 Ejecutando el contenedor temporal e interactivo...
✅ Dotfiles ya están configurados. Saltando setup...
```

## Configuración

Edita las variables al inicio de `run_temp_shell.sh`:

```bash
IMAGE_NAME="alpine-dev-test"              # Nombre de la imagen Docker
CONTAINER_NAME="alpine-temp-shell"        # Nombre del contenedor
VOLUME_NAME="alpine-dev-home"             # Nombre del volumen persistente
UPDATE_CHECK_INTERVAL_DAYS=7              # Días entre verificaciones de actualización
```

## Comandos Útiles

### Forzar Reconstrucción de Imagen

```bash
docker rmi alpine-dev-test
./run_temp_shell.sh
```

### Resetear Dotfiles y Configuración

```bash
docker volume rm alpine-dev-home
./run_temp_shell.sh
```

### Forzar Verificación de Actualizaciones

```bash
rm ~/.cache/alpine-dev-last-check
./run_temp_shell.sh
```

### Ver Información del Volumen

```bash
docker volume inspect alpine-dev-home
```

## Estructura del Proyecto

```
.
├── Dockerfile              # Definición de la imagen Alpine con herramientas
├── run_temp_shell.sh       # Script principal de ejecución
└── README.md              # Esta documentación
```

## Optimizaciones Implementadas

1. **Cache de imagen Docker**: No reconstruye si la imagen ya existe
2. **Verificación periódica**: Solo verifica actualizaciones cada 7 días
3. **Setup único**: Dotfiles se configuran solo una vez
4. **Volumen persistente**: Home directory persiste entre sesiones
5. **Dependencias en imagen**: Herramientas instaladas en el Dockerfile, no en cada ejecución

## Personalización

### Cambiar Repositorio de Dotfiles

Edita la línea 64 en `run_temp_shell.sh`:

```bash
if git clone git@github.com:TU_USUARIO/dotfiles.git ~/dotfiles; then
```

### Ajustar Intervalo de Verificación

Cambia el valor en `run_temp_shell.sh`:

```bash
UPDATE_CHECK_INTERVAL_DAYS=14  # Verificar cada 2 semanas
```

## Notas

- El contenedor se elimina automáticamente al salir (`--rm`)
- Los datos persisten en el volumen Docker nombrado
- El directorio actual se monta en `/app` dentro del contenedor
- El agente SSH se comparte para acceso a YubiKey

## Licencia

Proyecto personal de entorno de desarrollo.
