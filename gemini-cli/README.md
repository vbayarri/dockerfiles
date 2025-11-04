# Gemini CLI - Entorno de Desarrollo con Google Gemini AI

Entorno de desarrollo containerizado para usar [Gemini CLI](https://github.com/google-gemini/gemini-cli) de Google con Node.js 24 LTS y persistencia de autenticación.

## Características

- **Contenedor efímero**: Se elimina automáticamente al salir (con `--rm`)
- **Persistencia de autenticación**: Los tokens de Google OAuth persisten entre sesiones
- **Node.js 24 LTS**: Versión más reciente con soporte hasta abril 2028
- **Optimización de imagen**: No reconstruye si ya existe
- **Verificación periódica**: Revisa actualizaciones de Node.js cada 7 días
- **Entorno aislado**: No interfiere con tu instalación local de Node.js

## Funcionamiento

### 1. Construcción de Imagen

- **Primera ejecución**: Construye la imagen `gemini-cli-dev` basada en `node:24-slim`
- **Ejecuciones posteriores**: Reutiliza la imagen existente
- **Actualizaciones automáticas**: Cada 7 días verifica si hay nueva versión de Node.js

### 2. Autenticación con Google

- **Primera ejecución**: Muestra instrucciones para autenticarse
- **Ejecuciones posteriores**: Reutiliza los tokens OAuth guardados
- Los tokens se almacenan en el volumen persistente `gemini-cli-home`

### 3. Persistencia de Datos

- **Volumen Docker**: `gemini-cli-home` montado en `/root`
- **Persiste**: Tokens OAuth, configuración, historial de conversaciones
- **No persiste**: Binarios del sistema (están en la imagen Docker)

### 4. Herramientas Incluidas

Instaladas en el Dockerfile:
- **Node.js 24 LTS**: Runtime de JavaScript
- **npm/npx**: Gestor de paquetes de Node.js
- **git**: Control de versiones
- **curl**: Cliente HTTP para APIs

## Requisitos

- Docker instalado y en ejecución
- Cuenta de Google para autenticación

## Uso

### Inicio Rápido

```bash
cd gemini-cli
./run_gemini.sh
```

### Primera Ejecución - Autenticación

```bash
# Dentro del contenedor, ejecuta:
npx @google/generative-ai-cli auth

# Sigue las instrucciones para autenticarte con tu cuenta de Google
# El navegador se abrirá o te dará un código para copiar
```

### Usar Gemini CLI

```bash
# Iniciar chat interactivo
npx @google/generative-ai-cli chat

# Hacer una pregunta directa
npx @google/generative-ai-cli ask "¿Cuál es la capital de Francia?"

# Ver ayuda
npx @google/generative-ai-cli --help
```

### Ejemplos de Uso

#### Chat Interactivo
```bash
$ npx @google/generative-ai-cli chat
> Hola, ¿cómo estás?
[Gemini responde...]
> Explícame qué es Docker
[Gemini responde...]
> exit
```

#### Pregunta Directa
```bash
$ npx @google/generative-ai-cli ask "Escribe una función en Python para calcular fibonacci"
```

#### Trabajar con Archivos
```bash
# Los archivos en tu directorio actual están disponibles en /workspace
$ ls /workspace
# Puedes usar Gemini para analizar código, documentos, etc.
```

## Configuración

Edita las variables al inicio de `run_gemini.sh`:

```bash
IMAGE_NAME="gemini-cli-dev"              # Nombre de la imagen Docker
CONTAINER_NAME="gemini-cli-temp"         # Nombre del contenedor
VOLUME_NAME="gemini-cli-home"            # Nombre del volumen persistente
UPDATE_CHECK_INTERVAL_DAYS=7             # Días entre verificaciones de actualización
```

## Comandos Útiles

### Forzar Reconstrucción de Imagen

```bash
docker rmi gemini-cli-dev
./run_gemini.sh
```

### Resetear Autenticación y Configuración

```bash
docker volume rm gemini-cli-home
./run_gemini.sh
```

### Forzar Verificación de Actualizaciones

```bash
rm ~/.cache/gemini-cli-last-check
./run_gemini.sh
```

### Ver Información del Volumen

```bash
docker volume inspect gemini-cli-home
```

## Estructura del Proyecto

```
.
├── Dockerfile         # Definición de la imagen con Node.js 24 LTS
├── run_gemini.sh      # Script principal de ejecución
└── README.md          # Esta documentación
```

## Optimizaciones Implementadas

1. **Cache de imagen Docker**: No reconstruye si la imagen ya existe
2. **Verificación periódica**: Solo verifica actualizaciones cada 7 días
3. **Persistencia de autenticación**: OAuth tokens se guardan entre sesiones
4. **Volumen persistente**: Configuración y datos persisten
5. **Node.js 24 LTS**: Última versión con soporte extendido (hasta 2028)

## Autenticación y Seguridad

### ¿Cómo funciona la autenticación?

1. Gemini CLI usa OAuth 2.0 Device Flow
2. Se abre tu navegador o te da un código para copiar
3. Autorizas la aplicación en tu cuenta de Google
4. Los tokens se guardan localmente en el volumen Docker
5. Las sesiones posteriores reutilizan estos tokens

### Seguridad

- ✅ Los tokens OAuth están en un volumen Docker local (no en la imagen)
- ✅ El contenedor es efímero, solo persisten los datos del volumen
- ✅ Puedes eliminar el volumen en cualquier momento para revocar acceso
- ⚠️ No compartas el volumen Docker con otros usuarios

## Diferencias con Instalación Global

| Aspecto | Este Proyecto | Instalación Global |
|---------|---------------|-------------------|
| Node.js | Aislado en contenedor | Usa tu Node.js local |
| Persistencia | Volumen Docker | `~/.config` en tu home |
| Actualización | Automática cada 7 días | Manual con `npm update` |
| Aislamiento | Total | Comparte con otros proyectos |
| Portabilidad | Alta (funciona igual en cualquier máquina con Docker) | Depende del sistema |

## Solución de Problemas

### Error de autenticación

```bash
# Elimina el volumen y vuelve a autenticarte
docker volume rm gemini-cli-home
./run_gemini.sh
```

### Error "command not found: npx"

Esto no debería ocurrir con node:24-slim, pero si pasa:
```bash
# Dentro del contenedor
node --version  # Verifica que Node.js está instalado
npm --version   # Verifica que npm está instalado
```

### El contenedor no inicia

```bash
# Verifica que Docker está corriendo
docker ps

# Reconstruye la imagen
docker rmi gemini-cli-dev
./run_gemini.sh
```

## Referencias

- [Gemini CLI GitHub](https://github.com/google-gemini/gemini-cli)
- [Node.js 24 Documentation](https://nodejs.org/)
- [Google AI Studio](https://aistudio.google.com/)

## Licencia

Proyecto personal de entorno de desarrollo.
