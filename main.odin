package main

/*
	CTM -- Controller to Mouse
	==========================
	A small script that converts convroller input into mouse input

	XINPUT_STATE{dwPacketNumber = 225534, Gamepad = XINPUT_GAMEPAD{wButtons = XINPUT_GAMEPAD_BUTTON{DPAD_UP}, bLeftTrigger = 0, bRightTrigger = 0, sThumbLX = 0, sThumbLY = 0, sThumbRX = 0, sThumbRY = 0}}	
*/

import "core:fmt"
// import "core:time"
import "core:math"
import win "core:sys/windows"


XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE :: 7849
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689
INPUT_GAMEPAD_TRIGGER_THRESHOLD :: 30


MOUSE_SPEED :: 5.0 // tweak to taste

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
	dpad_up:      Button,
	dpad_down:    Button,
	dpad_left:    Button,
	dpad_right:   Button,
	face_up:      Button,
	face_down:    Button,
	face_left:    Button,
	face_right:   Button,
	left_bumber:  Button,
	right_bumber: Button,
}
controller: Controller

// buttons: ButtonsPressed

previous_key: win.WORD
has_sent: bool = false


setup_defaults :: proc() {

	/*Setups up the default controls for the controller to keyboard mapping
	(Defaults are actually made for Hytale since that's the game being used during testing)*/

	// dpad
	controller.dpad_up.key = win.VK_W
	controller.dpad_down.key = win.VK_S
	controller.dpad_left.key = win.VK_A
	controller.dpad_right.key = win.VK_D

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
}

send_mouse_input :: proc(event: win.DWORD) {
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
	/*Moves the mouse based on the dx and dy values provided*/
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


		// Move right thumstick to move mouse

		// RIGHT STICK → MOUSE MOVEMENT
		rx := state.Gamepad.sThumbRX
		ry := state.Gamepad.sThumbRY

		// deadzone
		if math.abs(cast(win.SHORT)rx) < XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE do rx = 0
		if math.abs(cast(win.SHORT)ry) < XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE do ry = 0

		if rx != 0 || ry != 0 {
			mag := math.sqrt(f32(rx * rx + ry * ry))

			if mag > 0 {
				nx := f32(rx) / mag
				ny := f32(ry) / mag
				scaled := math.min(mag / 32767.0, 1.0)

				dx := nx * scaled * MOUSE_SPEED
				dy := ny * scaled * MOUSE_SPEED

				send_mouse_move(i32(dx), i32(-dy))
			}
		}


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

	} // End of infinite for loop
}
