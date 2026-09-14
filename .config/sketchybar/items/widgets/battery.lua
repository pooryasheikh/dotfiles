local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local CAFFEINATE_PATTERN = "caffeinate -i -d"

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 19.0,
    }
  },
  label = { font = { family = settings.font.numbers } },
  update_freq = 180,
  popup = { align = "center" }
})

local remaining_time = sbar.add("item", {
  position = "popup." .. battery.name,
  icon = {
    string = "Time remaining:",
    width = 100,
    align = "left"
  },
  label = {
    string = "??:??h",
    width = 100,
    align = "right"
  },
})


local caffeinated = false

local function update_battery()
  sbar.exec("pmset -g batt", function(batt_info)
    local icon = "!"
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. "%"
    end

    local color = colors.green
    local charging, _, _ = batt_info:find("AC Power")

    if charging then
      icon = icons.battery.charging
    else
      if found and charge > 80 then
        icon = icons.battery._100
      elseif found and charge > 60 then
        icon = icons.battery._75
      elseif found and charge > 40 then
        icon = icons.battery._50
      elseif found and charge > 20 then
        icon = icons.battery._25
        color = colors.orange
      else
        icon = icons.battery._0
        color = colors.red
      end
    end

    -- caffeinate active (idle/display sleep prevented) takes over the color
    -- so it's obvious at a glance regardless of charge level
    if caffeinated then
      color = colors.magenta
    end

    local lead = ""
    if found and charge < 10 then
      lead = "0"
    end

    battery:set({
      icon = {
        string = icon,
        color = color
      },
      label = { string = lead .. label },
    })
  end)
end

battery:subscribe({"routine", "power_source_change", "system_woke"}, update_battery)

-- Pick up a caffeinate process already running (e.g. left over from before a
-- sketchybar reload) so the indicator matches reality instead of resetting.
sbar.exec("pgrep -f '" .. CAFFEINATE_PATTERN .. "' >/dev/null 2>&1 && echo 1 || echo 0", function(result)
  caffeinated = result:gsub("%s+", "") == "1"
  update_battery()
end)

local function toggle_caffeinate()
  if caffeinated then
    sbar.exec("pkill -f '" .. CAFFEINATE_PATTERN .. "'")
  else
    sbar.exec("caffeinate -i -d")
  end
  caffeinated = not caffeinated
  update_battery()
end

battery:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    toggle_caffeinate()
    return
  end

  local drawing = battery:query().popup.drawing
  battery:set( { popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec("pmset -g batt", function(batt_info)
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = found and remaining .. "h" or "No estimate"
      remaining_time:set( { label = label })
    end)
  end
end)

sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.battery.padding", {
  position = "right",
  width = settings.group_paddings
})
