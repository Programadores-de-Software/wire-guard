# Cliente Linux

Instrucciones para conectar un equipo Linux al servidor VPN WireGuard.

## 1. Instalar WireGuard

**Debian/Ubuntu:**
```bash
sudo apt update && sudo apt install -y wireguard wireguard-tools
```

**Fedora/RHEL:**
```bash
sudo dnf install -y wireguard-tools
```

**Arch:**
```bash
sudo pacman -S wireguard-tools
```

## 2. Obtener el archivo de configuración

1. Abre un túnel SSH hacia el servidor:
   ```bash
   ssh -L 51821:127.0.0.1:51821 usuario@ip_del_servidor
   ```
2. Entra a http://127.0.0.1:51821, inicia sesión y crea un nuevo cliente ("New Client").
3. Descarga el archivo `.conf` generado (ej. `laptop-juan.conf`).

## 3. Instalar la configuración

```bash
sudo cp ~/Downloads/laptop-juan.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
```

## 4. Levantar el túnel

```bash
sudo wg-quick up wg0
```

Para verificar:
```bash
sudo wg show
curl ifconfig.me   # debe mostrar la IP pública del servidor VPN
```

Para bajar el túnel:
```bash
sudo wg-quick down wg0
```

## 5. Conexión automática al iniciar el sistema (opcional)

```bash
sudo systemctl enable --now wg-quick@wg0
```

## Alternativa: NetworkManager (GUI)

Si prefieres usar la interfaz gráfica de tu distro:

```bash
sudo apt install -y network-manager-openvpn wireguard-tools
nmcli connection import type wireguard file /etc/wireguard/wg0.conf
nmcli connection up wg0
```

O desde la GUI: **Configuración → Red → VPN → "+" → Importar desde archivo...** y selecciona el `.conf` descargado.

## Troubleshooting

- `sudo wg show` — muestra el estado del túnel y si hay `latest handshake` reciente (confirma que la conexión funciona).
- `sudo journalctl -u wg-quick@wg0` — logs del servicio si falla el arranque automático.
- Verifica que el firewall local no bloquee tráfico UDP saliente hacia el puerto 51820 del servidor.
