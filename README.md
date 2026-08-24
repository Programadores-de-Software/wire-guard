# WireGuard VPN Server (wg-easy)

Servidor VPN WireGuard con panel de administración web ([wg-easy](https://github.com/wg-easy/wg-easy) v15), pensado para uso personal.

## Arquitectura

- **WireGuard** escucha en **UDP 51820**, expuesto a internet — es el puerto por el que se conectan los clientes VPN.
- El **panel web de administración** (puerto 51821) se publica **solo en `127.0.0.1`** del servidor — no es accesible desde internet. Para administrarlo, se usa un túnel SSH.

## Contenido

- [`docker-compose.yml`](./docker-compose.yml) — definición del servicio.
- [`Makefile`](./Makefile) — atajos para levantar el servidor, abrir el túnel SSH y gestionar clientes.
- [`docs/instalacion-servidor.md`](./docs/instalacion-servidor.md) — cómo instalar el servidor VPN desde cero en un host nuevo.
- [`docs/cliente-linux.md`](./docs/cliente-linux.md) — cómo instalar y conectar un cliente en Linux.
- [`docs/cliente-windows.md`](./docs/cliente-windows.md) — cómo instalar y conectar un cliente en Windows.
- [`docs/firewall.md`](./docs/firewall.md) — notas sobre firewall/UFW y el comportamiento de Docker con iptables.

## Quick start (servidor)

```bash
git clone git@github.com:Programadores-de-Software/wire-guard.git
cd wire-guard
make up
```

Luego sigue la guía completa en [`docs/instalacion-servidor.md`](./docs/instalacion-servidor.md).

## Quick start (cliente)

1. Desde tu laptop, abre el túnel SSH con Make:
   ```bash
   make tunnel SSH_HOST=ip_del_servidor
   ```
2. Entra a http://127.0.0.1:51821 y crea un nuevo cliente (o usa `make client-create`, ver abajo).
3. Descarga el `.conf` o escanea el QR.
4. Sigue la guía según tu sistema: [Linux](./docs/cliente-linux.md) · [Windows](./docs/cliente-windows.md)

## Uso del Makefile

Ejecuta `make help` para ver todos los comandos disponibles.

```bash
make help
```

| Comando | Dónde se ejecuta | Descripción |
|---|---|---|
| `make up` / `make down` / `make restart` | Servidor | Levanta / detiene / reinicia el contenedor |
| `make logs` / `make ps` | Servidor | Logs y estado del contenedor |
| `make tunnel SSH_HOST=ip` | Laptop/local | Abre el túnel SSH al panel (`127.0.0.1:51821`) |
| `make client-create NAME=laptop-juan` | Servidor | Crea un cliente vía API y descarga `laptop-juan.conf` |
| `make client-list` | Servidor | Lista los clientes existentes |
| `make client-qr ID=<client_id>` | Servidor | Muestra el QR del cliente en la terminal |
| `make client-config ID=<id> NAME=<archivo>` | Servidor | Vuelve a descargar el `.conf` de un cliente existente |
| `make client-delete ID=<client_id>` | Servidor | Elimina un cliente |
| `make admin-reset-password` | Servidor | Resetea la contraseña del panel |

### Configurar credenciales (una sola vez)

Los comandos `client-create` / `client-config` / `client-delete` usan la **API HTTP de wg-easy** y necesitan las credenciales del panel. Copia `.env.example` a `.env` (ya está en `.gitignore`, nunca se sube) y completa:

```bash
cp .env.example .env
# editar .env: WG_USER, WG_PASSWORD (y SSH_HOST si quieres guardar el valor para `make tunnel`)
```

> ⚠️ La API no funciona si el usuario admin tiene **2FA** activado en el panel.

### Ejemplo rápido: crear un cliente y traer su config

```bash
# En el servidor, con .env ya configurado:
make client-create NAME=laptop-juan
# -> genera ./laptop-juan.conf, listo para copiar a la laptop
```

## Notas de seguridad

- El puerto 51820/UDP debe quedar abierto a internet (es el propósito del servidor).
- El puerto 51821 (panel) **nunca** debe exponerse públicamente; solo se accede vía túnel SSH.
- Ver [`docs/firewall.md`](./docs/firewall.md) para detalles sobre cómo Docker gestiona sus propias reglas de iptables (y por qué UFW por sí solo no controla los puertos publicados por contenedores).
