.EXPORT_ALL_VARIABLES:

SHELL := /bin/sh
ARG=
TARGET ?= ..
COMPOSE_PROJECT_NAME=weather
COMPOSE_DOCKER_CLI_BUILD=1
DOCKER_BUILDKIT=1
DOCKER_COMPOSE=docker compose -p nobe
DEFAULT: help

help: ## Show this help
	@echo -e "usage: make [target]\n\ntarget:"
	@grep -F -h "##" $(MAKEFILE_LIST) | grep -F -v grep -F | sed -e 's/\\$$//' | sed -e 's/: ##\s*/\t/' | expand -t 30 | pr -to2

# Container Management Commands
up: ## Iniciar todos os serviços
	$(DOCKER_COMPOSE) up -d --remove-orphans

down: ## Parar todos os serviços
	$(DOCKER_COMPOSE) down

logs: ## Visualizar logs de todos os serviços
	$(DOCKER_COMPOSE) logs -f $(ARG)

ps: ## Listar status dos containers
	$(DOCKER_COMPOSE) ps

prune: ## Limpar recursos não utilizados (containers, networks, volumes)
	docker system prune -f

ifndef VERBOSE
.SILENT:
endif

.PHONY: help up down logs ps prune