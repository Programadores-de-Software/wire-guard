# WireGuard VPN Server (wg-easy)

Servidor VPN WireGuard con panel de administración web ([wg-easy](https://github.com/wg-easy/wg-easy) v15), pensado para uso personal.

## Arquitectura

- **WireGuard** escucha en **UDP 51820**, expuesto a internet — es el puerto por el que se conectan los clientes VPN.
- El **panel web de administración** (puerto 51821) se publica **solo en `127.0.0.1`** del servidor — no es accesible desde internet. Para administrarlo, se usa un túnel SSH.

## Contenido

- [`docker-compose.yml`](./docker-compose.yml) — definición del servicio.
- [`docs/instalacion-servidor.md`](./docs/instalacion-servidor.md) — cómo instalar el servidor VPN desde cero en un host nuevo.
- [`docs/cliente-linux.md`](./docs/cliente-linux.md) — cómo instalar y conectar un cliente en Linux.
- [`docs/cliente-windows.md`](./docs/cliente-windows.md) — cómo instalar y conectar un cliente en Windows.
- [`docs/firewall.md`](./docs/firewall.md) — notas sobre firewall/UFW y el comportamiento de Docker con iptables.

## Quick start (servidor)

```bash
git clone git@github.com:Programadores-de-Software/wire-guard.git
cd wire-guard
docker compose up -d
```

Luego sigue la guía completa en [`docs/instalacion-servidor.md`](./docs/instalacion-servidor.md).

## Quick start (cliente)

1. Abre un túnel SSH al servidor: `ssh -L 51821:127.0.0.1:51821 usuario@ip_del_servidor`
2. Entra a http://127.0.0.1:51821 y crea un nuevo cliente.
3. Descarga el `.conf` o escanea el QR.
4. Sigue la guía según tu sistema: [Linux](./docs/cliente-linux.md) · [Windows](./docs/cliente-windows.md)

## Notas de seguridad

- El puerto 51820/UDP debe quedar abierto a internet (es el propósito del servidor).
- El puerto 51821 (panel) **nunca** debe exponerse públicamente; solo se accede vía túnel SSH.
- Ver [`docs/firewall.md`](./docs/firewall.md) para detalles sobre cómo Docker gestiona sus propias reglas de iptables (y por qué UFW por sí solo no controla los puertos publicados por contenedores).
