-- epub-filter.lua: prepare combined markdown for EPUB output.
--
-- 1. Shift every heading down one level so content-page H1 titles nest under
--    area H1s. The exception is H1s carrying class "area-title" — those are
--    the five top-level TOC entries and stay at H1.
-- 2. Drop any heading whose immediately following block is just an HTML
--    comment (e.g. "<!-- INDEX:chapters -->"). These are nav-only labels in
--    HTML site templates and have no visible content in the EPUB.

function Header(el)
  if el.level == 1 and el.classes:includes('area-title') then
    return el
  end
  el.level = math.min(el.level + 1, 6)
  return el
end

function Pandoc(doc)
  local out = {}
  local blocks = doc.blocks
  for i = 1, #blocks do
    local block = blocks[i]
    local skip = false
    if block.t == 'Header' and not block.classes:includes('area-title') then
      local nxt = blocks[i + 1]
      if nxt and nxt.t == 'RawBlock' and nxt.format == 'html'
         and nxt.text:match('^%s*<!%-%-') then
        skip = true
      end
    end
    if not skip then
      table.insert(out, block)
    end
  end
  doc.blocks = out
  return doc
end
