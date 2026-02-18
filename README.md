# nix-pi-agent

[![CI](https://github.com/rbright/nix-pi-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/rbright/nix-pi-agent/actions/workflows/ci.yml)

Standalone Nix flake packaging for `pi` (from
[`badlogic/pi-mono`](https://github.com/badlogic/pi-mono)).

## What this repo provides

- Nix package: `pi-agent` (binary: `pi`)
- Nix app output: `.#pi-agent`
- Scripted updater for version/source/npm hash pin refresh
- Local quality gate (`just`) and GitHub Actions CI

## Quickstart

```sh
# list commands
just --list

# full local validation gate
just check

# run the packaged binary
just run --help
```

## Build and run

```sh
nix build -L 'path:.#pi-agent'
nix run 'path:.#pi-agent' -- --help
```

Success criteria:

- `nix build` exits `0`
- `nix run` prints `pi` CLI usage output

## Update workflow

```sh
# latest from npm package metadata
just update

# explicit version
just update 0.53.0
```

`./scripts/update-package.sh` updates all three values in `package.nix`:

- `version`
- `src.hash`
- `npmDepsHash`

### Updater prerequisites

- `curl`
- `jq`
- `nix`
- `npm`
- `perl`
- `tar`

Check script usage:

```sh
./scripts/update-package.sh --help
```

## Linting and checks

```sh
just fmt
just fmt-check
just lint
just check
```

`just lint` runs:

- `statix`
- `deadnix`
- `nixfmt --check`
- `shellcheck`

## Use from another flake

```nix
{
  inputs.nixPiAgent.url = "github:rbright/nix-pi-agent";

  outputs = { self, nixpkgs, nixPiAgent, ... }: {
    # Example: include in a NixOS system package list
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            nixPiAgent.packages.${pkgs.system}.pi-agent
          ];
        })
      ];
    };
  };
}
```
