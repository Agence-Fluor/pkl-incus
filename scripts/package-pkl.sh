#!/bin/sh
set -eu

repo=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
cd "$repo"
output_path=${1:-dist}
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT HUP INT TERM

mkdir -p "$stage/spec" "$output_path"
cp "$repo/PklProject" "$repo/PklProject.deps.json" "$repo/Incus.pkl" "$stage/"
cp -a "$repo/spec/api" "$repo/spec/options" "$stage/spec/"

# The launcher is a development dependency, outside the published library.
printf 'amends "%s/PklProject"\ndependencies = super.dependencies.toMap().filter((name, _) -> name != "nixTools").toMapping()\n' "$repo" > "$stage/PklProject"
pkl project package --skip-publish-check --output-path "$output_path" "$stage"
