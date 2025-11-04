#!/bin/bash

# --- CONFIGURACIÓN ---
IMAGE_NAME="gemini-cli-dev"
CONTAINER_NAME="gemini-cli-temp"
VOLUME_NAME="gemini-cli-home"
UPDATE_CHECK_INTERVAL_DAYS=7  # Verificar actualizaciones cada 7 días
LAST_CHECK_FILE="$HOME/.cache/gemini-cli-last-check"

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

# Verificar actualizaciones de Node.js si es necesario
if [ "$SHOULD_CHECK_UPDATES" = true ]; then
    echo "🔍 Verificando actualizaciones de Node.js 24 (última verificación hace $TIME_DIFF días)..."
    NODE_BEFORE=$(docker images -q node:24-slim)
    docker pull node:24-slim --quiet
    NODE_AFTER=$(docker images -q node:24-slim)

    # Guardar el timestamp de esta verificación
    mkdir -p "$(dirname "$LAST_CHECK_FILE")"
    date +%s > "$LAST_CHECK_FILE"

    if [ "$NODE_BEFORE" != "$NODE_AFTER" ] && [ -n "$NODE_AFTER" ]; then
        echo "🆕 Nueva versión de Node.js detectada. Reconstruyendo imagen..."
        NEEDS_REBUILD=true
    elif [ "$NEEDS_REBUILD" = false ]; then
        echo "✅ Node.js está actualizado."
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
echo "🚀 Ejecutando el contenedor Gemini CLI. Escribe 'exit' para salir y eliminarlo."

# Define los comandos de inicio
INIT_COMMANDS="
    # Verificar si es la primera ejecución
    if [ ! -f ~/.gemini_setup_done ]; then
        echo '🔧 Primera ejecución detectada.'
        echo ''
        echo '📋 Para usar Gemini CLI, necesitas autenticarte con tu cuenta de Google:'
        echo '   1. Ejecuta: npx @google/generative-ai-cli auth'
        echo '   2. Sigue las instrucciones para autenticarte'
        echo '   3. Una vez autenticado, usa: npx @google/generative-ai-cli chat'
        echo ''
        echo 'Tu autenticación persistirá entre sesiones gracias al volumen Docker.'
        echo ''
        touch ~/.gemini_setup_done
    else
        echo '✅ Gemini CLI configurado. Para iniciar chat: npx @google/generative-ai-cli chat'
        echo ''
    fi

    # Iniciar la shell interactiva
    cd /workspace && /bin/bash
"

docker run \
    --rm \
    -it \
    --name "$CONTAINER_NAME" \
    -v "$(pwd)":/workspace \
    -v "$VOLUME_NAME":/root \
    "$IMAGE_NAME" \
    /bin/bash -c "$INIT_COMMANDS"

echo "✅ Contenedor temporal finalizado y eliminado."
echo "💾 Datos persistidos en el volumen: $VOLUME_NAME"
echo "   (Para resetear autenticación y configuración, ejecuta: docker volume rm $VOLUME_NAME)"
