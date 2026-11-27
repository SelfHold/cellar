# Cellar architecture

Cellar (formerly DB Manager; some identifiers still use the old name) is a Go core running
inside the app's process and a Flutter UI that talks to it over gRPC (`proto/dbm.proto`).
The core owns the SSH connections, the database sessions, the server and connection lists
and the sync with Shard; the app only draws and never holds credentials.

## Process layout

- `core/embed` runs the core inside the app's own process and serves the gRPC API on a
  private unix socket (`$XDG_RUNTIME_DIR/dbmanager.sock`) with a bearer token.
- **Linux**: `desktopbind` is a C archive (`make core-lib`) that `app/linux/CMakeLists.txt`
  links into the executable; Dart calls `DbmStart` / `DbmStop` / `DbmFree` through FFI. The
  address and token are written to `endpoint.json` (readable only by the user); a second app
  instance finds a live endpoint there and reuses the first one's core.
- **Android**: `mobilebind` is bound with gomobile into an AAR (`make aar`). The AAR build is
  not finished, and the Kotlin side that starts the core and binds to Shard's service is not
  written yet.
- Data directory: `~/.config/dbmanager` on Linux, app-private storage on Android.

## Packages

| Package | Role |
|---|---|
| `core/rpc` | the gRPC service (`DBManager` in `dbm.proto`) |
| `core/store` | the document (servers, connections, tombstones), its merge, the per-device file, sealing |
| `core/sshx` | SSH client pool (one client per server, keepalive, jump servers), host keys; `sshtest` is an in-process SSH server for tests |
| `core/discover` | the discovery script and the checks of its candidates |
| `core/pg` | pgx pools, metadata, table data and edits, consoles, the statement splitter |
| `core/keychain` | OS keychain access (and a no-op variant) |
| `core/cloudsync` | the client of Shard's Connector API and the syncer; `fake` is an in-memory Shard for tests |

## Invariants

The code relies on these properties; changes that break them will not be merged.

- **Standalone first.** Everything works without Shard. Shard may be missing, stopped or
  locked at any moment.
- **The document always merges.** `store.Doc` (own servers, connections, tombstones) is the
  local working copy and, with sync on, the record `dbmanager.json` of connector app id
  `dbmanager` (neither name may change). `store.Merge` is a union by id, newest `updated_ms`
  wins, tombstones, order-independent, so sync never asks the user. Per-device state
  (`cloudsync.json`, the pairing token in the keychain, `device.json`) is never synced.
- **Shared servers and keys.** With Shard's `servers` scope, new servers go to the shared
  list; servers of Cellar's own stay until the user moves them (which re-keys their
  connections). Cellar's keys in `Server.extra` start with `dbmanager.`; other apps' keys are
  kept as they are. `proto/connector.proto` is a byte-for-byte copy of Shard's.
- **Host keys.** A changed host key is written only after the user's explicit "replace".
  `SaveServer` never changes host keys; only `TrustHostKey` does.
- **Secrets.** Keys from Shard's safe are fetched with `GetSshKeys` at connect time and kept
  in memory only. Pasted keys live in `device.json` (this device only, `local:` ids; for a
  shared server the choice is `Device.ServerKeys`). Passphrases typed at connect stay in
  memory. Logs, errors and RPC responses carry no passwords or keys.
- **Nothing readable on disk.** `dbmanager.json`, `device.json` and the sync cache are sealed
  (XChaCha20-Poly1305, associated data = file name) with a key from the OS keychain, else
  `local.key` (0600; on Android in app-private storage). `DBM_NO_KEYCHAIN=1` and
  `DBM_NO_CLOUDSYNC=1` are for development and tests.
- **Database traffic through SSH.** Connections bound to a server go through its SSH
  connection (`direct-tcpip`); host names are resolved on the server (pgx `LookupFunc`),
  never here. SSH channels report `0.0.0.0:0` as their remote address, so `pg.Config` wraps
  them (`addrConn`): a CancelRequest needs the real address. Only connections set to "this
  device (direct)" dial from here.
- **Text format.** Values travel in PostgreSQL text format (simple protocol, `ExecParams`
  with unknown OIDs): the server parses and prints every type.
- **Edits.** One transaction per submit; every `UPDATE` / `DELETE` must hit exactly one row
  (primary key, else `ctid`), otherwise everything rolls back.
- **Consoles** pin one session. `Execute` runs the statement at the cursor (UTF-16 offsets,
  the editor's units) or all statements, stopping at the first error. `pg.Split` knows
  strings, `E''`, quoted identifiers, dollar quotes and nested comments.
- **Discovery** runs one read-only script (`discover.Script`). From containers' environment
  only `POSTGRES_USER` / `POSTGRES_DB` are passed on; no passwords leave the server. Every
  candidate is checked with a PostgreSQL `SSLRequest` through SSH; unnamed ports that do not
  answer are dropped.

## App (`app/`)

- UI strings go through `tr('English', 'Русский')` (`app/lib/core/i18n.dart`). The app
  starts in English whatever the system locale; Russian is picked in Settings and stored in
  the per-device `app.json` (never synced).
- Screens use only the widgets of `app/lib/presentation/common/hm.dart` and the design tokens
  `HmColors` / `HmText`. Below 768 px of width the phone layout is used: the explorer is the
  page, tabs are pushed pages.
- `app/lib/data/rpc/gen` is generated by `make proto`; import it `as pb`. Proto fields
  `null` / `default` are `null_2` / `default_4` in Dart.

## Sync

See the [Connector guide](https://github.com/SelfHold/shard/blob/main/docs/CONNECTOR.md)
(§ 7 for the one-record integration, § 13 for `ssh_keys`, § 14 for `servers`, § 11 for
compatibility with an older Shard).
