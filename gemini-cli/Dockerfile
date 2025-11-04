# Usa Node.js 24 LTS (Slim) - Soporte hasta abril 2028
FROM node:24-slim

# Instalar dependencias adicionales útiles
# git: Para control de versiones de conversaciones
# curl: Para llamadas a APIs
RUN apt-get update && \
    apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*

# Define el directorio de trabajo dentro del contenedor
WORKDIR /workspace

# El CMD por defecto simplemente entra al shell de Bash si el contenedor se inicia sin argumentos
CMD ["/bin/bash"]
