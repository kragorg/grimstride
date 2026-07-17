local title = ""
local summary = {}

function Header(el)
  if el.level == 1 and title == "" then
    title = pandoc.utils.stringify(el.content)
  end
end

function Div(el)
  if el.classes:includes('summary') then
    summary = el.content
  end
end

function Pandoc(doc)
  if title == "" or #summary == 0 then return pandoc.Pandoc({}) end
  local term = {pandoc.Str(title)}
  local def = summary
  return pandoc.Pandoc({pandoc.DefinitionList({ {term, {def}} })})
end
