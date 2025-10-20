# Usa la última versión oficial de Alpine Linux
FROM alpine:latest

# Instala Bash, Curl y **Git**
# Estos paquetes son esenciales para tareas de desarrollo y clonación
RUN apk update && \
    apk add --no-cache bash curl git openssh-client && \
    rm -rf /var/cache/apk/*

# Define el directorio de trabajo dentro del contenedor
WORKDIR /app

# El CMD por defecto simplemente entra al shell de Bash si el contenedor se inicia sin argumentos
CMD ["/bin/bash"]