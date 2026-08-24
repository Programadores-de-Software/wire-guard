# ============================================================
# Makefile - WireGuard (wg-easy)
# ============================================================
# Variables configurables por linea de comandos o via .env
#   make tunnel SSH_HOST=1.2.3.4
#   make client-create NAME=laptop-juan
# ============================================================

-include .env
export

COMPOSE      ?= docker compose

# --- Tunel SSH (para acceder al panel web desde tu maquina local) ---
SSH_USER     ?= root
SSH_HOST     ?=
SSH_PORT     ?= 22
LOCAL_PORT   ?= 51821
REMOTE_PORT  ?= 51821

# --- API del panel (WG_API se usa desde el propio servidor, por eso 127.0.0.1) ---
WG_API       ?= http://127.0.0.1:51821
WG_USER      ?=
WG_PASSWORD  ?=

.DEFAULT_GOAL := help

.PHONY: help up down restart logs ps \
        tunnel \
        client-create client-list client-config client-qr client-delete \
        admin-reset-password

help: ## Muestra esta ayuda
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ----------------------------------------------------------------
# Servidor / contenedor
# ----------------------------------------------------------------

up: ## Levanta el contenedor wg-easy (docker compose up -d)
	$(COMPOSE) up -d

down: ## Detiene y elimina el contenedor
	$(COMPOSE) down

restart: ## Reinicia el contenedor (down + up)
	$(COMPOSE) down
	$(COMPOSE) up -d

logs: ## Muestra los logs en vivo
	$(COMPOSE) logs -f

ps: ## Muestra el estado del contenedor
	$(COMPOSE) ps

# ----------------------------------------------------------------
# Tunel SSH rapido (ejecutar desde tu laptop, no desde el servidor)
# ----------------------------------------------------------------

tunnel: ## Abre tunel SSH al panel: make tunnel SSH_HOST=ip [SSH_USER=root] [SSH_PORT=22] [LOCAL_PORT=51821]
	@if [ -z "$(SSH_HOST)" ]; then \
		echo "Error: define SSH_HOST. Ejemplo: make tunnel SSH_HOST=203.0.113.10"; \
		exit 1; \
	fi
	@echo "Panel disponible en http://127.0.0.1:$(LOCAL_PORT) mientras este tunel este abierto (Ctrl+C para cerrar)"
	ssh -N -L $(LOCAL_PORT):127.0.0.1:$(REMOTE_PORT) -p $(SSH_PORT) $(SSH_USER)@$(SSH_HOST)

# ----------------------------------------------------------------
# Gestion de clientes (ejecutar en el SERVIDOR, donde vive este repo)
# ----------------------------------------------------------------
# client-create / client-config / client-delete usan la API HTTP de wg-easy
# y requieren las credenciales del panel (WG_USER / WG_PASSWORD), definidas
# como variables de entorno o en un archivo .env (ver .env.example).
# IMPORTANTE: la API no funciona si el usuario admin tiene 2FA activado.

client-create: ## Crea un cliente nuevo y descarga su .conf: make client-create NAME=laptop-juan
	@if [ -z "$(NAME)" ]; then echo "Uso: make client-create NAME=<nombre>"; exit 1; fi
	@if [ -z "$(WG_USER)" ] || [ -z "$(WG_PASSWORD)" ]; then \
		echo "Error: define WG_USER y WG_PASSWORD (env vars o archivo .env)"; exit 1; \
	fi
	@echo "Creando cliente '$(NAME)'..."
	@RESPONSE=$$(curl -sf -u "$(WG_USER):$(WG_PASSWORD)" \
		-H "Content-Type: application/json" \
		-d '{"name":"$(NAME)"}' \
		"$(WG_API)/api/client"); \
	if [ -z "$$RESPONSE" ]; then echo "Error: sin respuesta de la API"; exit 1; fi; \
	CLIENT_ID=$$(echo "$$RESPONSE" | grep -o '"clientId":"[^"]*"' | cut -d'"' -f4); \
	if [ -z "$$CLIENT_ID" ]; then echo "Error creando cliente. Respuesta: $$RESPONSE"; exit 1; fi; \
	curl -sf -u "$(WG_USER):$(WG_PASSWORD)" -o "$(NAME).conf" "$(WG_API)/api/client/$$CLIENT_ID/configuration"; \
	echo "OK -> clientId: $$CLIENT_ID"; \
	echo "OK -> config guardada en ./$(NAME).conf"

client-list: ## Lista los clientes existentes (via CLI del contenedor)
	$(COMPOSE) exec -T wg-easy cli clients:list

client-qr: ## Muestra el QR de un cliente en la terminal: make client-qr ID=<client_id>
	@if [ -z "$(ID)" ]; then echo "Uso: make client-qr ID=<client_id>"; exit 1; fi
	$(COMPOSE) exec -T wg-easy cli clients:qr $(ID)

client-config: ## Descarga (o re-descarga) el .conf de un cliente: make client-config ID=<client_id> NAME=<archivo>
	@if [ -z "$(ID)" ] || [ -z "$(NAME)" ]; then echo "Uso: make client-config ID=<client_id> NAME=<archivo_salida>"; exit 1; fi
	@if [ -z "$(WG_USER)" ] || [ -z "$(WG_PASSWORD)" ]; then \
		echo "Error: define WG_USER y WG_PASSWORD (env vars o archivo .env)"; exit 1; \
	fi
	curl -sf -u "$(WG_USER):$(WG_PASSWORD)" -o "$(NAME).conf" "$(WG_API)/api/client/$(ID)/configuration"
	@echo "Guardado en ./$(NAME).conf"

client-delete: ## Elimina un cliente: make client-delete ID=<client_id>
	@if [ -z "$(ID)" ]; then echo "Uso: make client-delete ID=<client_id>"; exit 1; fi
	@if [ -z "$(WG_USER)" ] || [ -z "$(WG_PASSWORD)" ]; then \
		echo "Error: define WG_USER y WG_PASSWORD (env vars o archivo .env)"; exit 1; \
	fi
	curl -sf -u "$(WG_USER):$(WG_PASSWORD)" -X DELETE "$(WG_API)/api/client/$(ID)"
	@echo "Cliente $(ID) eliminado"

# ----------------------------------------------------------------
# Administracion
# ----------------------------------------------------------------

admin-reset-password: ## Resetea la contraseña del admin del panel (interactivo)
	$(COMPOSE) exec -it wg-easy cli db:admin:reset
