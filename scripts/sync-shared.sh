#!/usr/bin/env bash
# ============================================================
#  Copy the shared files from the Binder Book repo into this one.
#  ------------------------------------------------------------
#  The AMS and the Binder Book share the files listed in
#  shared-files.txt — the cloud sync layer above all, where a
#  difference between the two apps is how a book of business gets
#  overwritten. They are copied here verbatim, so "have they
#  drifted?" is answered by a byte comparison.
#
#  Edit those files in amanzor/uib-binderbook, never here.
#
#  Usage:
#    scripts/sync-shared.sh <path-to-uib-binderbook-checkout>
#    scripts/sync-shared.sh --check <path>   # report drift, change nothing
# ============================================================
set -euo pipefail

CHECK=0
if [ "${1:-}" = "--check" ]; then CHECK=1; shift; fi

SRC="${1:-}"
if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
    echo "usage: $0 [--check] <path-to-uib-binderbook-checkout>" >&2
    exit 2
fi

HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"

drift=0
missing=0

while read -r f; do
    [ -z "$f" ] && continue
    if [ ! -f "$SRC/$f" ]; then
        echo "  MISSING in Binder Book: $f"
        missing=$((missing + 1))
        continue
    fi
    if cmp -s "$SRC/$f" "$f" 2>/dev/null; then
        continue
    fi
    if [ "$CHECK" = "1" ]; then
        echo "  DRIFTED: $f"
    else
        cp "$SRC/$f" "$f"
        echo "  updated: $f"
    fi
    drift=$((drift + 1))
done < shared-files.txt

if [ "$missing" -gt 0 ]; then
    echo "$missing shared file(s) no longer exist in the Binder Book — update shared-files.txt." >&2
    exit 1
fi

if [ "$drift" -eq 0 ]; then
    echo "shared files are identical to the Binder Book's"
elif [ "$CHECK" = "1" ]; then
    echo "$drift shared file(s) differ from the Binder Book's"
    exit 1
else
    echo "$drift shared file(s) updated"
fi
