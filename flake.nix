{
  description = "nix-pi-agent: standalone Nix package for pi-agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs unstable dropped Intel macOS in 26.11; keep that supported
    # platform on the final stable branch that still receives security fixes.
    # Drop x86_64-darwin and this input when nixpkgs 26.05 reaches end of life
    # (end of 2026).
    nixpkgs-darwin-x64.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-darwin-x64,
      flake-utils,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = (if system == "x86_64-darwin" then nixpkgs-darwin-x64 else nixpkgs).legacyPackages.${system};

        piAgent = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          pi-agent = piAgent;
          default = piAgent;
        };

        apps = {
          pi-agent = {
            type = "app";
            program = "${piAgent}/bin/pi";
            meta = {
              description = "Run pi-agent";
            };
          };
          default = {
            type = "app";
            program = "${piAgent}/bin/pi";
            meta = {
              description = "Run pi-agent";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bash
            pkgs.curl
            pkgs.deadnix
            pkgs.gnutar
            pkgs.jq
            pkgs.just
            pkgs.nix
            pkgs.nixfmt
            pkgs.nodejs_22
            pkgs.perl
            pkgs.prefetch-npm-deps
            pkgs.prek
            pkgs.python3
            pkgs.ripgrep
            pkgs.shellcheck
            pkgs.statix
          ];
        };

        formatter = pkgs.nixfmt;
      }
    );
}
