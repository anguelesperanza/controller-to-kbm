package main

/*
	CTM -- Controller to Mouse
	==========================
	A small script that converts convroller input into mouse input

	XINPUT_STATE{dwPacketNumber = 225534, Gamepad = XINPUT_GAMEPAD{wButtons = XINPUT_GAMEPAD_BUTTON{DPAD_UP}, bLeftTrigger = 0, bRightTrigger = 0, sThumbLX = 0, sThumbLY = 0, sThumbRX = 0, sThumbRY = 0}}


	Resources:
	Thumbstick and Deadzone:https://learn.microsoft.com/en-us/windows/win32/xinput/getting-started-with-xinput
	AI for validation checks, questions, and general fixes
*/

import "core:fmt"
// import "core:time"
import "core:math"
import win "core:sys/windows"

XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE :: 7849
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689
INPUT_GAMEPAD_TRIGGER_THRESHOLD :: 30

scroll_index:int = 0

// ingame mouse speed set to 0.3 for left/right + top/down

MOUSE_SPEED :: 0.5 // tweak to taste
RIGHT_MOUSE_SPEED :: 2.0

Direction :: enum {
	LEFT,
	RIGHT,
}

State :: enum {
	PRESSED,
	RELEASED,
}

Button :: struct {
	pressed:       bool,
	key:           win.WORD,
	mouse_button:  win.DWORD,
	mouse_release: win.DWORD,
}

Controller :: struct {
	// dpad
	dpad_up:      Button,
	dpad_down:    Button,
	dpad_left:    Button,
	dpad_right:   Button,

	// face buttons
	face_up:      Button,
	face_down:    Button,
	face_left:    Button,
	face_right:   Button,

	// bumbers
	left_bumber:  Button,
	right_bumber: Button,
	left_thumb_up:Button,

	// triggers (nothing here at the moment)

	// left thumbstick
	left_thumb_down:Button,
	left_thumb_left:Button,
	left_thumb_right:Button,
	left_thumb_click:Button,


	// Start / Select
	start:Button,
	select:Button,
}

controller: Controller

// buttons: ButtonsPressed

previous_key: win.WORD
has_sent: bool = false

setup_defaults :: proc() {

	/*Setups up the default controls for the controller to keyboard mapping
	(Defaults are actually made for Hytale since that's the game being used during testing)*/

	// dpad
	controller.dpad_up.key = win.VK_Z
	controller.dpad_down.key = win.VK_0
	controller.dpad_left.key = win.VK_0
	controller.dpad_right.key = win.VK_0

	// face buttons (a b x y , triangle, cirlce square x)
	controller.face_up.key = win.VK_TAB
	controller.face_down.key = win.VK_SPACE
	controller.face_left.key = win.VK_F
	controller.face_right.key = win.VK_LCONTROL

	// Bumpers
	controller.left_bumber.mouse_button = win.MOUSEEVENTF_RIGHTDOWN
	controller.left_bumber.mouse_release = win.MOUSEEVENTF_RIGHTUP
	controller.right_bumber.mouse_button = win.MOUSEEVENTF_LEFTDOWN
	controller.right_bumber.mouse_release = win.MOUSEEVENTF_LEFTUP


	// Left thumb stick (treating as a key)
	controller.left_thumb_up.key = win.VK_W
	controller.left_thumb_down.key = win.VK_S
	controller.left_thumb_left.key = win.VK_A
	controller.left_thumb_right.key = win.VK_D
	controller.left_thumb_click.key = win.VK_LSHIFT

	// Start / Select
	controller.start.key = win.VK_ESCAPE
	controller.select.key = win.VK_M
}

get_scroll_index :: proc(direction:Direction) -> win.WORD {

	switch direction {
		case .LEFT:
			scroll_index -= 1
			if scroll_index < 1 do scroll_index = 9
		case .RIGHT:
			scroll_index += 1
			if scroll_index > 9 do scroll_index = 1
	}

	if scroll_index == 0 do return win.VK_0
	if scroll_index == 1 do return win.VK_1
	if scroll_index == 2 do return win.VK_2
	if scroll_index == 3 do return win.VK_3
	if scroll_index == 4 do return win.VK_4
	if scroll_index == 5 do return win.VK_5
	if scroll_index == 6 do return win.VK_6
	if scroll_index == 7 do return win.VK_7
	if scroll_index == 8 do return win.VK_8
	if scroll_index == 9 do return win.VK_9

	return win.VK_0 // default return the 0 key

}

send_mouse_input :: proc(event: win.DWORD) {
	/*Sends mouse input (not mouse movement)*/
	inputs: [1]win.INPUT

	inputs[0].type = .MOUSE
	inputs[0].mi.dwFlags = event

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	)
}

send_input :: proc(key: win.WORD, key_state: State) {

	/*Sends keyboard innput*/

	inputs: [1]win.INPUT

	switch key_state {
	case .PRESSED:
		inputs[0].type = .KEYBOARD // event comes from the keyboard
		inputs[0].ki.wVk = key

	case .RELEASED:
		inputs[0].type = .KEYBOARD // event comes from the keyboard
		inputs[0].ki.wVk = key
		inputs[0].ki.dwFlags = 0x0002 // release key dw flag
	}

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	) // -> UINT ---
}

send_mouse_move :: proc(dx: i32, dy: i32) {
	/*Moves the mouse based on the dx and dy values provided (not clicking events)*/
	inputs: [1]win.INPUT
	inputs[0] = win.INPUT{}

	inputs[0].type = .MOUSE
	inputs[0].mi.dx = dx
	inputs[0].mi.dy = dy
	inputs[0].mi.dwFlags = win.MOUSEEVENTF_MOVE

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	)
}

main :: proc() {

	setup_defaults()

	for {

		user: win.XUSER
		state: win.XINPUT_STATE
		system_err := win.XInputGetState(user, &state)

		// if state.Gamepad != {} do fmt.println(state.Gamepad)

		// Normaize input -- not what I want, I want dominate axis check
		// lx := cast(f16)state.Gamepad.sThumbLX
		// ly := cast(f16)state.Gamepad.sThumbLY

		// magnitude_left:f16 = math.sqrt(lx * lx + ly *ly)

		// normalized_lx:f16
		// normalized_ly:f16

		// if magnitude_left != 0 {
		// 	normalized_lx = lx / magnitude_left
		// 	normalized_ly = ly / magnitude_left
		// }
			
		
		// normalized_magnitude_left:f16 = 0

		// // Thumbstick (left) is not in the deadzone
		// if magnitude_left > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE {
		// 	if magnitude_left > 32767 do magnitude_left = 32767

		// 	magnitude_left -= XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE
		// 	normalized_magnitude_left = magnitude_left / (32767 - XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
			
		// } else {
		// 	// Thumbstick (left) is in the deadzone
		// 	magnitude_left = 0
		// 	normalized_magnitude_left = 0
		// }


		// domnite axis check
		
		lx := cast(f16)state.Gamepad.sThumbLX
		ly := cast(f16)state.Gamepad.sThumbLY

		magnitude_left:f16 = math.sqrt(lx * lx + ly *ly)
		normalized_magnitude_left:f16 = 0
		
		normalized_lx:f16
		normalized_ly:f16

		// Deadzone check
		if math.abs(lx) < XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE &&
		   math.abs(ly) < XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE {
		    normalized_lx = 0
		    normalized_ly = 0
		} else {
		    // Determine dominant axis
		    if math.abs(lx) > math.abs(ly) {
		        // Horizontal movement
		        normalized_lx = lx > 0 ? 1 : -1
		        normalized_ly = 0
		    } else {
		        // Vertical movement
		        normalized_ly = ly > 0 ? 1 : -1
		        normalized_lx = 0
		    }
		}

		if normalized_ly > 0 {
			if !controller.left_thumb_up.pressed {
				controller.left_thumb_up.pressed = true
				send_input(key = controller.left_thumb_up.key, key_state = .PRESSED)
			}
		} else {
			if controller.left_thumb_up.pressed {
				controller.left_thumb_up.pressed = false
				send_input(key = controller.left_thumb_up.key, key_state = .RELEASED)
			}
		}
		if normalized_ly < 0  {
			if !controller.left_thumb_down.pressed {
				controller.left_thumb_down.pressed = true
				send_input(key = controller.left_thumb_down.key, key_state = .PRESSED)
			}
		} else {
			if controller.left_thumb_down.pressed {
				controller.left_thumb_down.pressed = false
				send_input(key = controller.left_thumb_down.key, key_state = .RELEASED)
		 }
		}
		if normalized_lx < 0  {
			if !controller.left_thumb_left.pressed {
				controller.left_thumb_left.pressed = true
				send_input(key = controller.left_thumb_left.key, key_state = .PRESSED)
			}
		} else {
			if controller.left_thumb_left.pressed {
				controller.left_thumb_left.pressed = false
				send_input(key = controller.left_thumb_left.key, key_state = .RELEASED)
		 }
		}
		if normalized_lx > 0  {
			if !controller.left_thumb_right.pressed {
				controller.left_thumb_right.pressed = true
				send_input(key = controller.left_thumb_right.key, key_state = .PRESSED)
			}
		} else {
			if controller.left_thumb_right.pressed {
				controller.left_thumb_right.pressed = false
				send_input(key = controller.left_thumb_right.key, key_state = .RELEASED)
		 }
		}
		
		if win.XINPUT_GAMEPAD_BUTTON_BIT.LEFT_THUMB in state.Gamepad.wButtons {
			if !controller.left_thumb_click.pressed {
				controller.left_thumb_click.pressed = true
				send_input(controller.left_thumb_click.key, .PRESSED)
			}
		} else {
			if controller.left_thumb_click.pressed {
				controller.left_thumb_click.pressed = false
				send_input(controller.left_thumb_click.key, .RELEASED)
			}
		}

		// ============================================================================================================
		
		// // RIGHT STICK → MOUSE MOVEMENT
		// rx := state.Gamepad.sThumbRX
		// ry := state.Gamepad.sThumbRY

		// // Normalize thumbstick values to [-1.0, 1.0]
		// normalized_x_right := f32(rx) / 32767.0
		// normalized_y_right := f32(ry) / 32767.0

		// // Apply deadzone
		// deadzone_threshold_right := f32(XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE) / 32767.0

		// // Check if the magnitude is within deadzone
		// magnitude := math.sqrt(normalized_x_right*normalized_x_right + normalized_y_right*normalized_y_right)

		// if magnitude < deadzone_threshold_right {
		//     // Inside deadzone, set to zero
		//     normalized_x_right = 0
		//     normalized_y_right = 0
		// } else {
		//     // Outside deadzone - scale the vector properly
		//     // This ensures smooth diagonal movement
		//     scale := (magnitude - deadzone_threshold_right) / (1.0 - deadzone_threshold_right)
		//     if scale < 0 {
		//         scale = 0
		//     }
    
		//     // Apply the scaling to maintain proper proportions
		//     normalized_x_right = normalized_x_right * scale
		//     normalized_y_right = normalized_y_right * scale
		// }

		// // Apply mouse sensitivity
		// dx := normalized_x_right * MOUSE_SPEED
		// dy := normalized_y_right * MOUSE_SPEED

		// // Round to integer for mouse movement
		// dx_rounded := i32(math.round(f64(dx)))
		// dy_rounded := i32(math.round(f64(dy)))
		
		// // fmt.printf("RX: %d  RY: %d\n", state.Gamepad.sThumbRX, state.Gamepad.sThumbRY)
		
		// send_mouse_move(dx_rounded, -dy_rounded)

		rx := cast(f32)state.Gamepad.sThumbRX
		ry := cast(f32)state.Gamepad.sThumbRY

		// if math.abs(cast(f64)rx) < XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE do rx = 0
		// if math.abs(cast(f64)ry) < XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE do ry = 0



		magnitude_right:f32 = math.sqrt(rx * rx + ry * ry)


		if magnitude_right < XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE {
			rx = 0
			ry = 0
			magnitude_right = 0
		}
		
		nx:f32 = 0
		ny:f32 = 0

		
		normalized_magnitude_right:f32 = 0
		
		if magnitude_right > 0 {
			nx = rx / magnitude_right
			ny = ry / magnitude_right

			normalized_magnitude_right = magnitude_right / 32767.0

			if normalized_magnitude_right > 1.0 do normalized_magnitude_right = 1.0
		}

		dx:f32 = nx * normalized_magnitude_right * RIGHT_MOUSE_SPEED
		dy:f32 = -ny * normalized_magnitude_right * RIGHT_MOUSE_SPEED

		send_mouse_move(cast(win.LONG)dx, cast(win.LONG)dy)
		
		
		// DPAD CHECKS -- UP
		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_UP in state.Gamepad.wButtons {
			if !controller.dpad_up.pressed {
				controller.dpad_up.pressed = true
				send_input(controller.dpad_up.key, .PRESSED)
			}
		} else {
			if controller.dpad_up.pressed {
				controller.dpad_up.pressed = false
				send_input(controller.dpad_up.key, .RELEASED)
			}
		}

		// DPAD CHECKS -- DOWN
		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_DOWN in state.Gamepad.wButtons {
			if !controller.dpad_down.pressed {
				controller.dpad_down.pressed = true
				send_input(controller.dpad_down.key, .PRESSED)
			}
		} else {
			if controller.dpad_down.pressed {
				controller.dpad_down.pressed = false
				send_input(controller.dpad_down.key, .RELEASED)
			}
		}

		// DPAD CHECKS -- LEFT
		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_LEFT in state.Gamepad.wButtons {
			if !controller.dpad_left.pressed {
				controller.dpad_left.pressed = true
				controller.dpad_left.key = get_scroll_index(.LEFT)
				send_input(controller.dpad_left.key, .PRESSED)
			}
		} else {
			if controller.dpad_left.pressed {
				controller.dpad_left.pressed = false
				send_input(controller.dpad_left.key, .RELEASED)
			}
		}

		// DPAD CHECKS -- RIGHT
		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_RIGHT in state.Gamepad.wButtons {
			if !controller.dpad_right.pressed {
				controller.dpad_right.pressed = true
				controller.dpad_right.key = get_scroll_index(.RIGHT)
				send_input(controller.dpad_right.key, .PRESSED)
			}
		} else {
			if controller.dpad_right.pressed {
				controller.dpad_right.pressed = false
				send_input(controller.dpad_right.key, .RELEASED)
			}
		}


		// FACE CHECKS -- UP (Y (xbox), Triangle (playstation), X (Nintendo))
		if win.XINPUT_GAMEPAD_BUTTON_BIT.Y in state.Gamepad.wButtons {
			if !controller.face_up.pressed {
				controller.face_up.pressed = true
				send_input(controller.face_up.key, .PRESSED)
			}
		} else {
			if controller.face_up.pressed {
				controller.face_up.pressed = false
				send_input(controller.face_up.key, .RELEASED)
			}
		}


		// FACE CHECKS -- DOWN (A (xbox), X (playstation), B (Nintendo))
		if win.XINPUT_GAMEPAD_BUTTON_BIT.A in state.Gamepad.wButtons {
			if !controller.face_down.pressed {
				controller.face_down.pressed = true
				send_input(controller.face_down.key, .PRESSED)
			}
		} else {
			if controller.face_down.pressed {
				controller.face_down.pressed = false
				send_input(controller.face_down.key, .RELEASED)
			}
		}

		// FACE CHECKS -- LEFT (X (xbox), Square (playstation), Y (Nintendo))
		if win.XINPUT_GAMEPAD_BUTTON_BIT.X in state.Gamepad.wButtons {
			if !controller.face_left.pressed {
				controller.face_left.pressed = true
				send_input(controller.face_left.key, .PRESSED)
			}
		} else {
			if controller.face_left.pressed {
				controller.face_left.pressed = false
				send_input(controller.face_left.key, .RELEASED)
			}
		}

		// FACE CHECKS -- RIGHT (B (xbox), CIRCLE (playstation), A (Nintendo))
		if win.XINPUT_GAMEPAD_BUTTON_BIT.B in state.Gamepad.wButtons {
			if !controller.face_right.pressed {
				controller.face_right.pressed = true
				send_input(controller.face_right.key, .PRESSED)
			}
		} else {
			if controller.face_right.pressed {
				controller.face_right.pressed = false
				send_input(controller.face_right.key, .RELEASED)
			}
		}


		// LEFT BUMPER → LEFT CLICK
		if win.XINPUT_GAMEPAD_BUTTON_BIT.LEFT_SHOULDER in state.Gamepad.wButtons {
			if !controller.left_bumber.pressed {
				controller.left_bumber.pressed = true
				send_mouse_input(controller.left_bumber.mouse_button)
			}
		} else {
			if controller.left_bumber.pressed {
				controller.left_bumber.pressed = false
				send_mouse_input(controller.left_bumber.mouse_release)
			}
		}

		// RIGHT BUMPER → RIGHT CLICK
		if win.XINPUT_GAMEPAD_BUTTON_BIT.RIGHT_SHOULDER in state.Gamepad.wButtons {
			if !controller.right_bumber.pressed {
				controller.right_bumber.pressed = true
				send_mouse_input(event = controller.right_bumber.mouse_button)
			}
		} else {
			if controller.right_bumber.pressed {
				controller.right_bumber.pressed = false
				send_mouse_input(controller.right_bumber.mouse_release)
			}
		}

		// Start
		if win.XINPUT_GAMEPAD_BUTTON_BIT.START in state.Gamepad.wButtons {
			if !controller.start.pressed {
				controller.start.pressed = true
				send_input(controller.start.key, .PRESSED)
			}
		} else {
			if controller.start.pressed {
				controller.start.pressed = false
				send_input(controller.start.key, .RELEASED)
			}
		}
		
		// Select
		if win.XINPUT_GAMEPAD_BUTTON_BIT.BACK in state.Gamepad.wButtons {
			if !controller.select.pressed {
				controller.select.pressed = true
				send_input(controller.select.key, .PRESSED)
			}
		} else {
			if controller.select.pressed {
				controller.select.pressed = false
				send_input(controller.select.key, .RELEASED)
			}
		}
		
	} // End of infinite for loop
}
