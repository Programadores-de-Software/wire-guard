# Instalación del servidor (wg-easy)

Guía para instalar el servidor VPN WireGuard con panel wg-easy en un host nuevo (Ubuntu/Debian como referencia).

## Requisitos

- Host con IP pública (o dominio apuntando a él).
- Arquitectura x86_64 o arm64.
- Acceso root/sudo.
- Puerto UDP 51820 disponible para exponer a internet.

## 1. Instalar Docker

Si Docker no está instalado:

```bash
curl -sSL https://get.docker.com | sh
```

Verifica:

```bash
docker --version
docker compose version
```

## 2. Clonar este repositorio en el servidor

```bash
git clone git@github.com:Programadores-de-Software/wire-guard.git
cd wire-guard
```

## 3. Levantar el contenedor

```bash
docker compose up -d
```

Esto:

- Descarga la imagen `ghcr.io/wg-easy/wg-easy:15`.
- Crea la interfaz WireGuard `wg0` dentro del contenedor.
- Publica:
  - `51820/udp` en todas las interfaces (para los clientes VPN).
  - `51821/tcp` **solo en `127.0.0.1`** (panel web, protegido).

Verifica que esté corriendo:

```bash
docker compose ps
docker compose logs -f
```

## 4. Acceder al panel de administración

El panel **no** está expuesto a internet. Para acceder, crea un túnel SSH desde tu máquina local:

```bash
ssh -L 51821:127.0.0.1:51821 usuario@ip_del_servidor
```

Abre en tu navegador: **http://127.0.0.1:51821**

## 5. Asistente de configuración inicial

La primera vez que entras al panel, wg-easy te pedirá:

1. **Usuario y contraseña** — credenciales del panel de administración.
2. **¿Setup existente?** → elige **"No"** si es la primera instalación.
3. **Host** — la IP pública o dominio que usarán los clientes para conectarse.
4. **Puerto** — `51820` (el publicado en el `docker-compose.yml`).

## 6. Crear clientes

Desde el panel, botón **"New Client"** → se genera un archivo `.conf` y un código QR descargables. Usa estos archivos según la guía de cliente correspondiente:

- [Cliente Linux](./cliente-linux.md)
- [Cliente Windows](./cliente-windows.md)

## 7. Firewall

Revisa [`firewall.md`](./firewall.md) — importante entender que Docker gestiona sus propias reglas de iptables, por lo que el puerto 51820/udp queda expuesto automáticamente al publicar el contenedor, sin importar la configuración de UFW.

Asegúrate de que tu proveedor cloud (Security Groups / firewall externo, si aplica) permita tráfico entrante en **UDP 51820**.

## 8. Actualizar wg-easy

```bash
cd wire-guard
docker compose pull
docker compose up -d
```

> Importante: usa siempre `docker compose up/down`, nunca `start/stop`, para evitar estados inconsistentes.
