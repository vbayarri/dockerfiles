#!/bin/bash

# --- CONFIGURACIÓN ---
IMAGE_NAME="alpine-dev-test"
CONTAINER_NAME="alpine-temp-shell"

# Verificar si el agente SSH está disponible (necesario para la YubiKey)
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "🚨 ADVERTENCIA: La variable \$SSH_AUTH_SOCK no está configurada."
    echo "  Si planeas usar Git a través de SSH (con o sin YubiKey), inicia el agente SSH primero."
    echo "  Ejemplo: eval \$(ssh-agent -s) && ssh-add ~/.ssh/id_ed25519_sk"
fi

# --- 1. CONSTRUIR LA IMAGEN (solo si no existe o hay actualizaciones) ---
# Primero, verificar si hay actualizaciones de la imagen base Alpine
echo "🔍 Verificando actualizaciones de Alpine..."
ALPINE_BEFORE=$(docker images -q alpine:latest)
docker pull alpine:latest --quiet
ALPINE_AFTER=$(docker images -q alpine:latest)

# Determinar si necesitamos reconstruir
NEEDS_REBUILD=false

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "⚙️ Imagen no encontrada. Construyendo la imagen Docker: $IMAGE_NAME"
    NEEDS_REBUILD=true
elif [ "$ALPINE_BEFORE" != "$ALPINE_AFTER" ]; then
    echo "🆕 Nueva versión de Alpine detectada. Reconstruyendo imagen..."
    NEEDS_REBUILD=true
else
    echo "✅ Imagen $IMAGE_NAME ya existe y está actualizada. Saltando construcción."
    echo "   (Para reconstruir manualmente, ejecuta: docker rmi $IMAGE_NAME)"
fi

# Construir si es necesario
if [ "$NEEDS_REBUILD" = true ]; then
    docker build -t "$IMAGE_NAME" .

    if [ $? -ne 0 ]; then
        echo "❌ Error al construir la imagen. Abortando."
        exit 1
    fi
fi

# --- 2. EJECUTAR EL CONTENEDOR TEMPORAL E INTERACTIVO ---
echo "🚀 Ejecutando el contenedor temporal e interactivo. Escribe 'exit' para salir y eliminarlo."

# Define los comandos de inicio: Clonar dotfiles y luego iniciar Bash
INIT_COMMANDS="
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

    # 3. Iniciar la shell interactiva en el directorio home
    cd ~ && /bin/zsh
"

docker run \
    --rm \
    -it \
    --name "$CONTAINER_NAME" \
    -v "$(pwd)":/app \
    -v "$SSH_AUTH_SOCK":"$SSH_AUTH_SOCK" \
    -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
    "$IMAGE_NAME" \
    /bin/bash -c "$INIT_COMMANDS" # Ejecuta los comandos definidos arriba
    
echo "✅ Contenedor temporal finalizado y eliminado."
