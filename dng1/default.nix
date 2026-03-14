{ lib, uiop }:
let
  css = "dng.css";
  prefix = "dng1";

  chapters = uiop.readPagesWithPrefix "Chapters" { inherit css; } ./chapters;
  appendices = uiop.readPages { inherit css; } ./appendices;
  characters = uiop.readPages { inherit css; } ./characters;

  synopsis = uiop.mkPage { inherit css; } ./synopsis.md;

  indexPage = uiop.mkIndexPage {
    inherit prefix;
    template = ./index-template.md;
    sections = [
      {
        heading = "Chapters";
        pages = chapters;
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
[
  indexPage
  synopsis
]
++ chapters
++ appendices
++ characters
