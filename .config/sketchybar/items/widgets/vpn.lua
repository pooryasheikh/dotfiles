local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("pkill -f 'vpn_load.sh' 2>/dev/null; $CONFIG_DIR/helpers/event_providers/vpn_load.sh vpn_update 5.0")

local vpn = sbar.add("item", "widgets.vpn", {
  position = "right",
  icon = {
    string = icons.vpn,
    color = colors.grey,
    font = {
      style = settings.font.style_map["Bold"],
      size = 14.0,
    },
  },
  label = {
    string = "off",
    color = colors.grey,
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    drawing = false,
  },
  padding_right = settings.paddings + 4,
})

vpn:subscribe("vpn_update", function(env)
  if env.state == "disconnected" then
    vpn:set({
      icon = { color = colors.grey },
      label = { drawing = false },
    })
  elseif env.state == "connected" then
    local ping = tonumber(env.ping:match("%d+")) or 0
    local color = colors.green
    if ping > 200 then
      color = colors.red
    elseif ping > 80 then
      color = colors.yellow
    end
    vpn:set({
      icon = { color = color },
      label = { string = env.ping, color = color, drawing = true },
    })
  elseif env.state == "timeout" then
    -- VPN interface exists but gateway is unreachable — Pritunl "connected" but broken
    vpn:set({
      icon = { color = colors.red },
      label = { string = "!", color = colors.red, drawing = true },
    })
  end
end)

sbar.add("bracket", "widgets.vpn.bracket", { vpn.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.vpn.padding", {
  position = "right",
  width = settings.group_paddings,
})
