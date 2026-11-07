#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd -- "$PKG_DIR/.." && pwd)"
SOURCE="$PKG_DIR/source"
PROJECT_ROOT="$PKG_DIR/.."
PROFILES="$PROJECT_ROOT/components/qemu/profiles.json"
QEMU_PROFILE="${QEMU_PROFILE:-composite}"
BUILD_ROOT="${BUILD_ROOT:-$REPO_ROOT/build/qemu}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')}"
CROSS_PREFIX="${CROSS_PREFIX:-}"
HOST_ARCH="$(uname -m)"

if [[ "$HOST_ARCH" != "riscv64" && -z "$CROSS_PREFIX" ]]; then
    printf 'Error: run natively on riscv64 Linux, or set CROSS_PREFIX for cross-compilation. Detected: %s\n' "$HOST_ARCH" >&2
    exit 2
fi

if [[ ! -f "$SOURCE/VERSION" ]] || [[ "$(tr -d '\r\n' < "$SOURCE/VERSION")" != "9.1.0" ]]; then
    printf 'Error: expected the unmodified QEMU 9.1.0 source tree at %s\n' "$SOURCE" >&2
    exit 2
fi

if [[ ! -f "$PROFILES" ]]; then
    printf 'Error: QEMU profiles file not found: %s\n' "$PROFILES" >&2
    exit 2
fi
PATCH_LIST="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1], encoding="utf-8-sig")); p=d["profiles"].get(sys.argv[2]); sys.exit("unknown QEMU profile: " + sys.argv[2]) if p is None else None; print("\n".join(p["patches"]))' "$PROFILES" "$QEMU_PROFILE")"
PATCHES=()
if [[ -n "$PATCH_LIST" ]]; then
    mapfile -t PATCHES <<< "$PATCH_LIST"
fi
for patch_rel in "${PATCHES[@]}"; do
    if [[ ! -f "$PROJECT_ROOT/$patch_rel" ]]; then
        printf 'Error: patch listed in profile is missing: %s\n' "$PROJECT_ROOT/$patch_rel" >&2
        exit 2
    fi
done

for tool in gcc g++ python3 pkg-config ninja patch sha256sum; do
    command -v "$tool" >/dev/null 2>&1 || {
        printf 'Error: required build tool not found: %s\n' "$tool" >&2
        exit 2
    }
done

if [[ -n "$CROSS_PREFIX" ]]; then
    command -v "${CROSS_PREFIX}gcc" >/dev/null 2>&1 || {
        printf 'Error: cross compiler not found: %sgcc\n' "$CROSS_PREFIX" >&2
        exit 2
    }
    command -v "${CROSS_PREFIX}g++" >/dev/null 2>&1 || {
        printf 'Error: cross compiler not found: %sg++\n' "$CROSS_PREFIX" >&2
        exit 2
    }
    export PKG_CONFIG_LIBDIR="${PKG_CONFIG_LIBDIR:-/usr/lib/riscv64-linux-gnu/pkgconfig:/usr/share/pkgconfig}"
    unset PKG_CONFIG_PATH
    command -v file >/dev/null 2>&1 || {
        printf 'Error: file is required to verify the cross-built ELF.\n' >&2
        exit 2
    }
fi

pkg-config --exists glib-2.0 || {
    printf 'Error: GLib 2 development files and pkg-config are required.\n' >&2
    exit 2
}

mkdir -p "$BUILD_ROOT/baseline" "$BUILD_ROOT/optimized"

configure_args=(
    --cpu=riscv64
    --target-list=riscv64-softmmu
    --without-default-features
    --enable-tcg
    --enable-fdt=internal
    --disable-kvm
    --disable-plugins
    --disable-download
    --disable-docs
    --disable-werror
    --disable-tools
    --disable-guest-agent
    --disable-install-blobs
    --disable-pixman
    --disable-gio
    --prefix=/opt/riscv-qemu
)
if [[ -n "$CROSS_PREFIX" ]]; then
    configure_args+=("--cross-prefix=$CROSS_PREFIX")
fi

build_one() {
    local name="$1"
    local src="$2"
    local build_dir="$BUILD_ROOT/$name"
    (
        cd "$build_dir"
        "$src/configure" "${configure_args[@]}"
        ninja -j "$JOBS" qemu-system-riscv64
    )
    printf '\n%s binary: %s\n' "$name" "$build_dir/qemu-system-riscv64"
    if [[ -z "$CROSS_PREFIX" ]]; then
        "$build_dir/qemu-system-riscv64" --version
    else
        file "$build_dir/qemu-system-riscv64"
        file "$build_dir/qemu-system-riscv64" | grep -q 'RISC-V'
    fi
    sha256sum "$build_dir/qemu-system-riscv64"
}

printf 'Building baseline QEMU 9.1.0 with the shared configure options.\n'
build_one baseline "$SOURCE"

worktree="$(mktemp -d "$BUILD_ROOT/.optimized-source.XXXXXX")"
cleanup_worktree() {
    if [[ -n "${worktree:-}" && -d "$worktree" ]]; then
        chmod -R u+rwX "$worktree" 2>/dev/null || true
        rm -rf -- "$worktree"
    fi
}
trap cleanup_worktree EXIT
cp -a "$SOURCE/." "$worktree/"
for patch_rel in "${PATCHES[@]}"; do
    patch="$PROJECT_ROOT/$patch_rel"
    printf 'Applying %s\n' "$patch_rel"
    (
        cd "$worktree"
        patch --batch --fuzz=0 --dry-run -p1 -i "$patch"
        patch --batch --fuzz=0 -p1 -i "$patch"
    )
done

printf '\nBuilding optimized QEMU from the same baseline and configure options.\n'
build_one optimized "$worktree"

printf '\nBuild complete. Outputs are under %s/{baseline,optimized}/.\n' "$BUILD_ROOT"