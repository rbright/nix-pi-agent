{
  description = "nix-pi-agent: standalone Nix package for pi-agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
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
            pkgs.ripgrep
            pkgs.shellcheck
            pkgs.statix
          ];
        };

        formatter = pkgs.nixfmt;
      }
    );
}
