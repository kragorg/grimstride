-- summary-filter.lua
-- Transforms a fenced div with class "summary" (:::summary ... :::)
-- into a native <details> disclosure widget.
function Div(el)
  if el.classes:includes('summary') then
    local blocks = {}
    table.insert(blocks, pandoc.RawBlock('html', '<details class="summary">\n<summary>Summary</summary>'))
    for _, block in ipairs(el.content) do
      table.insert(blocks, block)
    end
    table.insert(blocks, pandoc.RawBlock('html', '</details>'))
    return blocks
  end
end
