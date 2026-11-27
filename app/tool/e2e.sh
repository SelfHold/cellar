#!/bin/sh
# End-to-end run of the real app: a throwaway sshd on 127.0.0.1:2222 (keys
# only, own host key), a seeded PostgreSQL in docker (256 MB) and an
# isolated config dir with one server. tool/e2e.dart then drives the app
# and writes screenshots to $DIR/shots. Nothing touches the real config,
# keychain or CloudSync (DBM_NO_KEYCHAIN, DBM_NO_CLOUDSYNC).
#
#   app/tool/e2e.sh            # from the repo root
set -eu
DIR=${DIR:-$(mktemp -d /tmp/dbm-e2e.XXXXXX)}
APP=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$DIR/ssh" "$DIR/cfg/dbmanager"
echo "work dir: $DIR"

ssh-keygen -q -t ed25519 -N '' -f "$DIR/ssh/hostkey"
ssh-keygen -q -t ed25519 -N '' -C e2e -f "$DIR/ssh/client"
cp "$DIR/ssh/client.pub" "$DIR/ssh/authorized_keys"
chmod 600 "$DIR/ssh/authorized_keys"
cat > "$DIR/ssh/sshd_config" <<EOF
Port 2222
ListenAddress 127.0.0.1
HostKey $DIR/ssh/hostkey
PidFile $DIR/ssh/sshd.pid
AuthorizedKeysFile $DIR/ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
StrictModes no
AllowTcpForwarding yes
EOF
/usr/bin/sshd -f "$DIR/ssh/sshd_config" -E "$DIR/ssh/sshd.log"

docker run -d --name dbm-e2e-pg --memory 256m -e POSTGRES_PASSWORD=secret -e POSTGRES_USER=shop -e POSTGRES_DB=shop \
	-p 127.0.0.1:55433:5432 postgres:17-alpine >/dev/null
cleanup() {
	kill "$(cat "$DIR/ssh/sshd.pid")" 2>/dev/null || true
	docker stop dbm-e2e-pg >/dev/null 2>&1 || true
	docker rm dbm-e2e-pg >/dev/null 2>&1 || true
}
trap cleanup EXIT
for i in $(seq 1 40); do docker exec dbm-e2e-pg pg_isready -U shop -d shop >/dev/null 2>&1 && break; sleep 1; done
sleep 2
docker exec -i dbm-e2e-pg psql -U shop -d shop -q <<'SQL'
CREATE TABLE customers (id serial PRIMARY KEY, name text NOT NULL, email text UNIQUE, city text, created timestamptz DEFAULT now());
INSERT INTO customers (name, email, city) SELECT 'Customer ' || g, 'c' || g || '@example.com', (ARRAY['Moscow','Berlin','Paris','Tokyo'])[1 + g % 4] FROM generate_series(1, 1234) g;
CREATE TABLE orders (id bigserial PRIMARY KEY, customer_id int REFERENCES customers(id), total numeric(10,2), status text, items jsonb);
INSERT INTO orders (customer_id, total, status, items) SELECT 1 + g % 1234, (g * 7.31)::numeric % 900, (ARRAY['new','paid','shipped'])[1 + g % 3], jsonb_build_object('sku', 'A' || g, 'qty', g % 5 + 1) FROM generate_series(1, 5000) g;
CREATE VIEW paid_orders AS SELECT o.id, c.name, o.total FROM orders o JOIN customers c ON c.id = o.customer_id WHERE status = 'paid';
CREATE SCHEMA analytics; CREATE TABLE analytics.events (at timestamptz, kind text);
CREATE FUNCTION order_count(cid int) RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM orders WHERE customer_id = cid $$;
SQL

# One server (no trusted host key yet: the run trusts it) with a local key.
python3 - "$DIR" <<'EOF'
import json, sys, time, getpass
d = sys.argv[1]
now = int(time.time() * 1000)
json.dump({"version": 1, "connections": [], "servers": [{"id": "srv1", "name": "local-docker", "group": "dev", "host": "127.0.0.1",
    "port": 2222, "user": getpass.getuser(), "auth": "key", "key_id": "local:k1", "updated_ms": now}]},
    open(d + "/cfg/dbmanager/dbmanager.json", "w"))
json.dump({"local_keys": [{"id": "k1", "title": "e2e key", "private_key": open(d + "/ssh/client").read(), "created_ms": now}]},
    open(d + "/cfg/dbmanager/device.json", "w"))
EOF
chmod 600 "$DIR"/cfg/dbmanager/*.json

cd "$APP"
GDK_BACKEND=${GDK_BACKEND:-x11} XDG_CONFIG_HOME="$DIR/cfg" DBM_NO_KEYCHAIN=1 DBM_NO_CLOUDSYNC=1 \
	SHOTS="$DIR/shots" E2E_PG_PASSWORD=secret flutter run -d linux -t tool/e2e.dart
echo "screenshots: $DIR/shots"
