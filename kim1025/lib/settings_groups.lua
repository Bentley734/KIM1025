-- Four controls fit on one native page; no feature submenus are needed.
return function(mod)
  local api = {}
  function api.apply(state, source, kind)
    local field = kind == "list" and "items" or "optionRows"
    local rows = {}
    for _, row in ipairs(source) do rows[#rows+1] = row end
    if kind == "list" then rows[#rows+1] = {id="kim1025:cancel",label="CANCEL",cancel=true} end
    state[field] = rows
    state._kimSettingsNavigation = state._kimSettingsNavigation or {parents={}}
    return rows
  end
  function api.back() return false end
  mod._kimSettingsGroups = api
  return api
end
