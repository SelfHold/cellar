.PHONY: all test race vet core-lib build-linux proto aar app-deps app-test app-run build-apk pg-test

# Every build output lands in builds/ at the repo root.
BIN := builds
SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
VERSION := 0.1.0
STAMP := $(shell date +%m%d.%H%M%S)
BUILD_ID := $(or $(DBM_BUILD_ID),$(SHA)-$(STAMP))
DEFINES := --dart-define=APP_VERSION=$(VERSION) --dart-define=BUILD_SHA=$(SHA) --dart-define=BUILD_ID=$(BUILD_ID)
GO_LDFLAGS = -X dbmanager/core/rpc.Version=$(VERSION) -X dbmanager/core/rpc.Build=$(BUILD_ID)
NDK ?= $(lastword $(sort $(wildcard $(HOME)/Android/Sdk/ndk/*)))
PROTOC_DART := $(HOME)/.pub-cache/bin/protoc-gen-dart

# Test runs are capped at 1 GB and run one at a time.
CAP := systemd-run --user --scope -p MemoryMax=1G -p MemorySwapMax=0 --quiet
GOTEST := $(CAP) env GOMAXPROCS=2 go test -p 1

all: vet test

# --- Go core -------------------------------------------------------------

# Unit tests. The PostgreSQL integration tests run only with DBM_PG_DSN
# (make pg-test).
test:
	$(GOTEST) ./core/...

race:
	$(CAP) go test -race -p 1 ./core/...

# Integration tests against a real PostgreSQL in docker (256 MB), reached
# through the in-process SSH server of the tests.
PG_PORT ?= 55432
pg-test:
	-docker rm -f dbm-test-pg >/dev/null 2>&1
	docker run -d --name dbm-test-pg --memory 256m -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=shop \
		-p 127.0.0.1:$(PG_PORT):5432 postgres:17-alpine >/dev/null
	@for i in $$(seq 1 60); do docker exec dbm-test-pg pg_isready -U postgres -d shop >/dev/null 2>&1 && break; sleep 1; done
	@sleep 2
	DBM_PG_DSN=postgres://postgres:secret@127.0.0.1:$(PG_PORT)/shop $(GOTEST) -count=1 ./core/... ; \
		s=$$?; docker rm -f dbm-test-pg >/dev/null; exit $$s

vet:
	go vet ./...

# The desktop core (desktopbind) as a C archive, linked into the Linux
# app's executable (app/linux/CMakeLists.txt runs this).
CORE_LIB ?= app/build/core/libdbmanager.a
core-lib: BUILD_ID = $(or $(DBM_BUILD_ID),dev)
core-lib:
	CGO_ENABLED=1 go build -buildmode=c-archive -ldflags '$(GO_LDFLAGS)' -o $(CORE_LIB) ./desktopbind

# Go and Dart code from proto/dbm.proto, and the Go client of CloudSync's
# Connector API from proto/connector.proto (a byte-for-byte copy of Shard's
# canonical proto/connector.proto).
proto:
	protoc -I proto \
		--go_out=core/rpc/pb --go_opt=paths=source_relative \
		--go-grpc_out=core/rpc/pb --go-grpc_opt=paths=source_relative \
		proto/dbm.proto
	mkdir -p app/lib/data/rpc/gen
	protoc -I proto --plugin=protoc-gen-dart=$(PROTOC_DART) --dart_out=grpc:app/lib/data/rpc/gen proto/dbm.proto
	protoc -I proto \
		--go_out=core/cloudsync/pb --go_opt=paths=source_relative --go_opt=Mconnector.proto=dbmanager/core/cloudsync/pb \
		--go-grpc_out=core/cloudsync/pb --go-grpc_opt=paths=source_relative --go-grpc_opt=Mconnector.proto=dbmanager/core/cloudsync/pb \
		proto/connector.proto

# The core for Android (gomobile).
aar:
	ANDROID_NDK_HOME=$(NDK) gomobile bind -target=android/arm64,android/amd64 -androidapi 26 \
		-javapkg dev.dbmanager -ldflags='-s -w $(GO_LDFLAGS)' -o app/android/app/libs/dbmanager.aar ./mobilebind

# --- Flutter app ---------------------------------------------------------

app-deps:
	cd app && flutter pub get

app-test: app-deps
	cd app && flutter analyze && $(CAP) flutter test --concurrency=1

build-linux: app-deps
	cd app && DBM_BUILD_ID=$(BUILD_ID) flutter build linux --release $(DEFINES)
	mkdir -p $(BIN)/linux
	cp -r app/build/linux/x64/release/bundle/. $(BIN)/linux/
	@echo "app: $(BIN)/linux/dbmanager"

build-apk: aar app-deps
	cd app && flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 $(DEFINES)
	mkdir -p $(BIN)/android
	cp app/build/app/outputs/flutter-apk/*-release.apk $(BIN)/android/

app-run: app-deps
	cd app && DBM_BUILD_ID=$(BUILD_ID) flutter run -d linux $(DEFINES)
