#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
REPOSITORY=SmaCow666/riscv-datacenter-optimization
REMOTE="https://github.com/$REPOSITORY.git"

if [[ $# -ne 0 ]]; then
    printf 'Usage: bash %s\nTarget: %s\n' "$0" "$REMOTE" >&2
    exit 2
fi
for tool in git python3; do
    command -v "$tool" >/dev/null || { printf 'Required command not found: %s\n' "$tool" >&2; exit 2; }
done
[[ -f "$ROOT/README.md" && -d "$ROOT/源码与构建脚本/vendor" && -d "$ROOT/Benchtest" ]] || {
    printf 'Source and Benchtest directories are required beside README.md.\n' >&2; exit 2;
}

python3 - "$ROOT" <<'PY'
import os
from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve()
for folder in ['源码与构建脚本','Benchtest']:
    for base,dirs,files in os.walk(root/folder,followlinks=False):
        path=Path(base);rel=path.relative_to(root).as_posix()
        if path==root/'源码与构建脚本' or path==root/'Benchtest':
            dirs[:]=[d for d in dirs if not(d=='build' or d.startswith(('build-','run-')))]
        if path==root/'Benchtest/qemu/guest':dirs[:]=[d for d in dirs if d!='build']
        dirs[:]=[d for d in dirs if d not in ['.git','__pycache__']]
        for name in files:
            p=path/name
            if p.is_symlink() and not p.resolve().is_relative_to(root):raise SystemExit('External source link: '+str(p))
            if p.is_file() and p.stat().st_size>100_000_000:raise SystemExit('File exceeds GitHub source limit: '+str(p))
PY

if [[ -e "$ROOT/.git" ]]; then
    [[ -d "$ROOT/.git" && ! -L "$ROOT/.git" ]] || { printf 'Use a standalone repository, not a linked worktree.\n' >&2; exit 2; }
    [[ "$(git -C "$ROOT" rev-parse --show-toplevel)" == "$ROOT" ]] || exit 2
    [[ "$(git -C "$ROOT" symbolic-ref --short HEAD)" == main ]] || { printf 'Expected local branch main.\n' >&2; exit 2; }
else
    if git -C "$ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
        printf 'Move this directory outside the enclosing Git repository first.\n' >&2; exit 2
    fi
fi
[[ -n "$(git -C "$ROOT" config user.name || true)" && -n "$(git -C "$ROOT" config user.email || true)" ]] || {
    printf 'Configure git user.name and user.email before uploading.\n' >&2; exit 2;
}
if [[ -d "$ROOT/.git" ]]; then
    CURRENT=$(git -C "$ROOT" config --get remote.origin.url || true)
    PUSH_URL=$(git -C "$ROOT" config --get remote.origin.pushurl || true)
    for value in "$CURRENT" "$PUSH_URL"; do
        [[ -z "$value" || "$value" == "$REMOTE" || "$value" == "git@github.com:$REPOSITORY.git" ]] || {
            printf 'Existing origin belongs to another repository: %s\n' "$value" >&2; exit 2;
        }
    done
fi

# The remote repository is created manually before this script is run.
TARGET_REMOTE=${CURRENT:-$REMOTE}
git ls-remote "$TARGET_REMOTE" >/dev/null
if [[ ! -d "$ROOT/.git" ]]; then
    git -C "$ROOT" init -b main
fi

git -C "$ROOT" add --all -- README.md .gitignore '源码与构建脚本' Benchtest
# Upstream ignore rules must not omit files supplied in the source snapshots.
git -C "$ROOT" add --force -- '源码与构建脚本/vendor' '源码与构建脚本/qemu/source' 'Benchtest/qemu/guest/source'
if ! git -C "$ROOT" diff --cached --quiet; then
    git -C "$ROOT" commit -m 'Add RISC-V component sources, build scripts and benchmarks'
fi
git -C "$ROOT" rev-parse --verify HEAD >/dev/null

if ! git -C "$ROOT" remote get-url origin >/dev/null 2>&1; then
    git -C "$ROOT" remote add origin "$REMOTE"
fi
git -C "$ROOT" push --set-upstream origin main
printf '\nhttps://github.com/%s\n' "$REPOSITORY"
