#!/bin/sh
# scratch.sh - per-target scratch space, and a guard against cross-target contamination.
#
# WHY THIS EXISTS
#   Recon used to run out of one shared directory, /tmp/work, for every target and
#   every session. Tools leave generically-named files behind (sf.txt, resolved.txt,
#   live.txt, urls.txt), so a later session could read a previous target's output as
#   if it were its own.
#
#   That happened on 2026-10-16: an example.com subdomain run picked up 753 lines
#   of sf.txt left by an earlier example.org session. The contamination was caught
#   only by accident, when example.org hostnames turned up in a review of the output.
#
#   Two rules follow, and this script enforces both:
#     1. One scratch directory per target, refused if it already has content, so a
#        dirty directory can never be mistaken for a fresh one.
#     2. Every results file is checked against the target's registrable domain
#        before it is trusted or filed.
#
# USAGE
#   sh scratch.sh init  <target>              create a clean scratch dir, print its path
#   sh scratch.sh check <target> <file>...    fail if any file holds foreign hosts
#   sh scratch.sh reset <target>              delete that target's scratch dir
#   sh scratch.sh list                        list existing scratch dirs
#
# POSIX sh only. execute_command runs dash, so no bashisms.

SCRATCH_ROOT=${SCRATCH_ROOT:-/tmp/recon}

usage() {
    echo "usage: sh scratch.sh {init|check|reset|list} ..." >&2
    exit 2
}

# www.agoda.com -> agoda.com  (last two labels)
base_domain() {
    echo "$1" | tr 'A-Z' 'a-z' | sed 's/\.$//' | awk -F. '{print $(NF-1)"."$NF}'
}

# Pull a comparable hostname out of each line of a results file. Handles bare hosts,
# dnsx/httpx output with trailing columns, and full URLs.
extract_hosts() {
    awk '{print $1}' "$1" \
        | sed -E 's#^[a-zA-Z]+://##; s#/.*$##; s/:[0-9]+$//; s/\.$//' \
        | tr 'A-Z' 'a-z' \
        | grep -v '^$'
}

cmd_init() {
    [ $# -ge 1 ] || usage
    target=$1
    case "$target" in
        *[!a-zA-Z0-9._-]*) echo "bad target name: $target" >&2; exit 2 ;;
    esac

    dir="$SCRATCH_ROOT/$target"
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "REFUSED: scratch for $target already exists and is not empty:" >&2
        echo "  $dir" >&2
        echo "It may hold another session's output. Do not reuse it by accident -" >&2
        echo "either work in it deliberately, or clear it first:" >&2
        echo "  sh scratch.sh reset $target" >&2
        exit 3
    fi

    mkdir -p "$dir"
    echo "$dir"
}

cmd_check() {
    [ $# -ge 2 ] || usage
    target=$1
    shift
    base=$(base_domain "$target")
    esc=$(echo "$base" | sed 's/\./\\./g')

    rc=0
    for f in "$@"; do
        if [ ! -f "$f" ]; then
            echo "MISSING: $f" >&2
            rc=1
            continue
        fi
        # A host belongs to the target if it IS the base domain, or is any number of
        # labels deep under it: ^([^.]+\.)*base$ matches www.agoda.com and a.b.agoda.com
        # but rejects both b.ac.id and pricelineagoda.com (no dot before "agoda").
        off=$(extract_hosts "$f" | grep -vE "^([^.]+\\.)*$esc$" | sort -u)
        if [ -n "$off" ]; then
            echo "CONTAMINATION: $f holds hosts outside $base" >&2
            echo "$off" | head -25 | sed 's/^/    /' >&2
            rc=1
        else
            echo "clean: $f"
        fi
    done
    return $rc
}

cmd_reset() {
    [ $# -ge 1 ] || usage
    dir="$SCRATCH_ROOT/$1"
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "removed $dir"
    else
        echo "nothing at $dir"
    fi
}

cmd_list() {
    if [ -d "$SCRATCH_ROOT" ]; then
        ls -1 "$SCRATCH_ROOT"
    else
        echo "(no scratch root yet at $SCRATCH_ROOT)"
    fi
}

[ $# -ge 1 ] || usage
case "$1" in
    init)  shift; cmd_init "$@" ;;
    check) shift; cmd_check "$@" ;;
    reset) shift; cmd_reset "$@" ;;
    list)  shift; cmd_list "$@" ;;
    *)     usage ;;
esac