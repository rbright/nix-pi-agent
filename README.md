# nix-pi-agent

[![CI](https://github.com/rbright/nix-pi-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/rbright/nix-pi-agent/actions/workflows/ci.yml)

Standalone Nix flake packaging for `pi` (from
[`badlogic/pi-mono`](https://github.com/badlogic/pi-mono)).

## What this repo provides

- Nix package: `pi-agent` (binary: `pi`)
- Nix app output: `.#pi-agent`
- Scripted updater for version/source/npm hash pin refresh
- Scheduled GitHub Actions updater that opens auto-mergeable PRs
- Automated GitHub release creation on `pi-agent` version bumps
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

## Automated GitHub updates

Workflow: `.github/workflows/update-pi-agent.yml`

- Runs every 6 hours and on manual dispatch.
- Detects the latest stable upstream tag from `badlogic/pi-mono`.
- If newer than `package.nix`, runs `scripts/update-package.sh` and opens/updates a PR.
- Enables auto-merge (`squash`) for that PR.

### One-time repository setup

1. Add repo secret `PI_AGENT_UPDATER_TOKEN` (fine-grained PAT scoped to this repo):
   - **Contents**: Read and write
   - **Pull requests**: Read and write
2. In repository settings → **Actions → General**:
   - Set workflow permissions to **Read and write permissions**.
   - Enable **Allow GitHub Actions to create and approve pull requests**.
3. Ensure branch protection/required checks allow auto-merge after CI passes.

Manual trigger:

- Actions → **Update pi-agent package** → **Run workflow**
- Optional input: `version` (accepts `0.x.y` or `v0.x.y`)

## Automated GitHub releases

Workflow: `.github/workflows/release-pi-agent.yml`

- Runs on pushes to `main` when `package.nix` changes.
- Compares previous and current `package.nix` `version` values.
- Creates a GitHub release + tag (`v<version>`) only when the packaged version changes.
- Skips docs-only merges and other changes that do not modify `package.nix` version.

No extra secret is required; it uses the workflow `GITHUB_TOKEN` with `contents: write`.

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
