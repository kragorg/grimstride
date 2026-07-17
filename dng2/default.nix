{ lib, uiop }:
let
  css = "dng.css";
  prefix = "dng2";

  summariesPage = {
    name = "summaries";
    title = "Session Summaries";
    source = "dng2--summaries.md";
    css = "dng.css";
    isGenerated = true;
  };

  rawSessions = uiop.readPagesWithPrefix "Session" { inherit css; } ./sessions;
  sessions = [ summariesPage ] ++ rawSessions;

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
