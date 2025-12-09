{
  pkgs,
  uiop,
}:
let
  inherit (pkgs.lib) flatten;
  config = {
    css = "wyrmlings.css";
    prefix = "wyr";
    site = "Wyrmlings";
    uplink = "wyrmlings.html";
  };
  referencePages = uiop.mkPages uiop.titleIdentity config ./ref;
  header = builtins.readFile ./index.md;
  index = pkgs.writeText (uiop.replaceExtension config.uplink "md") ''
    ${header}

    ${uiop.mkIndexEntries referencePages}
  '';
in
flatten [
  rec {
    name = "wyrmlings";
    source = index;
    title = uiop.readTitle source;
    css = "index.css";
  }
  rec {
    inherit (config) prefix site uplink;
    css = "dng.css";
    name = "kragor-and-rime-flake";
    source = builtins.path {
      path = ./. + "/Kragor and Rime-flake.md";
      name = "${name}.md";
    };
    title = uiop.readTitle source;
  }
  rec {
    inherit (config) prefix site uplink;
    name = "can-a-hatchling-speak";
    source = builtins.path {
      path = ./. + "/Can a hatchling speak?.md";
      name = "${name}.md";
    };
    title = uiop.readTitle source;
  }
  rec {
    inherit (config) prefix site uplink;
    name = "the-tutoring-plan";
    source = builtins.path {
      path = ./. + "/The Tutoring Plan.md";
      name = "${name}.md";
    };
    title = uiop.readTitle source;
  }
  referencePages
]
