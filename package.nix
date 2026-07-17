# package.nix - The site generator package.
{
  pkgs,
  lib,
  stdenvNoCC,
  writeText,
  linkFarm,
  gnused,
  ninja,
  pandoc,
  runCommand,
  zsh,
}:

let
  uiop = import ./uiop.nix { inherit pkgs; };
  assetExtensions = [
    "css"
    "jpg"
    "png"
    "txt"
    "woff2"
    "zip"
  ];
  siteareas = [
    ./home
    ./dng1
    ./dng2
    ./wyrmlings
    ./wildshape
    ./ddal
  ];

  pages = uiop.flattenAreas (toString ./.) siteareas;
  assets = uiop.collectAssets assetExtensions (toString ./.) ([ ./assets ] ++ siteareas);

  ninjaContent =
    uiop.mkNinjaBuildFile {
      buildScript = ./buildPage.zsh;
      shell = "${zsh}/bin/zsh";
      inherit pages assets;
    }
    + (
      let
        title = "Session Summaries";
      in
      ''

        rule extract_summaries
          command = (printf "# ${title}\n\n" && for f in $in; do pandoc --lua-filter=''${src}/scripts/extract-summary.lua $$f -t markdown; printf "\n"; done) > $out
          description = Extracting summaries

        build ''${builddir}/dng2--summaries.md: extract_summaries ${
          lib.concatMapStringsSep " " (n: "\${src}/dng2/sessions/${n}") (
            builtins.filter (n: lib.hasSuffix ".md" n) (builtins.attrNames (builtins.readDir ./dng2/sessions))
          )
        }
      ''
    );

  buildNinja = writeText "build.ninja" ninjaContent;

in
stdenvNoCC.mkDerivation rec {
  name = "site";

  src = ./.;
  dontUnpack = true;

  LC_ALL = "C.UTF-8";
  LANG = "C.UTF-8";

  nativeBuildInputs = [
    gnused
    ninja
    pandoc
    zsh
  ];

  buildPhase = ''
    mkdir -p "$out"
    ${uiop.mkBuildNinja {
      inherit buildNinja src;
      builddir = "$PWD";
      out = "$out";
    }}
    ninja -C "${src}" -f "$PWD/build.ninja" -v
  '';

  dontInstall = true;

  passthru = {
    inherit buildNinja;
    mkBuildNinja = uiop.mkBuildNinja;
  };
}
