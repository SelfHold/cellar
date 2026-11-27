# Contributing to Cellar

Bug reports, ideas and pull requests are welcome. Cellar is a personal project at an early
stage, so for anything bigger than a small fix, please open an issue first so we can agree
on the approach.

Security problems go through [SECURITY.md](SECURITY.md), not public issues.

## Before you start

Read [README.md](README.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). The invariants
listed there (the document always merges, nothing readable on disk, secrets only in memory,
database traffic through SSH, host keys only changed by the user, one-row edits) are
properties the code relies on; changes that break them will not be merged.

## Development

```bash
make vet test      # Go core
make race          # Go core with the race detector
make pg-test       # integration tests against PostgreSQL in docker
make app-test      # flutter analyze + flutter test
make proto         # after editing proto/cellar.proto
make app-run       # run the app
app/tool/e2e.sh    # end-to-end run of the real app (sshd + docker)
```

Test targets cap memory at 1 GB and should run one at a time. Build outputs go to
`builds/`. Sync behaviour is tested against the in-memory Shard in `core/shard/fake`,
not a live one.

## Rules

- **English only** in code, identifiers, comments, commit messages, logs and error messages.
  Other languages are allowed only in translations: UI strings, Android `values-<lang>/`
  resources, and translated documents that match their English original.
- UI strings go through `tr('English', 'Русский')` (`app/lib/core/i18n.dart`). The app starts
  in English; Russian is a per-device setting.
- Use only the widgets of `app/lib/presentation/common/hm.dart` and the `HmColors` /
  `HmText` design tokens: no raw colours, no Material elevation. Every screen must also work
  in the phone layout (below 768 px).
- Generated code (`core/rpc/pb`, `core/shard/pb`, `app/lib/data/rpc/gen`) is regenerated
  with `make proto`, never edited by hand.
- `proto/connector.proto` is a byte-for-byte copy of
  [Shard's](https://github.com/SelfHold/shard); change it there first.
- Don't rename persisted identifiers: the connector app id `cellar`, the record
  `cellar.json`, the `cellar.*` `extra` keys, the data directory, keychain entries, the
  Android package. They live on users' devices.
- Shared core code makes no Linux-only assumptions; platform specifics stay in
  `desktopbind`, `mobilebind`, `core/keychain` and the data-directory lookup. Windows is not
  a target.
- Run `gofmt` and `dart format`; keep `make vet` and `flutter analyze` clean. Add tests for
  behaviour changes.

## License

By contributing you agree that your contributions are licensed under the
[GNU GPL v3.0](LICENSE).
