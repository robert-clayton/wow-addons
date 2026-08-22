#!/usr/bin/env bash
# Full pipeline: shipped Lua -> database -> emitted Lua -> proof they match.
#
#   bash scripts/db/run.sh
#
# Exits non-zero if the round trip is not clean, so it works as a gate. Run it
# after any change to the schema, the loader, or the emitter -- and after any
# hand edit to a data file, which is the case it is really there to catch.
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build

luajit scripts/db/dump-shipped-data.lua  > build/shipped.jsonl
python scripts/db/build-db.py
python scripts/db/emit-lua.py
luajit scripts/db/dump-emitted-data.lua  > build/emitted.jsonl
python scripts/db/compare-roundtrip.py

# Upstream reconciliation, into build/collectionist-full.db. Runs last because
# the round trip above must pass against the catalog alone.
python scripts/db/ingest-upstream.py
