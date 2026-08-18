local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local popup_width = 250

-- Tracks the interface currently being monitored so we can detect switches
local current_iface = ""

local function start_network_load(iface)
  current_iface = iface
  sbar.exec("killall network_load 2>/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load " .. iface .. " network_update 2.0")
end

-- Detect active default-route interface and start monitoring it
sbar.exec("route get default 2>/dev/null | awk '/interface:/{print $2}'", function(iface)
  iface = iface:gsub("[%s\n]+", "")
  if iface == "" then iface = "en0" end
  start_network_load(iface)
end)

local net_up = sbar.add("item", "widgets.net1", {
  position = "right",
  padding_left = -5,
  width = 0,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.upload,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.red,
    string = "??? Bps",
  },
  y_offset = 4,
})

local net_down = sbar.add("item", "widgets.net2", {
  position = "right",
  padding_left = -5,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.download,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.blue,
    string = "??? Bps",
  },
  y_offset = -4,
})

local net_icon = sbar.add("item", "widgets.net.padding", {
  position = "right",
  label = { drawing = false },
})

local net_bracket = sbar.add("bracket", "widgets.net.bracket", {
  net_icon.name,
  net_up.name,
  net_down.name
}, {
  background = { color = colors.bg1 },
  popup = { align = "center", height = 30 }
})

local ssid = sbar.add("item", {
  position = "popup." .. net_bracket.name,
  icon = {
    font = {
      style = settings.font.style_map["Bold"]
    },
    string = icons.wifi.router,
  },
  width = popup_width,
  align = "center",
  label = {
    font = {
      size = 15,
      style = settings.font.style_map["Bold"]
    },
    max_chars = 18,
    string = "????????????",
  },
  background = {
    height = 2,
    color = colors.grey,
    y_offset = -15
  }
})

local hostname = sbar.add("item", {
  position = "popup." .. net_bracket.name,
  icon = {
    align = "left",
    string = "Hostname:",
    width = popup_width / 2,
  },
  label = {
    max_chars = 20,
    string = "????????????",
    width = popup_width / 2,
    align = "right",
  }
})

local ip = sbar.add("item", {
  position = "popup." .. net_bracket.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local mask = sbar.add("item", {
  position = "popup." .. net_bracket.name,
  icon = {
    align = "left",
    string = "Subnet mask:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  }
})

local router = sbar.add("item", {
  position = "popup." .. net_bracket.name,
  icon = {
    align = "left",
    string = "Router:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
})

sbar.add("item", { position = "right", width = settings.group_paddings })

local function update_net_icon()
  sbar.exec("route get default 2>/dev/null | awk '/interface:/{print $2}'", function(iface)
    iface = iface:gsub("[%s\n]+", "")
    if iface == "" then
      net_icon:set({ icon = { string = icons.wifi.disconnected, color = colors.red } })
      return
    end
    sbar.exec("networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{found=1} found && /Device:/{print $2; exit}'", function(wifi_iface)
      wifi_iface = wifi_iface:gsub("[%s\n]+", "")
      if iface == wifi_iface then
        net_icon:set({ icon = { string = icons.wifi.connected, color = colors.white } })
      else
        net_icon:set({ icon = { string = icons.wifi.lan, color = colors.white } })
      end
    end)
  end)
end

-- Check if the monitored interface is still the active default; restart network_load if not
local function check_iface_switch()
  sbar.exec("route get default 2>/dev/null | awk '/interface:/{print $2}'", function(iface)
    iface = iface:gsub("[%s\n]+", "")
    if iface ~= "" and iface ~= current_iface then
      start_network_load(iface)
    end
    update_net_icon()
  end)
end

local iface_tick = 0

net_up:subscribe("network_update", function(env)
  local up_color = (env.upload == "000 Bps") and colors.grey or colors.red
  local down_color = (env.download == "000 Bps") and colors.grey or colors.blue
  net_up:set({
    icon = { color = up_color },
    label = { string = env.upload, color = up_color }
  })
  net_down:set({
    icon = { color = down_color },
    label = { string = env.download, color = down_color }
  })
  iface_tick = (iface_tick + 1) % 5
  if iface_tick == 0 then
    check_iface_switch()
  end
end)

net_icon:subscribe({"wifi_change", "system_woke"}, function(env)
  check_iface_switch()
end)

local function hide_details()
  net_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = net_bracket:query().popup.drawing == "off"
  if should_draw then
    net_bracket:set({ popup = { drawing = true }})
    sbar.exec("networksetup -getcomputername", function(result)
      hostname:set({ label = result })
    end)
    sbar.exec("route get default 2>/dev/null | awk '/interface:/{print $2}'", function(iface)
      iface = iface:gsub("[%s\n]+", "")
      if iface == "" then return end

      sbar.exec("ipconfig getifaddr " .. iface, function(result)
        ip:set({ label = result })
      end)

      sbar.exec("ipconfig getsummary " .. iface .. " | awk -F ' SSID : ' '/ SSID : /{print $2}'", function(result)
        result = result:gsub("[%s\n]+", "")
        ssid:set({ label = result ~= "" and result or ("Ethernet (" .. iface .. ")") })
      end)

      sbar.exec("networksetup -listallhardwareports | awk '/Hardware Port:/{hp=$0} /Device: " .. iface .. "/{print hp}' | awk -F': ' '{print $2}'", function(service)
        service = service:gsub("^%s*(.-)%s*$", "%1")
        if service == "" then return end
        sbar.exec("networksetup -getinfo '" .. service .. "' | awk -F 'Subnet mask: ' '/^Subnet mask: /{print $2}'", function(result)
          mask:set({ label = result })
        end)
        sbar.exec("networksetup -getinfo '" .. service .. "' | awk -F 'Router: ' '/^Router: /{print $2}'", function(result)
          router:set({ label = result })
        end)
      end)
    end)
  else
    hide_details()
  end
end

net_up:subscribe("mouse.clicked", toggle_details)
net_down:subscribe("mouse.clicked", toggle_details)
net_icon:subscribe("mouse.clicked", toggle_details)
net_icon:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
