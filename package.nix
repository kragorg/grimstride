# package.nix - The site generator package.
{
  pkgs,
  lib,
  stdenvNoCC,
  writeText,
  linkFarm,
  ninja,
  pandoc,
  runCommand,
  zsh,
}:

let
  uiop = import ./uiop.nix { inherit pkgs; };
  assetExtensions = [ "css" "jpg" "png" "woff2" "zip" ];
  siteareas = [
    ./home
    ./dng1
    ./dng2
    ./wyrmlings
  ];

  pages = uiop.flattenAreas (toString ./.) siteareas;
  assets = uiop.collectAssets assetExtensions (toString ./.) ([ ./assets ] ++ siteareas);

  ninjaContent = uiop.mkNinjaBuildFile {
    buildScript = ./buildPage.zsh;
    shell = "${zsh}/bin/zsh";
    inherit pages assets;
  };

  buildNinja = writeText "build.ninja" ninjaContent;

in
stdenvNoCC.mkDerivation rec {
  name = "site";

  src = ./.;
  dontUnpack = true;

  LC_ALL = "C.UTF-8";
  LANG = "C.UTF-8";

  nativeBuildInputs = [
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

  passthru = { inherit buildNinja; mkBuildNinja = uiop.mkBuildNinja; };
}
