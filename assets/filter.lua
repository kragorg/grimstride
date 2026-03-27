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
