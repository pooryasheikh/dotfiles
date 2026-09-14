local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("pkill -f 'vpn_load.sh' 2>/dev/null; $CONFIG_DIR/helpers/event_providers/vpn_load.sh vpn_update 5.0")

local popup_width = 250

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

local vpn_bracket = sbar.add("bracket", "widgets.vpn.bracket", { vpn.name }, {
  background = { color = colors.bg1 },
  popup = { align = "center", height = 30 }
})

sbar.add("item", "widgets.vpn.padding", {
  position = "right",
  width = settings.group_paddings,
})

local status = sbar.add("item", {
  position = "popup." .. vpn_bracket.name,
  icon = {
    font = {
      style = settings.font.style_map["Bold"]
    },
    string = icons.vpn,
  },
  width = popup_width,
  align = "center",
  label = {
    font = {
      size = 15,
      style = settings.font.style_map["Bold"]
    },
    string = "Disconnected",
  },
  background = {
    height = 2,
    color = colors.grey,
    y_offset = -15
  }
})

local iface_item = sbar.add("item", {
  position = "popup." .. vpn_bracket.name,
  icon = {
    align = "left",
    string = "Interface:",
    width = popup_width / 2,
  },
  label = {
    string = "-",
    width = popup_width / 2,
    align = "right",
  }
})

local local_ip_item = sbar.add("item", {
  position = "popup." .. vpn_bracket.name,
  icon = {
    align = "left",
    string = "Local IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local gateway_item = sbar.add("item", {
  position = "popup." .. vpn_bracket.name,
  icon = {
    align = "left",
    string = "Gateway:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local ping_item = sbar.add("item", {
  position = "popup." .. vpn_bracket.name,
  icon = {
    align = "left",
    string = "Ping:",
    width = popup_width / 2,
  },
  label = {
    string = "-",
    width = popup_width / 2,
    align = "right",
  },
})

vpn:subscribe("vpn_update", function(env)
  if env.state == "disconnected" then
    vpn:set({
      icon = { color = colors.grey },
      label = { drawing = false },
    })
    status:set({ label = "Disconnected" })
    iface_item:set({ label = "-" })
    local_ip_item:set({ label = "-" })
    gateway_item:set({ label = "-" })
    ping_item:set({ label = "-" })
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
    status:set({ label = "Connected" })
    iface_item:set({ label = env.iface })
    local_ip_item:set({ label = env.local_ip })
    gateway_item:set({ label = env.gateway })
    ping_item:set({ label = { string = env.ping, color = color } })
  elseif env.state == "timeout" then
    -- VPN interface exists but gateway is unreachable — Pritunl "connected" but broken
    vpn:set({
      icon = { color = colors.red },
      label = { string = "!", color = colors.red, drawing = true },
    })
    status:set({ label = "Connected (unreachable)" })
    iface_item:set({ label = env.iface })
    local_ip_item:set({ label = env.local_ip })
    gateway_item:set({ label = env.gateway })
    ping_item:set({ label = { string = "timeout", color = colors.red } })
  end
end)

local function hide_details()
  vpn_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = vpn_bracket:query().popup.drawing == "off"
  if should_draw then
    vpn_bracket:set({ popup = { drawing = true } })
  else
    hide_details()
  end
end

vpn:subscribe("mouse.clicked", toggle_details)
vpn:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  if label == "-" or label == "" then return end
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

iface_item:subscribe("mouse.clicked", copy_label_to_clipboard)
local_ip_item:subscribe("mouse.clicked", copy_label_to_clipboard)
gateway_item:subscribe("mouse.clicked", copy_label_to_clipboard)
