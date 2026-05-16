{ lib, uiop }:
let
  css = "ddal.css";
  prefix = "ddal";
  dir = ./.;

  fileToTitle =
    name:
    let
      stem = lib.removeSuffix ".md" name;
      words = lib.splitString "-" stem;
      cap = w: (lib.toUpper (builtins.substring 0 1 w)) + (builtins.substring 1 (builtins.stringLength w - 1) w);
    in
    lib.concatStringsSep " " (map cap words);

  mdNames = builtins.filter (
    n: lib.hasSuffix ".md" n && n != "index-template.md"
  ) (builtins.attrNames (builtins.readDir dir));

  logs = map (n: uiop.mkPageWithTitle { inherit css; } (dir + "/${n}") (fileToTitle n)) mdNames;

  indexPage = uiop.mkIndexPage {
    inherit prefix;
    template = ./index-template.md;
    sections = [
      {
        key = "logs";
        pages = logs;
      }
    ];
    extraAttrs = {
      css = "index.css";
    };
  };

in
[ indexPage ] ++ logs
