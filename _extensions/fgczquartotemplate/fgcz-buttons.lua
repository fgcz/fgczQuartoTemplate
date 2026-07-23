-- FGCZ report features: YAML-driven configuration.
--
-- A report using the Quarto extension can select toolbar buttons with:
--
--   fgcz-buttons: search
--   fgcz-buttons: [search, download]
--
-- The toolbar remains opt-in through `include-after-body`. If this key is
-- omitted, an included toolbar shows both buttons.
--
-- It can also switch on the two optional tab features, both off by default:
--
--   fgcz-colour: true   per-nesting-level tab palette (see fgcz.scss)
--   fgcz-number: true   hierarchical tab numbers 1, 1.1, 1.1.1 …
--
-- Those two are applied as classes on <html>, which the always-included header
-- (fgcz_header_quarto.html) and fgcz.scss react to. The R helper reaches the
-- same classes by patching the header instead -- see .fgcz_set_header_flags().

local valid_names = { "search", "download" }
local valid_lookup = { search = true, download = true }

-- Boolean feature keys → the class each one adds to <html>.
local flag_keys = {
  { key = "fgcz-colour", class = "fgcz-colour" },
  { key = "fgcz-number", class = "fgcz-number" },
}

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

-- YAML `true` arrives as a Lua boolean; accept the common string spellings too
-- so `fgcz-colour: "true"` behaves the way an author would expect.
local function is_true(meta_value)
  if meta_value == nil then
    return false
  end
  if type(meta_value) == "boolean" then
    return meta_value
  end
  local text = pandoc.utils.stringify(meta_value):lower()
  return text == "true" or text == "yes" or text == "1"
end

-- Add a class to <html> for each feature the report switched on. Injected as a
-- header include, which Quarto emits ahead of the report body -- so the class is
-- in place before the first tabset is parsed and the colour layer never flashes
-- uncoloured. It does NOT beat the numbering script, which is why that script
-- tests for its flag inside its DOMContentLoaded handler rather than up front.
local function apply_flags(meta)
  local classes = {}
  for _, flag in ipairs(flag_keys) do
    if is_true(meta[flag.key]) then
      classes[#classes + 1] = '"' .. flag.class .. '"'
    end
  end
  if #classes == 0 then
    return
  end
  quarto.doc.include_text(
    "in-header",
    "<script>document.documentElement.classList.add(" ..
      table.concat(classes, ",") .. ");</script>"
  )
end

local function apply_buttons(meta)
  local value = meta["fgcz-buttons"]
  if value == nil then
    return
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
    return
  end

  quarto.doc.include_text(
    "in-header",
    "<script>window.FGCZ_BUTTONS = [" .. table.concat(quoted, ",") .. "];</script>"
  )
end

function Meta(meta)
  apply_flags(meta)
  apply_buttons(meta)
  return nil
end
