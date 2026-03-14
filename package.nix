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

  ninjaFile = writeText "build.ninja" ninjaContent;

  env =
    let
      pageLink = p:
        if p ? srcRelPath then
          { name = p.srcRelPath; path = "${p.source}"; }
        else
          {
            name = builtins.unsafeDiscardStringContext "generated/${builtins.baseNameOf "${p.source}"}";
            path = "${p.source}";
          };
      assetLink = a: { name = a.srcRelPath; path = "${a.source}"; };
      links = (map pageLink pages) ++ (map assetLink assets) ++ [
        { name = "build.ninja"; path = ninjaFile; }
      ];
    in
    linkFarm "site-env" links;

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
      inherit env;
      builddir = "$PWD";
      src = "${env}";
      out = "$out";
    }}
    ninja -C ${env} -f "$PWD/build.ninja" -v
  '';

  dontInstall = true;

  passthru = { inherit env; mkBuildNinja = uiop.mkBuildNinja; };
}
