{ lib, uiop }:
let
  css = "dng.css";
  prefix = "dng2";

  sessions = uiop.readPagesWithPrefix "Session" { inherit css; } ./sessions;
  appendices = uiop.readPages { inherit css; } ./appendices;
  characters = uiop.readPages { inherit css; } ./characters;

  indexPage = uiop.mkIndexPage {
    inherit prefix;
    template = ./index-template.md;
    sections = [
      {
        heading = "Sessions";
        pages = sessions;
      }
      {
        heading = "Appendices";
        pages = appendices;
      }
      {
        heading = "Characters";
        pages = characters;
      }
    ];
    extraAttrs = {
      css = "index.css";
    };
  };

in
[ indexPage ] ++ sessions ++ appendices ++ characters
