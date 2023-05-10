
GO_DIRS := $(shell go list ./... |sed -e 1d -e s,github.com/ncabatoff/dbms_exporter/,,)
GO_SRC := dbms_exporter.go $(shell find ${GO_DIRS} -name '*.go')

CONTAINER_NAME = ncabatoff/dbms_exporter:latest
FREETDS_VERSION = 1.1.5
BUILD_CONTAINER_NAME = ncabatoff/dbms_exporter_builder:${FREETDS_VERSION}
TAG_VERSION ?= $(shell git describe --tags --abbrev=0)

# Possible BUILDTAGS settings are postgres, freetds, and odbc.
DRIVERS = freetds
# Use make LDFLAGS= if you want to build with tag ODBC.
LDFLAGS = -extldflags=-static

all: vet test dbms_exporter

# Simple go build
dbms_exporter: $(GO_SRC)
	go build -ldflags '$(LDFLAGS) -X main.Version=$(TAG_VERSION)' -o dbms_exporter -tags '$(DRIVERS)' .

docker: Dockerfile $(GO_SRC)
	docker build --build-arg drivers="$(DRIVERS)" --build-arg ldflags="$(LDFLAGS)" -t $(CONTAINER_NAME) .

vet:
	go vet . ./config ./common ./db ./recipes

test:
	go test -v . ./config ./common ./db ./recipes

test-integration:
	tests/test-smoke

docker-build-pre: Dockerfile-buildexporter
	docker build --build-arg FREETDS_VERSION=${FREETDS_VERSION} -f Dockerfile-buildexporter -t $(BUILD_CONTAINER_NAME) .

# Do a self-contained build of dbms_exporter using Docker.
build-with-docker: $(GO_SRC) docker-build-pre Dockerfile
	rm -f dbms_exporter
	docker run --rm -v $(shell pwd):/work \
	    -w /work \
	    $(BUILD_CONTAINER_NAME) \
	    make DRIVERS="$(DRIVERS)" LDFLAGS="$(LDFLAGS)"

.PHONY: docker-build docker test vet


SYBASE_USER=
SYBASE_PASSWD=
SYBASE_SERVER=

build: build-with-docker docker
largetest:
	@echo Point your browser at http://localhost:9113/metrics
	docker run --rm -ti -e DATA_SOURCE_NAME='compatibility_mode=sybase;user=$(SYBASE_USER);pwd=$(SYBASE_PASSWD);server=$(SYBASE_SERVER)' -p 9113:9113 -v`pwd`:/etc ncabatoff/dbms_exporter -queryfile /etc/sybase.yaml -driver sybase

shell:
	docker run --rm -ti -e DATA_SOURCE_NAME='compatibility_mode=sybase;user=$(SYBASE_USER);pwd=$(SYBASE_PASSWD);server=$(SYBASE_SERVER)' -v`pwd`:/etc --entrypoint /bin/bash ncabatoff/dbms_exporter 

	
