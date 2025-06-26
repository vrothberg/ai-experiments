COMPOSE ?= podman compose

.PHONY: build
build:
	$(COMPOSE) build

.PHONY: run-mcp-atlassian
run-mcp-atlassian:
	$(COMPOSE) up -d mcp-atlassian

.PHONY: stop-mcp-atlassian
stop-mcp-atlassian:
	$(COMPOSE) down mcp-atlassian

.PHONY: run-goose
run-goose:
	$(COMPOSE) run --rm goose

.PHONY: run-goose-bash
run-goose-bash:
	$(COMPOSE) run --rm --entrypoint /usr/bin/bash goose

PACKAGE ?= podman
.PHONY: reverse-dependencies
recipe:
	$(COMPOSE) run --rm \
		--entrypoint /bin/sh goose \
		-c "/usr/local/bin/goose run --recipe recipes/recipe.yaml \
			--params package=$(PACKAGE)"

.PHONY: clean
clean:
	$(COMPOSE) down
	podman volume prune -f
