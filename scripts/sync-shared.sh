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

# One entry: a bare filename, or "source -> destination" when the file is
# named differently here (ams.html is this site's index.html). Blank lines
# and # comments are skipped.
sync_one() {
    src_name="${1%%->*}"; src_name="$(echo "$src_name" | xargs)"
    dst_name="${1#*->}";  dst_name="$(echo "$dst_name" | xargs)"
    [ "$1" = "$src_name" ] && dst_name="$src_name"

    if [ ! -f "$SRC/$src_name" ]; then
        echo "  MISSING in Binder Book: $src_name"
        missing=$((missing + 1))
        return
    fi
    if cmp -s "$SRC/$src_name" "$dst_name" 2>/dev/null; then
        return
    fi
    if [ "$CHECK" = "1" ]; then
        echo "  DRIFTED: $dst_name"
    else
        mkdir -p "$(dirname "$dst_name")"
        cp "$SRC/$src_name" "$dst_name"
        echo "  updated: $dst_name"
    fi
    drift=$((drift + 1))
}

for manifest in shared-files.txt app-files.txt; do
    [ -f "$manifest" ] || continue
    while read -r line; do
        case "$line" in ''|\#*) continue ;; esac
        sync_one "$line"
    done < "$manifest"
done

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
