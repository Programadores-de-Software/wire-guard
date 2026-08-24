# Cliente Windows

Instrucciones para conectar un equipo Windows al servidor VPN WireGuard.

## 1. Instalar WireGuard

1. Descarga el instalador oficial desde: https://www.wireguard.com/install/
2. Ejecuta el instalador y sigue el asistente (instalación estándar, "Next" en todas las pantallas).

## 2. Obtener el archivo de configuración

Necesitas acceso al panel de administración (wg-easy), que solo está disponible vía túnel SSH.

### Opción A: Túnel SSH con OpenSSH (Windows 10/11 ya lo trae)

Abre **PowerShell** o **Símbolo del sistema**:

```powershell
ssh -L 51821:127.0.0.1:51821 usuario@ip_del_servidor
```

Deja esa ventana abierta y abre en el navegador: **http://127.0.0.1:51821**

### Opción B: PuTTY

Si usas PuTTY, configura un túnel local:
- **Host**: `ip_del_servidor`
- **Connection → SSH → Tunnels**:
  - Source port: `51821`
  - Destination: `127.0.0.1:51821`
  - Tipo: `Local`
  - Click en **Add**, luego **Open** para conectar.

Luego abre en el navegador: **http://127.0.0.1:51821**

## 3. Crear el cliente en el panel

1. Inicia sesión en el panel.
2. Click en **"New Client"**.
3. Descarga el archivo `.conf` (ej. `laptop-windows.conf`) o usa el código QR si vas a configurar un móvil.

## 4. Importar la configuración en WireGuard

1. Abre la app **WireGuard** (instalada en el paso 1).
2. Click en **"Import tunnel(s) from file"**.
3. Selecciona el archivo `.conf` descargado.
4. Click en **"Activate"** para conectar el túnel.

## 5. Verificar la conexión

Con el túnel activo en la app WireGuard, deberías ver tráfico (Rx/Tx) incrementando. Para confirmar la IP pública:

- Abre un navegador y visita: https://ifconfig.me — debe mostrar la IP pública del servidor VPN.

## 6. Conexión automática al iniciar Windows (opcional)

En la app de WireGuard:
1. Abre el túnel importado.
2. Marca la casilla **"On-demand activation"** o usa **Instalar como servicio** desde el menú de administración del túnel (requiere permisos de administrador) para que se conecte automáticamente al iniciar sesión.

## Troubleshooting

- Si la conexión no muestra "Latest handshake", revisa que el puerto 51820/UDP esté realmente abierto en el servidor (ver [`firewall.md`](./firewall.md)).
- Verifica que no haya otro cliente VPN activo (ej. otra VPN corporativa) interfiriendo con las rutas.
- Revisa el firewall de Windows: la app de WireGuard suele crear sus propias reglas automáticamente, pero en entornos corporativos puede requerir aprobación manual.
