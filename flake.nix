{
  description = "Markdown to HTML static site generator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        site = pkgs.callPackage ./package.nix { };
        epub = pkgs.callPackage ./epub.nix { };

        buildEpub = pkgs.writeShellScriptBin "grimstride-build-epub" ''
          set -euo pipefail
          mkdir -p outputs
          install -m 0644 ${epub}/grimstride.epub outputs/grimstride.epub
          echo "Wrote $(pwd)/outputs/grimstride.epub"
        '';
      in
      {
        packages.default = site;
        packages.epub = epub;

        apps.epub = {
          type = "app";
          program = "${buildEpub}/bin/grimstride-build-epub";
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ninja
            pandoc
            zsh
          ];
          shellHook = ''
            mkdir -p "$out"
            ${site.mkBuildNinja {
              inherit (site) buildNinja;
              src = "$PWD";
              out = "$out";
            }}
            export PROMPTPREFIX=grimstride
          '';
        };
      }
    );
}
