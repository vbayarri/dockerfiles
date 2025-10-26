# Usa la última versión oficial de Alpine Linux
FROM alpine:latest

# Instala Bash, Curl, Git y Zsh
# Estos paquetes son esenciales para tareas de desarrollo y clonación
RUN apk update && \
    apk add --no-cache bash curl git openssh-client zsh wget unzip && \
    rm -rf /var/cache/apk/*

# Instalar fzf (fuzzy finder)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /usr/local/fzf && \
    /usr/local/fzf/install --bin && \
    ln -s /usr/local/fzf/bin/fzf /usr/local/bin/fzf

# Instalar zoxide (smarter cd command)
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && \
    mv /root/.local/bin/zoxide /usr/local/bin/

# Instalar oh-my-posh (prompt theme engine)
RUN wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh && \
    chmod +x /usr/local/bin/oh-my-posh

# Define el directorio de trabajo dentro del contenedor
WORKDIR /app

# El CMD por defecto simplemente entra al shell de Bash si el contenedor se inicia sin argumentos
CMD ["/bin/bash"]