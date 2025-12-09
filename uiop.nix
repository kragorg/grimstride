{
  pkgs,
}:
let
  inherit (pkgs.lib)
    concatMapStringsSep
    flatten
    imap0
    isString
    optionalAttrs
    pipe
    sort
    toLower
    trim
    ;
  inherit (pkgs.lib.strings) sanitizeDerivationName;
  src = ./.;
  env = pkgs.symlinkJoin {
    name = "grimstride-buildpage-env";
    paths = [
      pkgs.coreutils
      pkgs.pandoc
      pkgs.zsh
    ];
  };
in
rec {

  readTitle =
    path:
    let
      template = builtins.toFile "title-template.txt" "$title$";
      result = pkgs.runCommand "readTitle" { } ''
        ${pkgs.pandoc}/bin/pandoc \
          --template=${template} \
          --shift-heading-level-by=-1 \
          --from=markdown \
          --to=plain \
          "${path}" > "$out"
      '';
    in
    trim (builtins.readFile result);

  title2name =
    title:
    pipe title [
      toLower
      sanitizeDerivationName
    ];

  replaceExtension =
    filename: ext:
    let
      m = builtins.match "(.*)\\..*" filename;
      base = if m == null then filename else builtins.head m;
    in
    "${base}.${ext}";

  listFiles =
    dir:
    pipe dir [
      builtins.readDir
      builtins.attrNames
      (ls: sort (a: b: a < b) ls)
      (map (fname: "${dir}/${fname}"))
    ];

  listMarkdown =
    dir:
    pipe dir [
      listFiles
      (builtins.filter (fname: builtins.match ".*\\.md$" fname != null))
    ];

  skipIndexMarkdown = builtins.filter (fname: builtins.baseNameOf fname != "index.md");

  sources2pages =
    {
      css ? null,
      prefix,
      site,
      uplink,
      ...
    }:
    map (
      source:
      rec {
        inherit
          prefix
          site
          source
          uplink
          ;
      }
      // optionalAttrs (css != null) { inherit css; }
    );

  readTitles = map (page: page // { title = readTitle page.source; });

  xformTitles = xform: imap0 (i: page: page // { title = xform i page.title; });

  titles2names = map (page: page // { name = title2name page.title; });

  titleCondPrefix =
    fn: i: title:
    if i > 0 then "${fn i}${title}" else title;

  titleIdentity = _: title: title;

  mkPages =
    title-xform: attrs: directory:
    let
      retitle = i: page: page // { title = title-xform i page.title; };
    in
    pipe directory [
      listMarkdown
      skipIndexMarkdown
      (sources2pages attrs)
      readTitles
      (imap0 retitle)
      titles2names
    ];

  mkIndexEntries =
    pages:
    concatMapStringsSep "\n" (page: "- [${page.title}](${page.prefix}--${page.name}.html)") (
      flatten pages
    );

  buildPage =
    {
      css ? "main.css",
      homelink ? true,
      name,
      prefix ? null,
      site ? "",
      source,
      title,
      uplink ? false,
    }:
    let
      prefixedName = if prefix == null then name else "${prefix}--${name}";
      include = pkgs.writeText "header" ''
        <nav class="nav">
          ${
            if (isString uplink) then
              ''
                <a class="up" data-tooltip="Up" href="${uplink}"></a>
              ''
            else
              ""
          }
          ${
            if homelink then
              ''
                <a class="home" data-tooltip="Home" href="index.html"></a>
              ''
            else
              ""
          }
        </nav>
      '';
    in
    derivation {
      inherit
        css
        include
        site
        source
        title
        ;
      name = prefixedName;
      filename = "${prefixedName}.html";

      PATH = "${env}/bin";
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";

      args = [
        "--no_global_rcs"
        "--no_rcs"
        ./buildPage.zsh
        source
      ];
      builder = "${pkgs.zsh}/bin/zsh";
      system = pkgs.stdenv.hostPlatform.system;
    };

  buildSite =
    {
      name,
      pages ? [ ],
    }:
    let
      env = pkgs.symlinkJoin {
        name = "${name}-env";
        paths = map buildPage (flatten pages);
      };
    in
    pkgs.runCommand name { } ''
      mkdir -p $out
      cp -RH ${env}/* $out
      cd ${src}
      ${pkgs.fd}/bin/fd -e css -e jpg -e png -e woff2 -e zip -X cp {} $out
    '';

}
