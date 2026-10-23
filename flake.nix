{
  description = "nix-pi-agent: standalone Nix package for pi-agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # eMudhra CA compromise (https://emudhra.we-have-a-problem.com/): the locked
    # nixos-unstable does not have the patched Node.js 22.23.4. This master
    # revision has it in cache.nixos.org. Only nodejs_22 comes from it. Remove
    # this input once nixos-unstable has Node.js 22.23.4 or later.
    nixpkgs-master.url = "github:NixOS/nixpkgs/75ba83324cc35b3e156ac46ee379f38e8f0b1808";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-master,
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
        pkgs = import nixpkgs { inherit system; };

        # Nixpkgs master dropped x86_64-darwin, so that system keeps the
        # nodejs_22 of the locked nixpkgs.
        nodejs_22 =
          if system == "x86_64-darwin" then
            pkgs.nodejs_22
          else
            nixpkgs-master.legacyPackages.${system}.nodejs_22;

        piAgent = pkgs.callPackage ./package.nix { inherit nodejs_22; };
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
            nodejs_22
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
