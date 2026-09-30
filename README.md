# Incus Pkl specifications

A versioned Pkl package containing typed Incus API models and server configuration
options. It has one purpose: let Pkl modules import Incus specifications and use
them for validation, completion, and rendering.

The current package targets **Incus v7.0.1**. It is generated from Incus' REST API
description and configuration metadata, with small documented corrections where
the YAML field names differ from the API schema. It does not contain Incus client
settings, deployment examples, an Incus CLI, or orchestration logic.

## Use the published package

Add the package dependency to a consumer's `PklProject`:

```pkl
amends "pkl:Project"

dependencies {
  ["incus"] {
    uri = "package://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-incus/incus-pkl@0.1.2"
  }
}
```

Resolve the dependency and import the public façade:

```pkl
import "@incus/Incus.pkl" as Incus

network: Incus.NetworksPost = new {
  name = "agents"
  type = "ovn"
}
```

```sh
pkl project resolve
pkl eval --format yaml network.pkl
```

`Incus.pkl` exports the generated API models and configuration option types. The
individual modules under `spec/api/` and `spec/options/` are also importable when a
consumer needs a narrower import.

## Develop and package

The executable `flake.pkl` runs Nix through
[`pkl-nix-tools`](https://github.com/Agence-Fluor/pkl-nix-tools#démarrer),
loaded from the project’s pinned `nixTools` Pkl dependency. No global wrapper installation is needed. Use `pkl eval flake.pkl` to render Nix only. The development shell provides Pkl, Python,
PyYAML, and curl:

```sh
./flake.pkl develop
python3 scripts/gen-incus-pkl.py --check
sh scripts/test-package.sh
sh scripts/package-pkl.sh
```

`package-pkl.sh` stages `PklProject`, `Incus.pkl`, and the API/options Pkl modules
before calling `pkl project package`. The published ZIP contains only the Pkl
modules; Pkl publishes package metadata as separate release files. Source
snapshots, generator code, coverage reports, and development files stay out of
the archive. `test-package.sh` extracts the ZIP into a clean temporary consumer,
checks its contents, and evaluates a typed Incus network. It is local and needs
no Incus daemon or network access.

The versioned source snapshots and SHA-256 lock are in `spec/sources/`. Normal
generation is offline and reproducible:

```sh
python3 scripts/gen-incus-pkl.py --check
```

To move to another Incus release, download that release's official inputs, review
the generated coverage report and YAML-name overrides, then update the package
version and regenerate:

```sh
python3 scripts/gen-incus-pkl.py --download --ref vX.Y.Z
```

The CI publishes package metadata and the ZIP as a GitHub release on tags named
`incus-pkl@<version>`. Update `version` in `PklProject`, commit it, then use
`git tag "$(sh scripts/release-tag.sh)"` and push that tag. The package name
is `incus-pkl`, even though the repository is named `pkl-incus`.
