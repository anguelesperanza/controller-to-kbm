package main

/*
	CONFIG -- Data structures and procedures
	========================================
	This file holds all the structs and procedures and other
	config related pieces of code.

	The config file is a .ini file as it's really simple and easy to look at.
	Each game will have its own .ini file and that will be loaded in when it's time to switch games.

	The following are the keywords used in the .ini
	===============================================
	A-Z:         Maps to the corresponding VK (must be uppercase)
	0-9:         Maps to the corresponding VK
	TAB          -> VK_TAB
	SPACE        -> VK_SPACE
	LSHIFT       -> VK_LSHIFT
	LCONTROL     -> VK_LCONTROL
	LALT         -> VK_LMENU
	RALT         -> VK_RMENU
	ESCAPE       -> VK_ESCAPE
	left_click   -> Left mouse button
	right_click  -> Right mouse button
	num_up       -> Increment scroll index (number row)
	num_down     -> Decrement scroll index (number row)
*/

import "core:fmt"
import "core:os/os2"
import "core:strconv"
import "core:encoding/ini"
import win "core:sys/windows"


ButtonType :: enum {
	KEY,
	MOUSE_BUTTON,
	SCROLL_UP,
	SCROLL_DOWN,
}

Button :: struct {
	pressed:       bool,
	type:          ButtonType,
	key:           win.WORD,
	mouse_button:  win.DWORD,
	mouse_release: win.DWORD,
}

Controller :: struct {
	// dpad
	dpad_up:    Button,
	dpad_down:  Button,
	dpad_left:  Button,
	dpad_right: Button,

	// face buttons
	face_up:    Button,
	face_down:  Button,
	face_left:  Button,
	face_right: Button,

	// bumpers
	left_bumper:  Button,
	right_bumper: Button,

	// left thumbstick
	left_thumb_up:    Button,
	left_thumb_down:  Button,
	left_thumb_left:  Button,
	left_thumb_right: Button,
	left_thumb_click: Button,

	// right thumbstick
	right_thumb_click: Button,

	// Start / Select
	start:  Button,
	select: Button,
}

Config :: struct {
	controller:        Controller,
	smoothing:         f32,
	curve:             f32,
	max_accel:         f32,
	accel_buildup:     f32,
	ymult:             f32,
	sensitivity:       f32,
	pause_sensitivity: f32,
	left_deadzone:     f64,
	right_deadzone:    f64,
}


config_to_button :: proc(value: string) -> Button {
	button: Button

	switch value {
	case "TAB":
		button.type = .KEY
		button.key  = win.VK_TAB
	case "SPACE":
		button.type = .KEY
		button.key  = win.VK_SPACE
	case "LSHIFT":
		button.type = .KEY
		button.key  = win.VK_LSHIFT
	case "LCONTROL":
		button.type = .KEY
		button.key  = win.VK_LCONTROL
	case "LALT":
		button.type = .KEY
		button.key  = win.VK_LMENU
	case "RALT":
		button.type = .KEY
		button.key  = win.VK_RMENU
	case "ESCAPE":
		button.type = .KEY
		button.key  = win.VK_ESCAPE
	case "num_up":
		button.type = .SCROLL_UP
	case "num_down":
		button.type = .SCROLL_DOWN
	case "middle_mouse":
		button.type = .MOUSE_BUTTON
		button.mouse_button  = win.MOUSEEVENTF_MIDDLEDOWN
		button.mouse_release  = win.MOUSEEVENTF_MIDDLEUP
		
	case "right_click":
		button.type          = .MOUSE_BUTTON
		button.mouse_button  = win.MOUSEEVENTF_RIGHTDOWN
		button.mouse_release = win.MOUSEEVENTF_RIGHTUP
	case "left_click":
		button.type          = .MOUSE_BUTTON
		button.mouse_button  = win.MOUSEEVENTF_LEFTDOWN
		button.mouse_release = win.MOUSEEVENTF_LEFTUP
	case:
		// Single letter A-Z or digit 0-9
		if len(value) == 1 {
			c := value[0]
			if (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') {
				button.type = .KEY
				button.key  = cast(win.WORD)c
			}
		}
	}

	return button
}


load_default_config :: proc() -> Config {
	config: Config

	// dpad
	config.controller.dpad_up.type    = .KEY
	config.controller.dpad_up.key     = win.VK_Z
	config.controller.dpad_down.type  = .KEY
	config.controller.dpad_down.key   = win.VK_0
	config.controller.dpad_left.type  = .SCROLL_DOWN
	config.controller.dpad_right.type = .SCROLL_UP

	// face buttons (Y/Triangle, A/Cross, X/Square, B/Circle)
	config.controller.face_up.type    = .KEY
	config.controller.face_up.key     = win.VK_TAB
	config.controller.face_down.type  = .KEY
	config.controller.face_down.key   = win.VK_SPACE
	config.controller.face_left.type  = .KEY
	config.controller.face_left.key   = win.VK_F
	config.controller.face_right.type = .KEY
	config.controller.face_right.key  = win.VK_LCONTROL

	// bumpers
	config.controller.left_bumper.type          = .MOUSE_BUTTON
	config.controller.left_bumper.mouse_button  = win.MOUSEEVENTF_RIGHTDOWN
	config.controller.left_bumper.mouse_release = win.MOUSEEVENTF_RIGHTUP
	config.controller.right_bumper.type          = .MOUSE_BUTTON
	config.controller.right_bumper.mouse_button  = win.MOUSEEVENTF_LEFTDOWN
	config.controller.right_bumper.mouse_release = win.MOUSEEVENTF_LEFTUP

	// left thumbstick
	config.controller.left_thumb_up.type    = .KEY
	config.controller.left_thumb_up.key     = win.VK_W
	config.controller.left_thumb_down.type  = .KEY
	config.controller.left_thumb_down.key   = win.VK_S
	config.controller.left_thumb_left.type  = .KEY
	config.controller.left_thumb_left.key   = win.VK_A
	config.controller.left_thumb_right.type = .KEY
	config.controller.left_thumb_right.key  = win.VK_D
	config.controller.left_thumb_click.type = .KEY
	config.controller.left_thumb_click.key  = win.VK_LSHIFT

	// start / select
	config.controller.start.type  = .KEY
	config.controller.start.key   = win.VK_ESCAPE
	config.controller.select.type = .KEY
	config.controller.select.key  = win.VK_M

	config.smoothing         = 0.18
	config.curve             = 1.0
	config.max_accel         = 0.5
	config.accel_buildup     = 0.04
	config.ymult             = 0.85
	config.sensitivity       = 2.0
	config.pause_sensitivity = 0.05
	config.left_deadzone     = 7849.0
	config.right_deadzone    = 0.06

	return config
}


load_config :: proc(path: string) -> Config {
	data, error := os2.read_entire_file_from_path(path, context.allocator)
	if error != nil {
		fmt.eprintf("Could not load config due to error: %v\n", error)
		os2.exit(0)
	}

	m, err := ini.load_map_from_string(string(data), context.allocator)
	if err != nil {
		fmt.eprintf("Could not parse config due to error: %v\n", err)
		os2.exit(0)
	}

	delete(data, context.allocator)

	config: Config

	// Settings
	config.smoothing,         _ = strconv.parse_f32(m["settings"]["smoothing"])
	config.curve,             _ = strconv.parse_f32(m["settings"]["curve"])
	config.max_accel,         _ = strconv.parse_f32(m["settings"]["max_accel"])
	config.accel_buildup,     _ = strconv.parse_f32(m["settings"]["accel_buildup"])
	config.ymult,             _ = strconv.parse_f32(m["settings"]["ymult"])
	config.sensitivity,       _ = strconv.parse_f32(m["settings"]["sensitivity"])
	config.pause_sensitivity, _ = strconv.parse_f32(m["settings"]["pause_sensitivity"])
	config.left_deadzone,     _ = strconv.parse_f64(m["settings"]["left_deadzone"])
	config.right_deadzone,    _ = strconv.parse_f64(m["settings"]["right_deadzone"])

	// Face buttons
	config.controller.face_up    = config_to_button(m["buttons"]["face_up"])
	config.controller.face_down  = config_to_button(m["buttons"]["face_down"])
	config.controller.face_left  = config_to_button(m["buttons"]["face_left"])
	config.controller.face_right = config_to_button(m["buttons"]["face_right"])

	// D-pad
	config.controller.dpad_up    = config_to_button(m["buttons"]["dpad_up"])
	config.controller.dpad_down  = config_to_button(m["buttons"]["dpad_down"])
	config.controller.dpad_left  = config_to_button(m["buttons"]["dpad_left"])
	config.controller.dpad_right = config_to_button(m["buttons"]["dpad_right"])

	// Bumpers
	config.controller.left_bumper  = config_to_button(m["buttons"]["left_bumper"])
	config.controller.right_bumper = config_to_button(m["buttons"]["right_bumper"])

	// Left thumbstick
	config.controller.left_thumb_up    = config_to_button(m["buttons"]["left_thumb_up"])
	config.controller.left_thumb_down  = config_to_button(m["buttons"]["left_thumb_down"])
	config.controller.left_thumb_left  = config_to_button(m["buttons"]["left_thumb_left"])
	config.controller.left_thumb_right = config_to_button(m["buttons"]["left_thumb_right"])
	config.controller.left_thumb_click = config_to_button(m["buttons"]["left_thumb_click"])

	config.controller.right_thumb_click = config_to_button(m["buttons"]["right_thumb_click"])

	// Start / Select
	config.controller.start  = config_to_button(m["buttons"]["start"])
	config.controller.select = config_to_button(m["buttons"]["select"])

	return config
}
