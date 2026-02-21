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
	
	
	
	

*/

import "core:fmt"
import "core:os/os2"
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
	
	config.left_deadzone = 7849.0
	config.right_deadzone = 0.06

	
	return config
}

load_config:: proc(config:string) {
	/* WIP: Loads up the provided config*/

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

	fmt.println(m)

	delete(data, context.allocator) // Don't need the original data anymore, free up memory
    /*map[
    	mouse=map[left_bumper=right_click, right_bumper=left_click],
	    settings=map[smoothing=0.18, ymult=0.85, sensitivity=3.0, curve=1.0],
	    buttons=map[left_thumb_click=VK_LSHIFT, face_down=VK_SPACE, face_up=VK_TAB, face_left=VK_F, dpad_right=VK_0, left_thumb_up=VK_W, left_thumb_right=VK_D, left_thumb_down=VK_S, start=VK_ESCAPE, dpad_down=VK_0, left_thumb_left=VK_A, dpad_up=VK_Z, dpad_left=VK_0, face_right=VK_LCONTROL, select=VK_M]
	 ]*/

	

}
