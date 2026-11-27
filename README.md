# Cellar

A small database manager in the spirit of DataGrip: a Database Explorer tree, a table
viewer and editor, and query consoles. PostgreSQL first. Databases are reached **over SSH**:
you add a server, Cellar looks for the database services running on it and offers to
connect.

Cellar was formerly called DB Manager.

Cellar is part of [SelfHold](https://github.com/SelfHold), a set of independent
self-hosted apps. It works on its own; optionally it syncs through
[Shard](https://github.com/SelfHold/shard) and then shares servers, host keys and SSH keys
with [Postern](https://github.com/SelfHold/postern), the SSH terminal and file manager.

## Status

A personal project at an early stage (version 0.1.0). It works for daily use on Linux,
but expect rough edges and breaking changes. Not done yet:

- **Android packaging**: there is a `make aar` target for the Go core (gomobile), but the
  AAR build is not finished and the Kotlin glue that starts the core and binds to Shard on
  Android is not written yet, so the Android app does not run.
- SQL completion in consoles.
- Databases other than PostgreSQL.

## Features

- **Servers over SSH**: password, private key or ssh-agent (desktop) authentication, jump
  servers, keepalive, one SSH connection per server shared by everything that uses it.
  Servers can be organised in nested folders.
- **Discovery**: on a server, one read-only shell script lists listening sockets,
  PostgreSQL clusters and processes, and docker containers. Every candidate port is checked
  with a PostgreSQL `SSLRequest` through the SSH connection. For containers, only
  `POSTGRES_USER` / `POSTGRES_DB` are read from their environment; passwords never leave the
  server.
- **Connections**: through a server, or directly from this device if you choose so. SSL
  mode (`disable` / `prefer` / `require`), read-only sessions, a colour tag, a filter for
  which databases to show, a connection test.
- **Explorer**: servers → connections → databases → schemas → tables, views, materialized
  views, foreign tables, sequences, routines, enums, domains and composite / range types.
  Tables open into columns, keys and checks, indexes and triggers. Next to the databases,
  a connection lists the server's users and roles. System schemas and the built-in `pg_*`
  roles are hidden unless you turn them on.
- **Create, modify, drop** from the context menu, as in DataGrip: users and roles
  (privileges, memberships, connection limit, password expiry), databases, schemas and
  tables (columns, primary key, constraints, indexes, comments, owner), and dropping any
  schema object. Every dialog shows the SQL it will run before you execute it, or opens it
  in a console instead. Changes run in one transaction where PostgreSQL allows it. A new
  password is hashed on this device (SCRAM-SHA-256, or md5 if the server keeps md5
  passwords), so the server never receives it in clear text.
- **Dumps and restores** with PostgreSQL's own tools: `pg_dump` of a database, a schema
  or a table (SQL, custom or tar format), and restores of SQL files through `psql` and of
  archives through `pg_restore`, with progress and the tools' log. The tools run on this
  device, reaching the database through the server's SSH connection over a private unix
  socket, or on the server itself over SSH when this device has no fitting `pg_dump`
  (`pg_dump` must not be older than the database server). The file always stays on this
  device; the database password is passed to the tools in their environment only.
- **Table viewer and editor**: paging, sorting by column, a `WHERE` filter, inline editing,
  inserting and deleting rows. Edits are submitted in one transaction; every `UPDATE` or
  `DELETE` must hit exactly one row (by primary key, else by `ctid`), otherwise everything
  rolls back.
- **Structure and DDL** of a table or other object.
- **Query consoles**: one pinned session per console (transactions, `SET`, temporary tables
  live as long as the console), run the statement at the cursor or all statements (stopping
  at the first error), cancel a running statement, transaction state, notices, error
  positions, SQL highlighting. The statement splitter knows strings, `E''` strings, quoted
  identifiers, dollar quotes and nested comments.
- **Optional sync through Shard**: servers and connections are the same on all your
  devices (see below).
- English and Russian UI. The app always starts in English; Russian is a choice in
  Settings, remembered on this device only.

Phone layout (below 768 px of width): the explorer is the page and tabs open as pushed
pages.

## Platforms

- **Linux**: the supported target.
- **Android**: in progress, see Status.
- **macOS and iOS**: planned; the platform-specific parts are kept behind small seams
  (`desktopbind`, `mobilebind`, `core/keychain`, the data-directory lookup).

Windows is not a target.

## Security model in brief

- **Database traffic goes through the server's SSH connection** (`direct-tcpip` channels).
  Host names are resolved on the server, never on this device. A connection set to "this
  device (direct)" is the only exception and connects from here.
- **Host-key trust**: the first connection to a server shows its host key and asks you to
  trust it. A changed host key is refused, and only replaced after your explicit
  "Replace the key"; saving a server never changes its host keys.
- **Nothing readable on disk**: the server and connection list (`cellar.json`), the
  per-device file (`device.json`) and the sync cache are sealed with XChaCha20-Poly1305
  (the file name as associated data) under a key kept in the OS keychain, or, without a
  keychain, in `local.key` (mode 0600; on Android in app-private storage).
- **Secrets in memory**: SSH keys from Shard's safe are fetched when connecting and kept in
  memory only; passphrases typed at connect time stay in memory. Keys you paste or load from
  a file stay on this device (`device.json`) and are never synced.
- **The UI holds no credentials**: the Go core does all SSH and database work; the Flutter
  app talks to it over a private unix socket with a bearer token and only renders.

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## Architecture

```
app/          Flutter UI (renders only; talks gRPC to the core)
proto/        cellar.proto: the core <-> app API; connector.proto: Shard's Connector API
core/         Go core: all logic and all secrets
  embed/        runs the core inside the app's process
  sshx/         SSH client pool, host keys, jump servers (sshtest: test SSH server)
  discover/     discovery script and candidate checks
  pg/           PostgreSQL: pools, metadata, data, consoles, statement splitter
  store/        the document (servers, connections), merge, sealing
  keychain/     OS keychain access
  shard/    Shard Connector client and the syncer (fake: in-memory Shard for tests)
  rpc/          the gRPC service
desktopbind/  C archive linked into the Linux executable
mobilebind/   gomobile binding for Android
```

There is no daemon. On Linux, `app/linux/CMakeLists.txt` runs `make core-lib`, links the
resulting C archive into the executable, and Dart starts it through FFI. On Android the core
is a gomobile AAR. A second app instance reuses the first one's core through
`endpoint.json`. The core's architecture follows [Parley](https://github.com/SelfHold/parley);
the SSH and server-list code started from [Postern](https://github.com/SelfHold/postern).

More detail, including the invariants the code relies on: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Building from source

Prerequisites:

- Go (version from `go.mod`) with cgo and a C compiler;
- Flutter (Dart SDK as in `app/pubspec.yaml`) with Linux desktop support (clang, CMake,
  Ninja, pkg-config, GTK 3 development headers);
- for `make proto`: `protoc`, `protoc-gen-go`, `protoc-gen-go-grpc` and `protoc-gen-dart`
  (expected in `~/.pub-cache/bin`);
- for `make aar` / `make build-apk`: `gomobile` and the Android SDK with an NDK (the newest
  one under `~/Android/Sdk/ndk` is used, or set `NDK=`);
- for `make pg-test` and `app/tool/e2e.sh`: docker.

```bash
make build-linux   # release bundle in builds/linux/ (executable: cellar)
make package-linux # deb, rpm and Arch packages in builds/packages (PKG=archlinux for one)
make icons         # re-render the PNG icons from the SVGs in branding/ (rsvg-convert)
make app-run       # run the app in debug mode
make core-lib      # only the core's C archive (app/build/core/libcellar.a)
make proto         # regenerate core/rpc/pb, core/shard/pb, app/lib/data/rpc/gen
make aar           # the core for Android (app/android/app/libs/cellar.aar)
make build-apk     # Android APKs in builds/android/ (the app does not run yet, see Status)
```

Every build output lands in `builds/`. Generated code is never edited by hand.

## Testing

Test runs are capped at 1 GB of memory (`systemd-run --user --scope`, so a systemd user
session is needed) and run one at a time.

```bash
make test        # Go unit tests
make race        # Go tests with the race detector
make vet         # go vet
make pg-test     # integration tests: postgres:17-alpine in docker (256 MB), reached
                 # through the in-process SSH server of the tests (core/sshx/sshtest)
make app-test    # flutter analyze + flutter test
app/tool/e2e.sh  # end-to-end run of the real app
```

Sync is tested against an in-memory Shard (`core/shard/fake`: records, shared servers,
safe keys, pairing, Watch, and an older Shard without the new scopes).

`app/tool/e2e.sh` starts a throwaway `sshd` on 127.0.0.1:2222 (keys only), a seeded
PostgreSQL in docker on 127.0.0.1:55433, and the app with an isolated config directory;
`app/tool/e2e.dart` then drives the app through a scenario (discover, connect, browse, edit,
console, structure, settings) and writes a screenshot after each step. It needs
`/usr/bin/sshd`, `ssh-keygen`, `python3`, docker, Flutter and an X11 display. It never
touches your real config, keychain or Shard (`CELLAR_NO_KEYCHAIN=1`, `CELLAR_NO_SHARD=1`).

## Sync through Shard (optional)

Cellar works without Shard. Turn sync on in Settings and approve the pairing in Shard; Shard
may be missing, stopped or locked at any moment, and the local file stays the working copy.

- Your servers and connections are kept in one record (`cellar.json` of app id
  `cellar`) and merge deterministically (union by id, newest change wins, deletions are
  kept as tombstones), so sync never asks you to resolve a conflict.
- With Shard's `servers` scope, servers live in Shard's shared list, which Postern uses too;
  servers kept by Cellar alone can be moved there (Settings → Move). Host keys
  trusted in one app are known to the others.
- With the `ssh_keys` scope, you can pick an SSH key from Shard's password safe when
  connecting.
- An older Shard without these scopes still syncs the record; servers then stay in Cellar's
  own list.

Cellar speaks Shard's Connector API; see the
[Connector guide](https://github.com/SelfHold/shard/blob/main/docs/CONNECTOR.md).
`proto/connector.proto` is a byte-for-byte copy of Shard's.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Cellar is free software under the [GNU General Public License v3.0](LICENSE).
