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
  findExtensionsExpression = extensions:
    lib.concatMapStringsSep " -o " (ext: ''-iname "*.${ext}"'') extensions;
  siteareas = [
    ./home
    ./dng1
    ./dng2
    ./wyrmlings
  ];

  pages = uiop.flattenAreas (toString ./.) siteareas;

  ninjaContent = uiop.mkNinjaBuildFile {
    buildScript = ./buildPage.zsh;
    shell = "${zsh}/bin/zsh";
    inherit pages;
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
      links = (map pageLink pages) ++ [
        { name = "build.ninja"; path = ninjaFile; }
      ];
    in
    linkFarm "site-env" links;

  copyAssets = src: ''
    find "${src}" -type f                                \
      \( ${findExtensionsExpression assetExtensions} \)  \
      -print0                                            \
      | xargs -0 -I % cp --remove-destination % "$out/"
  '';

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
    ${copyAssets src}
    { printf 'src = %s\nout = %s\nbuilddir = %s\n' "${env}" "$out" "$PWD"; cat ${env}/build.ninja; } > build.ninja
    ninja -C ${env} -f "$PWD/build.ninja" -v
  '';

  dontInstall = true;

  passthru = { inherit copyAssets env; };
}
