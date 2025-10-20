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

# --- 1. CONSTRUIR LA IMAGEN ---
echo "⚙️ Construyendo la imagen Docker: $IMAGE_NAME"
# La construcción utiliza el Dockerfile en el directorio actual
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen. Abortando."
    exit 1
fi

# --- 2. EJECUTAR EL CONTENEDOR TEMPORAL E INTERACTIVO ---
echo "🚀 Ejecutando el contenedor temporal e interactivo. Escribe 'exit' para salir y eliminarlo."

# Define los comandos de inicio: Clonar dotfiles y luego iniciar Bash
INIT_COMMANDS="
    # 1. Comando de clonación de dotfiles (Ajusta la URL de tu repositorio)
    # Usamos HTTPS si la clave SSH no se carga automáticamente, o SSH si usas la clave YubiKey.
    # Recomendación: Si usas YubiKey, usa SSH. Si no, usa HTTPS.
    git clone git@github.com:vbayarri/dotfiles.git ~/dotfiles

    # 2. Comando para inicializar tus dotfiles (ej. un script de setup)
    ~/dotfiles/scripts/install-dependencies.sh

    # 3. Iniciar la shell interactiva
    /bin/zsh
"

docker run \
    --rm \
    -it \
    --name "$CONTAINER_NAME" \
    -w /app \
    -v "$(pwd)":/app \
    -v "$SSH_AUTH_SOCK":"$SSH_AUTH_SOCK" \
    -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
    "$IMAGE_NAME" \
    /bin/bash -c "$INIT_COMMANDS" # Ejecuta los comandos definidos arriba
    
echo "✅ Contenedor temporal finalizado y eliminado."
