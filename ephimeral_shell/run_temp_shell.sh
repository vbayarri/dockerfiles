#!/bin/bash

# --- CONFIGURACIÓN ---
IMAGE_NAME="alpine-dev-test"
CONTAINER_NAME="alpine-temp-shell"
VOLUME_NAME="alpine-dev-home"
UPDATE_CHECK_INTERVAL_DAYS=7  # Verificar actualizaciones cada 7 días
LAST_CHECK_FILE="$HOME/.cache/alpine-dev-last-check"

# Verificar si el agente SSH está disponible (necesario para la YubiKey)
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "🚨 ADVERTENCIA: La variable \$SSH_AUTH_SOCK no está configurada."
    echo "  Si planeas usar Git a través de SSH (con o sin YubiKey), inicia el agente SSH primero."
    echo "  Ejemplo: eval \$(ssh-agent -s) && ssh-add ~/.ssh/id_ed25519_sk"
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
echo "🚀 Ejecutando el contenedor temporal e interactivo. Escribe 'exit' para salir y eliminarlo."

# Define los comandos de inicio: Clonar dotfiles (solo si no existen) y luego iniciar Bash
INIT_COMMANDS="
    # Verificar si los dotfiles ya están configurados
    if [ -d ~/dotfiles ]; then
        echo '✅ Dotfiles ya están configurados. Saltando setup...'
    else
        echo '🔧 Primera ejecución detectada. Configurando dotfiles...'

        # 0. Configurar SSH known_hosts para GitHub (evitar prompt interactivo)
        mkdir -p ~/.ssh
        ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null

        # 1. Comando de clonación de dotfiles (Ajusta la URL de tu repositorio)
        # Usamos HTTPS si la clave SSH no se carga automáticamente, o SSH si usas la clave YubiKey.
        # Recomendación: Si usas YubiKey, usa SSH. Si no, usa HTTPS.
        if git clone git@github.com:vbayarri/dotfiles.git ~/dotfiles; then
            echo '✅ Dotfiles clonados exitosamente'

            # 2. Comando para inicializar tus dotfiles (ej. un script de setup)
            if [ -f ~/dotfiles/scripts/install-dependencies.sh ]; then
                ~/dotfiles/scripts/install-dependencies.sh > /dev/null 2>&1
                echo '✅ Dotfiles configurados exitosamente'
            else
                echo '⚠️ Script install-dependencies.sh no encontrado, saltando...'
            fi
        else
            echo '❌ Error al clonar dotfiles. Continuando sin dotfiles...'
        fi
    fi

    # 3. Iniciar la shell interactiva en el directorio home
    cd ~ && /bin/zsh
"

docker run \
    --rm \
    -it \
    --name "$CONTAINER_NAME" \
    -v "$(pwd)":/app \
    -v "$VOLUME_NAME":/root \
    -v "$SSH_AUTH_SOCK":"$SSH_AUTH_SOCK" \
    -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
    "$IMAGE_NAME" \
    /bin/bash -c "$INIT_COMMANDS" # Ejecuta los comandos definidos arriba

echo "✅ Contenedor temporal finalizado y eliminado."
echo "💾 Datos persistidos en el volumen: $VOLUME_NAME"
echo "   (Para resetear todo, ejecuta: docker volume rm $VOLUME_NAME)"
