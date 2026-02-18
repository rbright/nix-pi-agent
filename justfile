set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set positional-arguments

tooling_flake := "path:."

default:
    @just --list

# Format tracked Nix files.
fmt:
    nix develop '{{ tooling_flake }}' -c bash -euo pipefail -c 'mapfile -t files < <(rg --files -g "*.nix"); if [[ "${#files[@]}" -eq 0 ]]; then exit 0; fi; nixfmt "${files[@]}"'

# Check Nix formatting only.
fmt-check:
    nix develop '{{ tooling_flake }}' -c bash -euo pipefail -c 'mapfile -t files < <(rg --files -g "*.nix"); if [[ "${#files[@]}" -eq 0 ]]; then exit 0; fi; nixfmt --check "${files[@]}"'

# Run lint checks.
lint: lint-nix lint-shell
    @echo "✅ lint passed"

# Lint Nix configs (statix + deadnix + formatting check).
lint-nix:
    nix develop '{{ tooling_flake }}' -c statix check .
    nix develop '{{ tooling_flake }}' -c bash -euo pipefail -c 'mapfile -t files < <(rg --files -g "*.nix"); if [[ "${#files[@]}" -eq 0 ]]; then exit 0; fi; deadnix --fail --no-underscore "${files[@]}"'
    nix develop '{{ tooling_flake }}' -c bash -euo pipefail -c 'mapfile -t files < <(rg --files -g "*.nix"); if [[ "${#files[@]}" -eq 0 ]]; then exit 0; fi; nixfmt --check "${files[@]}"'

# Lint shell scripts.
lint-shell:
    nix develop '{{ tooling_flake }}' -c shellcheck scripts/*.sh

# Build package.
build:
    nix build -L '{{ tooling_flake }}#pi-agent'

# Run package with forwarded args.
run *args='--help':
    nix run '{{ tooling_flake }}#pi-agent' -- {{ args }}

# Update version/hash pins in package.nix.
update version="":
    if [[ -n "{{ version }}" ]]; then \
      ./scripts/update-package.sh --version "{{ version }}"; \
    else \
      ./scripts/update-package.sh; \
    fi

# Full validation gate.
check: fmt-check lint
    nix flake check --all-systems '{{ tooling_flake }}'
    nix run '{{ tooling_flake }}#pi-agent' -- --version
    @echo "✅ check passed"
