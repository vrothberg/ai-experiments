.PHONY: build-container
build-container:
	goose recipe validate ./build-container.yaml
	GOOSE_MODE="auto" goose run --recipe ./build-container.yaml --params package=vim --params name=foo.com/hello:recipe

PACKAGE ?= podman
.PHONY: update-centos-package
update-centos-package:
	goose recipe validate ./update-centos-package.yaml
	GOOSE_MODE="auto" goose run --recipe ./update-centos-package.yaml --params package=$(PACKAGE)


PACKAGE ?= podman
.PHONY: reverse-dependencies
reverse-dependencies:
	goose recipe validate ./reverse-dependencies.yaml
	GOOSE_MODE="auto" goose run --recipe ./reverse-dependencies.yaml --params package=$(PACKAGE)
