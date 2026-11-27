.PHONY: all test race vet core-lib build-linux proto aar app-deps app-test app-run build-apk pg-test package-linux icons

# Every build output lands in builds/ at the repo root.
BIN := builds
SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
VERSION := 0.1.0
STAMP := $(shell date +%m%d.%H%M%S)
BUILD_ID := $(or $(CELLAR_BUILD_ID),$(SHA)-$(STAMP))
DEFINES := --dart-define=APP_VERSION=$(VERSION) --dart-define=BUILD_SHA=$(SHA) --dart-define=BUILD_ID=$(BUILD_ID)
GO_LDFLAGS = -X github.com/SelfHold/cellar/core/rpc.Version=$(VERSION) -X github.com/SelfHold/cellar/core/rpc.Build=$(BUILD_ID)
NDK ?= $(lastword $(sort $(wildcard $(HOME)/Android/Sdk/ndk/*)))
PROTOC_DART := $(HOME)/.pub-cache/bin/protoc-gen-dart

# Test runs are capped at 1 GB and run one at a time.
CAP := systemd-run --user --scope -p MemoryMax=1G -p MemorySwapMax=0 --quiet
GOTEST := $(CAP) env GOMAXPROCS=2 go test -p 1

all: vet test

# --- Go core -------------------------------------------------------------

# Unit tests. The PostgreSQL integration tests run only with CELLAR_PG_DSN
# (make pg-test).
test:
	$(GOTEST) ./core/...

race:
	$(CAP) go test -race -p 1 ./core/...

# Integration tests against a real PostgreSQL in docker (256 MB), reached
# through the in-process SSH server of the tests.
PG_PORT ?= 55432
pg-test:
	-docker rm -f cellar-test-pg >/dev/null 2>&1
	docker run -d --name cellar-test-pg --memory 256m -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=shop \
		-p 127.0.0.1:$(PG_PORT):5432 postgres:17-alpine >/dev/null
	@for i in $$(seq 1 60); do docker exec cellar-test-pg pg_isready -U postgres -d shop >/dev/null 2>&1 && break; sleep 1; done
	@sleep 2
	CELLAR_PG_DSN=postgres://postgres:secret@127.0.0.1:$(PG_PORT)/shop $(GOTEST) -count=1 ./core/... ; \
		s=$$?; docker rm -f cellar-test-pg >/dev/null; exit $$s

vet:
	go vet ./...

# The desktop core (desktopbind) as a C archive, linked into the Linux
# app's executable (app/linux/CMakeLists.txt runs this).
CORE_LIB ?= app/build/core/libcellar.a
core-lib: BUILD_ID = $(or $(CELLAR_BUILD_ID),dev)
core-lib:
	CGO_ENABLED=1 go build -buildmode=c-archive -ldflags '$(GO_LDFLAGS)' -o $(CORE_LIB) ./desktopbind

# Go and Dart code from proto/cellar.proto, and the Go client of Shard's
# Connector API from proto/connector.proto (a byte-for-byte copy of Shard's
# canonical proto/connector.proto).
proto:
	mkdir -p core/rpc/pb core/shard/pb
	protoc -I proto \
		--go_out=core/rpc/pb --go_opt=paths=source_relative \
		--go-grpc_out=core/rpc/pb --go-grpc_opt=paths=source_relative \
		proto/cellar.proto
	mkdir -p app/lib/data/rpc/gen
	protoc -I proto --plugin=protoc-gen-dart=$(PROTOC_DART) --dart_out=grpc:app/lib/data/rpc/gen proto/cellar.proto
	protoc -I proto \
		--go_out=core/shard/pb --go_opt=paths=source_relative --go_opt=Mconnector.proto=github.com/SelfHold/cellar/core/shard/pb \
		--go-grpc_out=core/shard/pb --go-grpc_opt=paths=source_relative --go-grpc_opt=Mconnector.proto=github.com/SelfHold/cellar/core/shard/pb \
		proto/connector.proto

# The core for Android (gomobile).
aar:
	ANDROID_NDK_HOME=$(NDK) gomobile bind -target=android/arm64,android/amd64 -androidapi 26 \
		-javapkg dev.selfhold.cellar -ldflags='-s -w $(GO_LDFLAGS)' -o app/android/app/libs/cellar.aar ./mobilebind

# --- Flutter app ---------------------------------------------------------

app-deps:
	cd app && flutter pub get

app-test: app-deps
	cd app && flutter analyze && $(CAP) flutter test --concurrency=1

# A CMake cache made at another checkout path (the repo was moved or renamed)
# breaks `flutter build linux`, so it is dropped first.
build-linux: app-deps
	@c=app/build/linux/x64/release/CMakeCache.txt; \
	if [ -f "$$c" ] && ! grep -qxF "CMAKE_CACHEFILE_DIR:INTERNAL=$(CURDIR)/app/build/linux/x64/release" "$$c"; then \
		echo "CMake cache from another checkout path: removing app/build/linux"; \
		rm -rf app/build/linux; \
	fi
	cd app && CELLAR_BUILD_ID=$(BUILD_ID) flutter build linux --release $(DEFINES)
	mkdir -p $(BIN)/linux
	cp -r app/build/linux/x64/release/bundle/. $(BIN)/linux/
	@echo "app: $(BIN)/linux/cellar"

# Linux packages from the build-linux output, described in packaging/linux/nfpm.yaml.
# PKG picks the formats (deb, rpm, archlinux; all three by default), e.g.
#   make package-linux PKG=archlinux
# Packages land in $(BIN)/packages/. nfpm runs through `go run` unless it is installed.
PKG ?= deb rpm archlinux
NFPM ?= $(or $(shell command -v nfpm 2>/dev/null),go run github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.49.0)

package-linux: build-linux
	mkdir -p $(BIN)/packages
	@for p in $(PKG); do \
		PKG_VERSION=$(VERSION) $(NFPM) package -f packaging/linux/nfpm.yaml -p $$p -t $(BIN)/packages/ || exit 1; \
	done

# Re-renders the committed PNG icons (app, Android) from the SVGs in branding/.
icons:
	branding/render.sh

build-apk: aar app-deps
	cd app && flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 $(DEFINES)
	mkdir -p $(BIN)/android
	cp app/build/app/outputs/flutter-apk/*-release.apk $(BIN)/android/

app-run: app-deps
	cd app && CELLAR_BUILD_ID=$(BUILD_ID) flutter run -d linux $(DEFINES)
