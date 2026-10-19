#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/lib/ui.sh"
ui_init
OUTPUT="$ROOT/dist"
REPO=''

usage() {
  cat <<'EOF'
Usage: bash scripts/package.sh [--output DIRECTORY] [--repo OWNER/REPO]
Creates a versioned release archive and SHA-256 checksum. With --repo,
also creates a one-line remote installer for GitHub Releases.
EOF
}

while (( $# )); do
  case $1 in
    --output)
      (( $# >= 2 )) || { echo '--output requires a directory' >&2; exit 2; }
      OUTPUT=$2
      shift;;
    --repo)
      (( $# >= 2 )) || { echo '--repo requires OWNER/REPO' >&2; exit 2; }
      REPO=$2
      shift;;
    --help|-h) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2;;
  esac
  shift
done

version=$(<"$ROOT/VERSION")
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid VERSION: $version" >&2; exit 2; }
ui_heading 'Linux Dev Setup' "Package build · v$version"
if [[ -n $REPO ]]; then
  [[ $REPO =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "Invalid GitHub repository: $REPO" >&2; exit 2; }
fi
package="linux-dev-setup-v$version"
stage=$(mktemp -d)
archive_tmp=''
trap 'rm -rf "$stage"; if [[ -n $archive_tmp ]]; then rm -f "$archive_tmp"; fi' EXIT
mkdir -p "$OUTPUT"
OUTPUT=$(cd "$OUTPUT" && pwd)
cd "$ROOT"

# Keep the release contents explicit: local files and credentials cannot leak into it.
files=(
  VERSION README.md install.sh diagnose.sh
  config/*.conf lib/*.sh modules/*.sh scripts/resolve-download.py scripts/checklist-terminal.sh docs/tooling.md
)
for file in "${files[@]}"; do
  [[ -f "$ROOT/$file" ]] || { echo "Missing package file: $file" >&2; exit 1; }
  mkdir -p "$stage/$package/$(dirname "$file")"
  cp -p "$ROOT/$file" "$stage/$package/$file"
done

archive_tmp=$(mktemp "$OUTPUT/.${package}.XXXXXX")
COPYFILE_DISABLE=1 tar -czf "$archive_tmp" -C "$stage" "$package"
archive="$OUTPUT/$package.tar.gz"
mv -f "$archive_tmp" "$archive"
archive_tmp=''
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$OUTPUT" && sha256sum "$(basename "$archive")") > "$archive.sha256"
else
  (cd "$OUTPUT" && shasum -a 256 "$(basename "$archive")") > "$archive.sha256"
fi
ui_badge ok created; printf ' %s\n' "$archive"
ui_badge ok created; printf ' %s\n' "$archive.sha256"
if [[ -n $REPO ]]; then
  bootstrap=$(<"$ROOT/scripts/bootstrap.sh.in")
  bootstrap=${bootstrap//@GITHUB_REPO@/$REPO}
  bootstrap=${bootstrap//@VERSION@/$version}
  printf '%s\n' "$bootstrap" > "$OUTPUT/install.sh"
  chmod 755 "$OUTPUT/install.sh"
  ui_badge ok created; printf ' %s\n' "$OUTPUT/install.sh"
fi
