.EXPORT_ALL_VARIABLES:

SHELL := /bin/sh
ARG=
TARGET ?= ..
COMPOSE_DOCKER_CLI_BUILD=1
DOCKER_BUILDKIT=1
DEFAULT: help

help: ## Show this help
	@echo -e "usage: make [target]\n\ntarget:"
	@grep -F -h "##" $(MAKEFILE_LIST) | grep -F -v grep -F | sed -e 's/\\$$//' | sed -e 's/: ##\s*/\t/' | expand -t 30 | pr -to2

# Container Management Commands
up: ## Iniciar todos os serviços
	docker compose -p weather up -d --remove-orphans

down: ## Parar todos os serviços
	docker compose -p weather down

logs: ## Visualizar logs de todos os serviços
	docker compose -p weather logs -f $(ARG)

ps: ## Listar status dos containers
	docker compose -p weather ps

prune: ## Limpar recursos não utilizados (containers, networks, volumes)
	docker system prune -f

ifndef VERBOSE
.SILENT:
endif

.PHONY: help up down logs ps prune