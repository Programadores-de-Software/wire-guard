# Firewall: UFW + Docker

Notas importantes sobre cómo interactúan Docker y UFW en el servidor, basadas en la instalación real de este proyecto.

## El problema

Docker **no respeta las reglas de UFW** para los puertos publicados con `ports:` (o `-p` en `docker run`). Cuando el daemon de Docker publica un puerto, inserta sus propias reglas directamente en `iptables` (cadenas `DOCKER`, `DOCKER-FORWARD`, `FORWARD`), que se evalúan **antes** que las reglas de UFW.

Esto significa:

- Un puerto publicado por Docker (ej. `51820:51820/udp`) queda accesible desde internet **aunque `ufw status` no lo liste explícitamente**.
- Ejecutar `sudo ufw deny 51820/udp` **no bloquea** el tráfico hacia ese puerto si Docker ya lo publicó, porque el paquete nunca llega a evaluarse contra las reglas de UFW (la cadena `DOCKER`/`FORWARD` ya lo aceptó antes).

## Cómo queda configurado en este proyecto

En [`docker-compose.yml`](../docker-compose.yml):

```yaml
ports:
  - "51820:51820/udp"            # publicado en 0.0.0.0 -> accesible desde internet
  - "127.0.0.1:51821:51821/tcp"  # publicado SOLO en loopback -> no accesible desde fuera
```

Verificación hecha en producción:

```bash
# Regla DNAT generada automáticamente por Docker para el panel:
iptables -t nat -L DOCKER -n -v | grep 51821
# DNAT tcp -- !br-xxx *  0.0.0.0/0  127.0.0.1  tcp dpt:51821 to:10.42.42.42:51821
```

Nota el `-d 127.0.0.1` en la regla: **solo** coincide si el paquete llegó dirigido a `127.0.0.1` (es decir, tráfico local o mediante un túnel SSH con `-L`). Los paquetes que llegan desde internet a la IP pública del servidor **no** coinciden con esa regla, y terminan cayendo en la política por defecto de UFW (`DROP` en `INPUT`), quedando efectivamente bloqueados.

Para el puerto 51820/udp, al no tener el bind a `127.0.0.1`, la regla DNAT no filtra por IP de destino, así que cualquier origen puede alcanzarlo — que es justo el comportamiento deseado para el servidor VPN.

## Qué hacer si necesitas que UFW controle también los puertos de Docker

Si en el futuro necesitas reglas más finas controladas por UFW sobre puertos publicados por Docker (ej. restringir 51820 a un rango de IPs), hay dos opciones:

1. **No publicar el puerto a `0.0.0.0`** y en su lugar bindear a una IP específica o usar `network_mode: host` combinado con reglas manuales de iptables.
2. Usar el script de terceros [`ufw-docker`](https://github.com/chaifeng/ufw-docker), que inserta reglas en la cadena `DOCKER-USER` (que sí se evalúa antes de que Docker acepte el tráfico) permitiendo que UFW controle el acceso.

## Resumen de verificación

Comandos usados para confirmar el comportamiento (ejecutar en el servidor):

```bash
# Ver reglas de UFW (no listará 51820, y aun así funciona):
sudo ufw status verbose

# Ver que Docker publicó su propia regla de forward/DNAT:
sudo iptables -L DOCKER -n -v | grep 51820
sudo iptables -t nat -L DOCKER -n -v | grep -E "51820|51821"

# Confirmar que el panel NO responde desde la IP pública/LAN:
curl -m 3 -o /dev/null -w "HTTP:%{http_code}\n" http://<IP_DEL_SERVIDOR>:51821/
# Debe devolver HTTP:000 (sin respuesta) — correcto, está bloqueado.

# Confirmar que el panel SÍ responde en loopback:
curl -o /dev/null -w "HTTP:%{http_code}\n" http://127.0.0.1:51821/
# Debe devolver un código HTTP válido (ej. 302).
```
