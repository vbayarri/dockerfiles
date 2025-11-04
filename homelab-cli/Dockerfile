# Imagen Alpine minimalista con Terraform
FROM alpine:latest

# Versión de Terraform (actualiza según necesites)
ARG TERRAFORM_VERSION=1.10.3

# Instala dependencias mínimas y Terraform
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod +x /usr/local/bin/terraform \
    && rm -rf /var/cache/apk/*

# Define el directorio de trabajo dentro del contenedor
WORKDIR /workspace

# El CMD por defecto simplemente entra al shell de Bash
CMD ["/bin/bash"]
