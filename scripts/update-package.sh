#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage:
  ${0} [--version <version>] [--file <path>]

Examples:
  ${0}
  ${0} --version 0.53.0
  ${0} --version v0.53.0
  ${0} --file ${script_dir}/../package.nix

Environment overrides:
  PI_PACKAGE_NAME   npm package name (default: @mariozechner/pi-agent)
  PI_REPO_OWNER     GitHub owner (default: badlogic)
  PI_REPO_NAME      GitHub repo (default: pi-mono)
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

version=""
target_file="${script_dir}/../package.nix"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      version="${2:-}"
      shift 2
      ;;
    --file)
      target_file="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

package_name="${PI_PACKAGE_NAME:-@mariozechner/pi-agent}"
repo_owner="${PI_REPO_OWNER:-badlogic}"
repo_name="${PI_REPO_NAME:-pi-mono}"

require_cmd curl
require_cmd jq
require_cmd nix
require_cmd npm
require_cmd perl
require_cmd tar

if [[ ! -f "$target_file" ]]; then
  echo "Target file not found: $target_file" >&2
  exit 1
fi

if [[ -z "$version" ]]; then
  version="$(npm view "$package_name" version)"
fi

version="${version#v}"
if [[ -z "$version" ]]; then
  echo "Resolved version is empty" >&2
  exit 1
fi

tag="v${version}"
source_url="https://github.com/${repo_owner}/${repo_name}/archive/${tag}.tar.gz"

echo "Updating Pi package definition"
echo "  package: ${package_name}"
echo "  repo:    ${repo_owner}/${repo_name}"
echo "  version: ${version}"

source_hash="$(
  nix store prefetch-file --json --unpack "$source_url" \
    | jq -r '.hash'
)"

if [[ ! "$source_hash" =~ ^sha256- ]]; then
  echo "Failed to resolve source hash from: $source_url" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL "$source_url" -o "$tmpdir/source.tar.gz"
tar -xzf "$tmpdir/source.tar.gz" -C "$tmpdir"

lockfile="$(find "$tmpdir" -maxdepth 2 -type f -name package-lock.json | head -n 1)"
if [[ -z "$lockfile" ]]; then
  echo "Could not find package-lock.json in fetched source archive" >&2
  exit 1
fi

npm_deps_hash="$(
  nix --extra-experimental-features "nix-command flakes" \
    shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$lockfile"
)"

if [[ ! "$npm_deps_hash" =~ ^sha256- ]]; then
  echo "Failed to resolve npm dependency hash" >&2
  exit 1
fi

VERSION="$version" perl -0pi -e 's/(\n\s*version = )"[^"]+";/$1 . "\"" . $ENV{VERSION} . "\";"/e' "$target_file"
SOURCE_HASH="$source_hash" perl -0pi -e 's/(src = fetchFromGitHub \{.*?\n\s*hash = )"sha256-[^"]+";/$1 . "\"" . $ENV{SOURCE_HASH} . "\";"/se' "$target_file"
NPM_DEPS_HASH="$npm_deps_hash" perl -0pi -e 's/(\n\s*npmDepsHash = )"sha256-[^"]+";/$1 . "\"" . $ENV{NPM_DEPS_HASH} . "\";"/e' "$target_file"

echo "Updated: $target_file"
echo "  version:     $version"
echo "  src.hash:    $source_hash"
echo "  npmDepsHash: $npm_deps_hash"
