#!/bin/bash

# --- CONFIGURACIÓN ---
IMAGE_NAME="homelab-cli"
CONTAINER_NAME="homelab-temp"
VOLUME_NAME="homelab-home"
UPDATE_CHECK_INTERVAL_DAYS=7  # Verificar actualizaciones cada 7 días
LAST_CHECK_FILE="$HOME/.cache/homelab-cli-last-check"
WORKSPACE_DIR="$HOME/homelab/proxmox-terraform"
SSH_DIR="$HOME/.ssh"

# Verificar que el directorio de trabajo existe
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "❌ Error: El directorio $WORKSPACE_DIR no existe."
    echo "   Crea el directorio primero: mkdir -p $WORKSPACE_DIR"
    exit 1
fi

# Verificar que el directorio SSH existe
if [ ! -d "$SSH_DIR" ]; then
    echo "⚠️ Advertencia: El directorio SSH $SSH_DIR no existe. No se montará."
    SSH_MOUNT=""
else
    SSH_MOUNT="-v $SSH_DIR:/root/.ssh:ro"
fi

# --- 1. CONSTRUIR LA IMAGEN (solo si no existe o hay actualizaciones) ---
# Determinar si necesitamos verificar actualizaciones
SHOULD_CHECK_UPDATES=false
NEEDS_REBUILD=false

# Verificar si la imagen existe
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "⚙️ Imagen no encontrada. Construyendo la imagen Docker: $IMAGE_NAME"
    NEEDS_REBUILD=true
    SHOULD_CHECK_UPDATES=true
else
    # Verificar si ha pasado suficiente tiempo desde la última verificación
    if [ -f "$LAST_CHECK_FILE" ]; then
        LAST_CHECK=$(cat "$LAST_CHECK_FILE")
        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$(( (CURRENT_TIME - LAST_CHECK) / 86400 ))  # Diferencia en días

        if [ $TIME_DIFF -ge $UPDATE_CHECK_INTERVAL_DAYS ]; then
            SHOULD_CHECK_UPDATES=true
        fi
    else
        # Primera ejecución, crear el archivo de verificación
        SHOULD_CHECK_UPDATES=true
    fi
fi

# Verificar actualizaciones de Alpine si es necesario
if [ "$SHOULD_CHECK_UPDATES" = true ]; then
    echo "🔍 Verificando actualizaciones de Alpine (última verificación hace $TIME_DIFF días)..."
    ALPINE_BEFORE=$(docker images -q alpine:latest)
    docker pull alpine:latest --quiet
    ALPINE_AFTER=$(docker images -q alpine:latest)

    # Guardar el timestamp de esta verificación
    mkdir -p "$(dirname "$LAST_CHECK_FILE")"
    date +%s > "$LAST_CHECK_FILE"

    if [ "$ALPINE_BEFORE" != "$ALPINE_AFTER" ] && [ -n "$ALPINE_AFTER" ]; then
        echo "🆕 Nueva versión de Alpine detectada. Reconstruyendo imagen..."
        NEEDS_REBUILD=true
    elif [ "$NEEDS_REBUILD" = false ]; then
        echo "✅ Alpine está actualizado."
    fi
else
    echo "✅ Imagen $IMAGE_NAME existe. Saltando verificación de actualizaciones."
    echo "   (Última verificación: hace $TIME_DIFF días, próxima en $(( UPDATE_CHECK_INTERVAL_DAYS - TIME_DIFF )) días)"
fi

# Construir si es necesario
if [ "$NEEDS_REBUILD" = true ]; then
    docker build -t "$IMAGE_NAME" .

    if [ $? -ne 0 ]; then
        echo "❌ Error al construir la imagen. Abortando."
        exit 1
    fi
else
    echo "   (Para reconstruir manualmente, ejecuta: docker rmi $IMAGE_NAME)"
fi

# --- 2. EJECUTAR EL CONTENEDOR TEMPORAL E INTERACTIVO ---
echo "🚀 Ejecutando el contenedor Homelab CLI. Escribe 'exit' para salir y eliminarlo."
echo "📁 Directorio de trabajo: $WORKSPACE_DIR"

# Define los comandos de inicio
INIT_COMMANDS="
    # Verificar si es la primera ejecución
    if [ ! -f ~/.homelab_setup_done ]; then
        echo '🔧 Primera ejecución detectada.'
        echo ''
        echo '📋 Entorno Homelab CLI listo con Terraform. Comandos útiles:'
        echo '   • terraform init      - Inicializar el directorio de trabajo'
        echo '   • terraform plan      - Ver cambios planificados'
        echo '   • terraform apply     - Aplicar cambios'
        echo '   • terraform destroy   - Destruir infraestructura'
        echo ''
        echo 'Tu configuración persistirá entre sesiones gracias al volumen Docker.'
        echo ''
        touch ~/.homelab_setup_done
    else
        echo '✅ Entorno Homelab CLI configurado.'
        echo '📁 Trabajando en: /workspace'
        echo ''
    fi

    # Mostrar versión de Terraform
    terraform version
    echo ''

    # Iniciar la shell interactiva
    cd /workspace && /bin/bash
"

docker run \
    --rm \
    -it \
    --name "$CONTAINER_NAME" \
    -v "$WORKSPACE_DIR":/workspace \
    -v "$VOLUME_NAME":/root \
    $(echo $SSH_MOUNT) \
    -v $SSH_AUTH_SOCK:/ssh-agent \
    -e SSH_AUTH_SOCK=/ssh-agent \
    "$IMAGE_NAME" \
    /bin/bash -c "$INIT_COMMANDS"

echo "✅ Contenedor temporal finalizado y eliminado."
echo "💾 Datos persistidos en el volumen: $VOLUME_NAME"
echo "   (Para resetear configuración, ejecuta: docker volume rm $VOLUME_NAME)"
