-- FGCZ report toolbar: YAML-driven button selection.
--
-- A report using the Quarto extension can select toolbar buttons with:
--
--   fgcz-buttons: search
--   fgcz-buttons: [search, download]
--
-- The toolbar remains opt-in through `include-after-body`. If this key is
-- omitted, an included toolbar shows both buttons.

local valid_names = { "search", "download" }
local valid_lookup = { search = true, download = true }

local function names_from(meta_value)
  local names = {}
  local value_type = pandoc.utils.type(meta_value)
  if value_type == "List" or meta_value.t == "MetaList" then
    for _, value in ipairs(meta_value) do
      names[#names + 1] = pandoc.utils.stringify(value)
    end
  else
    for name in pandoc.utils.stringify(meta_value):gmatch("%S+") do
      names[#names + 1] = name
    end
  end
  return names
end

function Meta(meta)
  local value = meta["fgcz-buttons"]
  if value == nil then
    return nil
  end

  local selected = {}
  local unknown = {}
  for _, name in ipairs(names_from(value)) do
    if valid_lookup[name] then
      selected[name] = true
    elseif not unknown[name] then
      unknown[name] = true
    end
  end

  local unknown_names = {}
  for name, _ in pairs(unknown) do
    unknown_names[#unknown_names + 1] = name
  end
  table.sort(unknown_names)
  if #unknown_names > 0 then
    assert(
      false,
      "Unknown fgcz-buttons value(s): " .. table.concat(unknown_names, ", ") ..
        ". Valid values are: search, download."
    )
  end

  local quoted = {}
  for _, name in ipairs(valid_names) do
    if selected[name] then
      quoted[#quoted + 1] = '"' .. name .. '"'
    end
  end
  if #quoted == 0 then
    return nil
  end

  quarto.doc.include_text(
    "in-header",
    "<script>window.FGCZ_BUTTONS = [" .. table.concat(quoted, ",") .. "];</script>"
  )
  return nil
end
