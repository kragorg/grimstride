# epub.nix - Package all Markdown sources as a single EPUB.
# Does not depend on the HTML site build.
{
  pkgs,
  lib,
  stdenvNoCC,
  pandoc,
  writeText,
}:

let
  uiop = import ./uiop.nix { inherit pkgs; };

  siteareas = [
    ./home
    ./dng1
    ./dng2
    ./wyrmlings
    ./wildshape
    ./ddal
  ];

  allPages = uiop.flattenAreas (toString ./.) siteareas;

  # Skip home/ — navigation hub; cover image already represents it.
  epubPages = builtins.filter (p: (p.prefix or null) != null) allPages;

  # Index pages use the raw template (epubSource) whose H1 carries {.area-title};
  # all other pages use their normal source.
  pageSource = p: if p ? epubSource then p.epubSource else p.source;

  sourcesArg = lib.concatMapStringsSep " " (p: lib.escapeShellArg "${pageSource p}") epubPages;

  # Recursively walk a source directory and return relative subdirectory paths
  # (including "" for the directory itself).
  walkSrcDirs = srcPath:
    let
      entries = builtins.readDir srcPath;
      subdirs = lib.attrNames (lib.filterAttrs (_: t: t == "directory") entries);
      childRels = lib.concatLists (map (name:
        map (rel: if rel == "" then name else "${name}/${rel}")
          (walkSrcDirs (srcPath + "/${name}"))
      ) subdirs);
    in [ "" ] ++ childRels;

  # Bring each area directory into the store and expose every subdirectory in
  # the resource path so pandoc can find images that live in subdirectories
  # like dng1/chapters/ or dng2/sessions/.
  areaResourceDirs = area:
    let
      store = toString (builtins.path { path = area; name = builtins.baseNameOf (toString area); });
      rels = walkSrcDirs area;
    in map (rel: if rel == "" then store else "${store}/${rel}") rels;

  resourcePath = lib.concatStringsSep ":" (lib.concatMap areaResourceDirs siteareas);

  metadata = writeText "epub-metadata.yaml" ''
    ---
    title: Grimstride
    creator:
      - role: author
        text: Kragor Grimstride
    language: en-US
    ...
  '';

  coverImage = ./home/kragor_eldritch_portrait.png;
in
stdenvNoCC.mkDerivation {
  name = "grimstride-epub";
  dontUnpack = true;

  LC_ALL = "C.UTF-8";
  LANG = "C.UTF-8";

  nativeBuildInputs = [ pandoc ];

  buildPhase = ''
    mkdir -p "$out"
    pandoc \
      --from=markdown \
      --to=epub \
      --toc \
      --toc-depth=2 \
      --lua-filter=${./assets/epub-filter.lua} \
      --metadata-file=${metadata} \
      --epub-cover-image=${coverImage} \
      --resource-path=${lib.escapeShellArg resourcePath} \
      --output="$out/grimstride.epub" \
      ${sourcesArg}
  '';

  dontInstall = true;
}
