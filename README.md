# Dockerfiles

Colección de configuraciones Docker y entornos de desarrollo containerizados.

## Proyectos

### [Ephemeral Shell](./ephimeral_shell)

Entorno de desarrollo efímero basado en Alpine Linux con persistencia inteligente de configuración.

**Características:**
- Contenedor temporal que se elimina al salir
- Persistencia de dotfiles y configuraciones usando volúmenes Docker
- Setup automático de dotfiles solo en la primera ejecución
- Verificación periódica de actualizaciones de Alpine (cada 7 días)
- Herramientas preinstaladas: zsh, oh-my-posh, fzf, zoxide
- Soporte para YubiKey SSH

**Uso rápido:**
```bash
cd ephimeral_shell
./run_temp_shell.sh
```

Ver [documentación completa](./ephimeral_shell/README.md) para más detalles.

## Estructura

```
dockerfiles/
├── ephimeral_shell/    # Entorno de desarrollo temporal con Alpine Linux
└── README.md          # Este archivo
```

## Requisitos Generales

- Docker instalado y en ejecución
- Bash para ejecutar los scripts

## Contribuir

Este es un repositorio personal de configuraciones Docker. Los proyectos están optimizados para uso personal pero pueden servir como referencia.
