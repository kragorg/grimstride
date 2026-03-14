{ lib, uiop }:
let
  css = "wyrmlings.css";
  prefix = "wyrmlings";

  pages = uiop.readPages { inherit css; } ./pages;
  references = uiop.readPages { inherit css; } ./ref;

  indexPage = uiop.mkIndexPage {
    inherit prefix;
    template = ./index-template.md;
    sections = [
      {
        key = "main";
        inherit pages;
      }
      {
        key = "ref";
        pages = references;
      }
    ];
    extraAttrs = {
      css = "index.css";
    };
  };

in
[ indexPage ] ++ pages ++ references
