#!/bin/sh
set -eu

repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
temp=$(mktemp -d)
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$temp/dist" "$temp/package" "$temp/consumer"
sh "$repo/scripts/package-pkl.sh" "$temp/dist"
version=$(pkl eval --no-project -x 'package.version' "$repo/PklProject")
archive="$temp/dist/incus-pkl@$version.zip"
python3 - "$archive" "$temp/package" <<'PY'
import sys
import zipfile
from pathlib import Path

archive, package_dir = Path(sys.argv[1]), Path(sys.argv[2])
with zipfile.ZipFile(archive) as package:
    files = {name for name in package.namelist() if not name.endswith("/")}
    required = {"Incus.pkl", "spec/api/Types.pkl", "spec/options/Options.pkl"}
    if not required <= files:
        raise SystemExit(f"Package is missing required files: {sorted(required - files)}")
    invalid = sorted(name for name in files if name not in {"PklProject", "Incus.pkl"}
                     and not name.startswith(("spec/api/", "spec/options/")))
    if invalid:
        raise SystemExit(f"Package contains non-spec files: {invalid}")
    package.extractall(package_dir)
PY
cp "$repo/PklProject" "$temp/package/PklProject"

cat > "$temp/consumer/PklProject" <<EOF
amends "pkl:Project"

dependencies {
  ["incus"] = import("../package/PklProject")
}
EOF

cat > "$temp/consumer/smoke.pkl" <<'EOF'
import "@incus/Incus.pkl" as Incus

network: Incus.NetworksPost = new {
  name = "package-smoke-test"
  type = "ovn"
}
EOF

cd "$temp/consumer"
pkl project resolve
pkl eval --format yaml smoke.pkl > "$temp/rendered.yaml"
grep -q 'name: package-smoke-test' "$temp/rendered.yaml"
cat "$temp/rendered.yaml"
