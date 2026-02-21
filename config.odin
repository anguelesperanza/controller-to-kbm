package main

/*
	CONFIG -- Data structures and procedures
	========================================
	This file holds all the structs and procedures and other
	config releated pieces of code.

	the config file is a .ini file as it's really simple and easy to look at
	Each game will have it's own .ini file and that will be loaded in when it's time to swtich games.

	The following are the keywords used in the .ini
	===============================================
	A-Z: will map to corresponding VK
		A: VK_A
		Needs to be caps

	 0-9: Will map to corresponding VK
	 	0: VK-0

	TAB -> VK_TAB
	
	num_down and num_up:
		These are the number row (0 ..= 9)
		the value: scroll_index is used to decide which number on the number row the button is active for
		num_up will increment scroll_index by 1
		num_down will decreement scroll_index by 1
*/

import "core:fmt"
import "core:os/os2"
import "core:strconv"
import "core:strings"
import "core:encoding/ini"
import win "core:sys/windows"


Config :: struct {
	controller:Controller,
	smoothing:f32,
	curve:f32,
	max_accel: f32,
	accel_buildup: f32,
	ymult: f32,
	sensitivity: f32, // Mouse movement inside of game
	pause_sensitivity: f32, // Mouse movement inside of pause menue
	left_deadzone:f64,
	right_deadzone:f64,
}


get_scroll_index :: proc(direction: Direction) -> win.WORD {
	switch direction {
	case .LEFT:
		scroll_index -= 1
		if scroll_index < 1 do scroll_index = 9
	case .RIGHT:
		scroll_index += 1
		if scroll_index > 9 do scroll_index = 1
	}

	keys := [10]win.WORD{
 		win.VK_0, win.VK_1, win.VK_2, win.VK_3, win.VK_4,
		win.VK_5, win.VK_6, win.VK_7, win.VK_8, win.VK_9,
	}
	return keys[scroll_index]


	// return cast(win.WORD)scroll_index
}

config_to_button :: proc(value:string) -> Button {
	button:Button
	switch value {
		case "TAB":
			button.key = win.VK_TAB
			return button
		case "SPACE":
			button.key = win.VK_SPACE
			return button
		case "LSHIFT":
			button.key = win.VK_LSHIFT
			return button
		case "LCONTROL":
			button.key = win.VK_LCONTROL
			return button
		case "LALT":
			button.key = win.VK_LMENU
			return button
		case "RALT":
			button.key = win.VK_RMENU
			return button
		case "ESCAPE":
			button.key = win.VK_ESCAPE
			return button
		case "num_up":
			button.key =  0 //get_scroll_index(.RIGHT)
			return button
		case "num_down":
			button.key =  0 //get_scroll_index(.LEFT)
			return button
		case "right_click":
			button.mouse_button = win.MOUSEEVENTF_RIGHTDOWN
			button.mouse_release  = win.MOUSEEVENTF_RIGHTUP
			return button
		case "left_click":
			button.mouse_button = win.MOUSEEVENTF_LEFTDOWN
			button.mouse_release = win.MOUSEEVENTF_LEFTUP
			return button
	    case:
	        // Single letter A-Z fallback
	        if len(value) == 1 && value[0] >= 'A' && value[0] <= 'Z' {
	            button.key = cast(win.WORD)value[0]
	            return button
	        }
	}
	        	

	return button
}


load_default_config :: proc() -> Config {
	config:Config
	config.controller.dpad_up.key    = win.VK_Z
	config.controller.dpad_down.key  = win.VK_0
	config.controller.dpad_left.key  = win.VK_0
	config.controller.dpad_right.key = win.VK_0

	// face buttons (Y/Triangle, A/Cross, X/Square, B/Circle)
	config.controller.face_up.key    = win.VK_TAB
	config.controller.face_down.key  = win.VK_SPACE
	config.controller.face_left.key  = win.VK_F
	config.controller.face_right.key = win.VK_LCONTROL

	// bumpers
	config.controller.left_bumper.mouse_button   = win.MOUSEEVENTF_RIGHTDOWN
	config.controller.left_bumper.mouse_release  = win.MOUSEEVENTF_RIGHTUP
	config.controller.right_bumper.mouse_button  = win.MOUSEEVENTF_LEFTDOWN
	config.controller.right_bumper.mouse_release = win.MOUSEEVENTF_LEFTUP

	// left thumbstick (treated as keys)
	config.controller.left_thumb_up.key    = win.VK_W
	config.controller.left_thumb_down.key  = win.VK_S
	config.controller.left_thumb_left.key  = win.VK_A
	config.controller.left_thumb_right.key = win.VK_D
	config.controller.left_thumb_click.key = win.VK_LSHIFT

	// start / select
	config.controller.start.key  = win.VK_ESCAPE
	config.controller.select.key = win.VK_M

	config.smoothing = 0.18
	config.curve = 1.0
	config.max_accel = 0.5
	config.accel_buildup = 0.04
	config.ymult = 0.85
	config.sensitivity = 2.0
	config.pause_sensitivity = 0.05
	
	config.left_deadzone = 7849.0
	config.right_deadzone = 0.06

	
	return config
}

load_config:: proc(config:string) -> Config {
	// Using os2 intead of ini to load file as ini uses original os package, not os2
	data, error := os2.read_entire_file_from_path(config, context.allocator)

	if error != nil {
		fmt.eprintf("Could not load config due to error: %v\n", error)
		os2.exit(0)
	}

	m, err := ini.load_map_from_string(string(data), context.allocator)
	if err != nil {
		fmt.eprintf("Could not load config due to error: %v\n", error)
		os2.exit(0)
	}

	delete(data, context.allocator) // Don't need the original data anymore, free up memory


	config:Config
	
	// Set the settings options for the config
	config.smoothing, _ = strconv.parse_f32(m["settings"]["smoothing"])
	config.curve, _ = strconv.parse_f32(m["settings"]["curve"])
	config.max_accel, _ = strconv.parse_f32(m["settings"]["max_accel"])
	config.accel_buildup, _ = strconv.parse_f32(m["settings"]["accel_buildup"])
	config.ymult, _ = strconv.parse_f32(m["settings"]["ymult"])
	config.sensitivity, _ = strconv.parse_f32(m["settings"]["sensitivity"])
	config.pause_sensitivity, _ = strconv.parse_f32(m["settings"]["pause_sensitivity"])
	config.left_deadzone, _ = strconv.parse_f64(m["settings"]["left_deadzone"])
	config.right_deadzone, _ = strconv.parse_f64(m["settings"]["right_deadzone"])

	// Set the face buttons for the config
	config.controller.face_up =  config_to_button(m["buttons"]["face_up"])
	config.controller.face_down =  config_to_button(m["buttons"]["face_down"])
	config.controller.face_left =  config_to_button(m["buttons"]["face_left"])
	config.controller.face_right =  config_to_button(m["buttons"]["face_right"])

	// Set the dpad buttons for the config
	config.controller.dpad_up = config_to_button(m["buttons"]["dpad_up"])
	config.controller.dpad_down = config_to_button(m["buttons"]["dpad_down"])
	config.controller.dpad_left = config_to_button(m["buttons"]["dpad_left"])
	config.controller.dpad_right = config_to_button(m["buttons"]["dpad_right"])

	// Set the left and right buttons for the config
	config.controller.left_bumper = config_to_button(m["buttons"]["left_bumper"])
	config.controller.right_bumper = config_to_button(m["buttons"]["right_bumper"])

	// Set Thumsticks
	config.controller.left_thumb_up = config_to_button(m["buttons"]["left_thumb_up"])
	config.controller.left_thumb_down = config_to_button(m["buttons"]["left_thumb_down"])
	config.controller.left_thumb_left = config_to_button(m["buttons"]["left_thumb_left"])
	config.controller.left_thumb_right = config_to_button(m["buttons"]["left_thumb_right"])

	// Set Start and Select
	config.controller.start = config_to_button(m["buttons"]["start"])
	config.controller.select = config_to_button(m["buttons"]["select"])

	return config
}
