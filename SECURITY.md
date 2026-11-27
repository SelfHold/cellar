# Security policy

Cellar handles database credentials, SSH keys and passphrases, and runs commands on your
servers, so security reports are taken seriously.

## Supported versions

Cellar is at an early stage; only the latest version on `main` receives security fixes.

## Reporting a vulnerability

Please **do not open a public issue**. Report privately through
[GitHub security advisories](https://github.com/SelfHold/cellar/security/advisories/new).

Include what you found, how to reproduce it and what an attacker could gain. You will get an
answer within a week; fixes are released as soon as they are ready, and you will be credited
unless you prefer otherwise.

## Scope

In scope, for example:

- database credentials, SSH private keys or passphrases written to disk unsealed, or leaking
  into logs, error messages, RPC responses or the sync record;
- weaknesses in the sealing of `cellar.json`, `device.json` or the sync cache, or in the
  handling of the local key;
- host-key checks that can be bypassed, or a changed host key accepted without the user's
  explicit consent;
- database traffic or host-name resolution leaving the SSH connection for a connection bound
  to a server;
- the discovery script doing anything but reading, or passing secrets (such as container
  passwords) off the server;
- a table edit hitting more than one row without rolling back;
- the core's local gRPC endpoint being reachable without its token;
- Cellar exposing data of the Shard Connector beyond the scopes the user granted.

Out of scope: vulnerabilities in PostgreSQL, OpenSSH or Shard themselves (report those to
their projects), and attacks that need control of the user's account on the device.
