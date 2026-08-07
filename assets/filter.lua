-- summary-filter.lua
-- Transforms fenced divs into native <details> disclosure widgets.
local function make_details(el, css_class, title)
  local blocks = {}
  table.insert(blocks, pandoc.RawBlock('html', '<details class="' .. css_class .. '">\n<summary>' .. title .. '</summary>'))
  for _, block in ipairs(el.content) do
    table.insert(blocks, block)
  end
  table.insert(blocks, pandoc.RawBlock('html', '</details>'))
  return blocks
end

function Div(el)
  if el.classes:includes('details') then
    return make_details(el, 'details', el.attributes['summary'] or 'Summary')
  end
  if el.classes:includes('summary') then
    return make_details(el, 'summary', 'Summary')
  end
end

-- Escape HTML special characters in plain text we inject into raw HTML.
local function escape(s)
  local r = s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
  return r
end

-- Serialize a cell's blocks to HTML, lifting any footnote Notes out into the
-- `notes` list and replacing them with superscript markers.
local function valueToHtml(blocks, notes)
  local html = {}
  local function push(i)
    if i.t == 'Note' then
      local n = #notes + 1
      table.insert(notes, escape(pandoc.utils.stringify(i.content)))
      table.insert(html, '<sup>' .. n .. '</sup>')
    else
      table.insert(html, escape(pandoc.utils.stringify(i)))
    end
  end
  for _, blk in ipairs(blocks) do
    if blk.t == 'Para' or blk.t == 'Plain' then
      for _, i in ipairs(blk.content) do
        push(i)
      end
    end
  end
  return table.concat(html)
end

-- Render the D&D Beyond 4-column stat grid from the authored 2-column table.
-- Rows 1 & 3 are label rows, rows 2 & 4 are value rows. Fields not in
-- `order` (Tags, Classes) are suppressed.
local order = { 'Level', 'Casting Time', 'Range/Area', 'Components', 'Duration', 'School', 'Attack/Save', 'Damage/Effect' }
local rename = { Range = 'Range/Area' }

local function renderStatTable(tbl, notes)
  local body = tbl.bodies and tbl.bodies[1]
  if not body or not body.body then
    return nil
  end
  local map = {}
  for _, row in ipairs(body.body) do
    local c = row.cells
    if c and #c >= 2 then
      local label = pandoc.utils.stringify(c[1]):gsub('^%s+', ''):gsub('%s+$', '')
      map[label] = c[2]
    end
  end

  local labels, vals = {}, {}
  for _, want in ipairs(order) do
    local cell = map[want]
    if not cell then
      for k, v in pairs(rename) do
        if v == want and map[k] then
          cell = map[k]
        end
      end
    end
    if cell then
      labels[#labels + 1] = want
      vals[#vals + 1] = cell
    end
  end
  if #labels ~= 8 then
    return nil
  end

  local function L(i)
    return '<td><strong>' .. labels[i] .. '</strong></td>'
  end
  local function V(i)
    return '<td>' .. valueToHtml(vals[i].contents, notes) .. '</td>'
  end
  local function r4(a, b, c, d)
    return '<tr>' .. a .. b .. c .. d .. '</tr>'
  end

  return '<table><tbody>'
    .. r4(L(1), L(2), L(3), L(4))
    .. r4(V(1), V(2), V(3), V(4))
    .. r4(L(5), L(6), L(7), L(8))
    .. r4(V(5), V(6), V(7), V(8))
    .. '</tbody></table>'
end

-- Wrap each spell in Appendix H into a styled card.
-- Detects the Psychic Spells appendix by its H1, then groups every H2 spell
-- heading and the blocks that follow it (up to the next H2) into a Div.spell.
-- The spell's stat table is rebuilt as the 4-column D&D Beyond grid and any
-- footnote (the material component) is rendered after the description.
function Pandoc(doc)
  local isSpells = false
  for _, blk in ipairs(doc.blocks) do
    if blk.t == 'Header' and blk.level == 1 then
      local text = pandoc.utils.stringify(blk.content)
      isSpells = text:match('^Appendix H') ~= nil
      break
    end
  end
  if not isSpells then
    return nil
  end

  local out = {}
  local current = nil
  local cardNotes = {}

  local function flush()
    if current then
      for i, note in ipairs(cardNotes) do
        table.insert(current, pandoc.RawBlock('html',
          '<p class="spell-footnote"><sup>' .. i .. '</sup> ' .. note .. '</p>'))
      end
      table.insert(out, pandoc.Div(current, pandoc.Attr('', { 'spell' })))
      current = nil
      cardNotes = {}
    end
  end

  for _, blk in ipairs(doc.blocks) do
    if blk.t == 'Header' and blk.level == 2 then
      flush()
      current = { blk }
    elseif current then
      if blk.t == 'Table' then
        local rendered = renderStatTable(blk, cardNotes)
        if rendered then
          table.insert(current, pandoc.RawBlock('html', rendered))
        else
          table.insert(current, blk)
        end
      else
        table.insert(current, blk)
      end
    else
      table.insert(out, blk)
    end
  end
  flush()

  doc.blocks = out
  return doc
end
