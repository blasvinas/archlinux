-- =============================================================================
-- HYPRLAND LUA CONFIGURATION
-- =============================================================================

-- 1. MONITORS
-- -----------------------------------------------------------------------------
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@59.0000", position = "0x0", scale = 1.00 })
hl.monitor({ output = "eDP-1", mode = "1920x1200@60.03", position = "320x1440", scale = 1.00 })
-- -----------------------------------------------------------------------------

-- 2. ENVIRONMENT VARIABLES
-- -----------------------------------------------------------------------------
hl.env("GTK_THEME", "Dracula")

-- -----------------------------------------------------------------------------
-- 3. CORE SETTINGS (hl.config)
-- -----------------------------------------------------------------------------
hl.config({
	input = {
		kb_layout = "us",
		numlock_by_default = true,
		follow_mouse = 1,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
		sensitivity = 0,
	},

	general = {
		gaps_in = 1,
		gaps_out = 10,
		border_size = 2,

		-- Correct Lua gradient structure
		col = {
			active_border = {
				colors = { "rgba(33ccffee)", "rgba(8f00ffee)" },
				angle = 45,
			},
			inactive_border = {
				colors = { "rgba(595959aa)" },
			},
		},

		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		active_opacity = 0.9, -- Opacity of focused windows
		inactive_opacity = 0.85, -- Transparency for unfocused windows (adjust as needed)
		fullscreen_opacity = 1.0,
		blur = {
			enabled = true,
			size = 5,
			passes = 2,
		},
	},

	animations = {
		enabled = true,
		bezier = {
			myBezier = { 0.05, 0.9, 0.1, 1.05 },
		},
		animation = {
			{ "windows", 1, 7, "myBezier" },
			{ "windowsOut", 1, 7, "default", "popin 80%" },
			{ "border", 1, 10, "default" },
			{ "fade", 1, 7, "default" },
			{ "workspaces", 1, 6, "default" },
		},
	},

	dwindle = {
		preserve_split = true,
	},

	misc = {
		disable_hyprland_logo = true,
	},

	submaps = {
		resize = {
			-- Pass the literal command as a string to dispatcher
			{ key = "right", dispatcher = "resizeactive 10 0", flags = { repeating = true } },
			{ key = "left", dispatcher = "resizeactive -10 0", flags = { repeating = true } },
			{ key = "up", dispatcher = "resizeactive 0 -10", flags = { repeating = true } },
			{ key = "down", dispatcher = "resizeactive 0 10", flags = { repeating = true } },

			-- Escape resets the submap back to global mode
			{ key = "escape", dispatcher = "submap reset" },
		},
	},
})

-- -----------------------------------------------------------------------------
-- 3b. LAYER RULES
-- -----------------------------------------------------------------------------
-- Blur the Quickshell bar (matches WlrLayershell.namespace in Bar.qml).
hl.layer_rule({
	name = "blur-quickshell-bar",
	match = { namespace = "^quickshell-bar$" },
	blur = true,
	ignore_alpha = 0.3, -- blur the pods (alpha 0.5) but not their soft shadows
})

-- Blur behind Quickshell overlays (launcher, dashboard, toasts, ...).
-- ignore_alpha = 0.5 keeps the full-screen dim (alpha 0.4) and drop shadows
-- unblurred, while the glass panels (alpha ~0.8) get frosted.
hl.layer_rule({
	name = "blur-quickshell-overlays",
	match = { namespace = "^quickshell-(launcher|dashboard|notifications|clipboard|powermenu|wallpaper-picker)$" },
	blur = true,
	ignore_alpha = 0.5,
})

-- -----------------------------------------------------------------------------
-- 4. AUTOSTART PROGRAMS (hl.on "hyprland.start")
-- -----------------------------------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("quickshell")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- -----------------------------------------------------------------------------
-- 5. KEYBINDS & SYSTEM ACTIONS (Official 0.55 Specification)
-- -----------------------------------------------------------------------------

-- Application Launchers & Management
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("quickshell ipc call clipboard toggle"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("thunderbird"))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session")) -- hypridle runs lock_cmd (quickshell lock)
hl.bind("SUPER + O", hl.dsp.exec_cmd("libreoffice"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("1password"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + T", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("virt-manager"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("quickshell ipc call wallpaper toggle"))
hl.bind("SUPER + X", hl.dsp.exec_cmd("quickshell ipc call power toggle"))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("quickshell ipc call theme cycle"))
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("quickshell ipc call wallpaper random"))

-- Function Keys
-- hl.bind("SUPER + F1", hl.dsp.exec_cmd("firefox"))

-- Window Focus (Arrows)
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

-- Move Windows
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))

-- System Hardware Binds (Brightness, Volume, Media)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { repeating = true })
hl.bind("code:122", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("code:123", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("code:121", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("code:232", hl.dsp.exec_cmd("brightnessctl -c backlight set 5%-"))
hl.bind("code:233", hl.dsp.exec_cmd("brightnessctl -c backlight set +5%"))
hl.bind("code:172", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("code:171", hl.dsp.exec_cmd("playerctl next"))
hl.bind("code:173", hl.dsp.exec_cmd("playerctl previous"))

-- Screenshots (Using Lua [[ ]] block strings to avoid nested escaping errors)
-- Print: full screen -> file + clipboard | CTRL: region -> clipboard | SHIFT+CTRL: region -> swappy editor | ALT: active window
local shot = [[f="$HOME/Pictures/Screenshots/$(date +%F_%H-%M-%S).png"; mkdir -p "$(dirname "$f")"; ]]
hl.bind("Print", hl.dsp.exec_cmd(shot .. [[grim "$f" && wl-copy < "$f"]]))
hl.bind("CTRL + Print", hl.dsp.exec_cmd(shot .. [[grim -g "$(slurp)" "$f" && wl-copy < "$f"]]))
hl.bind("CTRL + SHIFT + Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind(
	"ALT + Print",
	hl.dsp.exec_cmd(
		shot
			.. [[grim -g "$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$f" && wl-copy < "$f"]]
	)
)

-- Workspace Management (Switching 1-10 via Loop)
for i = 1, 9 do
	hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
	hl.bind("ALT + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
	hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i), follow = false }))
end
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("ALT + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10", follow = false }))

-- Mouse Binds (Scroll & Window Dragging)
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
