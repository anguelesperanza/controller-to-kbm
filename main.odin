package main

/*
	CTM -- Controller to Mouse
	==========================
	A small script that converts convroller input into mouse input
*/

import "core:fmt"
// import "core:time"
import win "core:sys/windows"
import "core:math"


XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE ::  7849
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689
INPUT_GAMEPAD_TRIGGER_THRESHOLD :: 30

ctm_enabled:bool



main :: proc() {

	smoothing:win.INT = 1
	right_thumb_counter:[2]win.INT
	frame_counter:int = 0
	max_frame_counter:int = 100
	speed:f64 = 100


	for {
		user:win.XUSER
		state:win.XINPUT_STATE
		system_err := win.XInputGetState(user, &state)

		rx := cast(f64)state.Gamepad.sThumbLX
		ry := cast(f64)state.Gamepad.sThumbLY

		dx:f64
		dy:f64
		
		magnitude := math.sqrt_f64(rx * rx + ry + ry)

		normalized_lx := rx / magnitude
		normalized_ly := ry / magnitude

		normalized_magnitude := 0

		// if magnitude > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE {
		// 	if magnitude > 32767 do magnitude = 32767

		// 	magnitude -= XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE

		// 	normalized_magnitude = cast(int)magnitude / (32767 - XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
		// } else {
		// 	magnitude = 0
		// 	normalized_magnitude = 0
		// }

		if math.abs(rx) < XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE do rx = 0
		if math.abs(ry) < XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE do ry = 0

		if magnitude > 0 {
			nx := rx / magnitude
			ny := ry / magnitude


			normalized_magnitude = cast(int)min(magnitude / 32767.0, 1.0)

			dx = nx * cast(f64)normalized_magnitude * speed
			dy = ny * cast(f64)normalized_magnitude * speed
			
		}

		
		if state.Gamepad.wButtons == {.LEFT_THUMB, .LEFT_SHOULDER, .RIGHT_SHOULDER} && frame_counter <= max_frame_counter {
			fmt.println(ctm_enabled)
			// fmt.println(state.Gamepad.wButtons)
			ctm_enabled = true
			
		} // end of buttom press check
		
		if state.Gamepad.wButtons == {.RIGHT_THUMB, .LEFT_SHOULDER, .RIGHT_SHOULDER} {
			// fmt.println(ctm_enabled)
			// fmt.println(state.Gamepad.wButtons)
			ctm_enabled = false			
		} // end of buttom press end check 
		
		if ctm_enabled {
			
			win.SetCursorPos(cast(win.INT)dx, cast(win.INT)dy)
			// inputs:[1]win.INPUT
			// inputs[0].type = .MOUSE
			// inputs[0].mi = {
			// 	dx = cast(win.LONG)dx,
			// 	dy = cast(win.LONG)dy,
			// 	dwFlags = win.MOUSEEVENTF_MOVE
			// }

			// fmt.println(inputs[0])
			// win.SendInput(cInputs = 0, pInputs = raw_data(inputs[:]), cbSize = size_of(win.INPUT)) // -> UINT ---

			
			// // Right Thumbstick Pointing right
			// if state.Gamepad.sThumbRX > 0 && frame_counter == max_frame_counter {
			// 	right_thumb_counter[0] += 1
			// 	win.ShowCursor(win.TRUE)
			// 	win.SetCursorPos(cast(win.INT)right_thumb_counter[0], cast(win.INT)right_thumb_counter[1])
			// }
			// // Right Thumbstick Pointing left
			// if state.Gamepad.sThumbRX < 0 && frame_counter == max_frame_counter {
			// 	right_thumb_counter[0] -= 1
			// 	win.ShowCursor(win.TRUE)
			// 	win.SetCursorPos(cast(win.INT)right_thumb_counter[0], cast(win.INT)right_thumb_counter[1])
			// }
			// // Right Thumbstick Pointing Up
			// if state.Gamepad.sThumbRY > 0 && frame_counter == max_frame_counter {
			// 	right_thumb_counter[1] -= 1
			// 	win.ShowCursor(win.TRUE)
			// 	win.SetCursorPos(cast(win.INT)right_thumb_counter[0], cast(win.INT)right_thumb_counter[1])
			// }
			
			// // Right Thumbstick Pointing Down
			// if state.Gamepad.sThumbRY < 0 && frame_counter == max_frame_counter {
			// 	right_thumb_counter[1] += 1
			// 	win.ShowCursor(win.TRUE)
			// 	win.SetCursorPos(cast(win.INT)right_thumb_counter[0], cast(win.INT)right_thumb_counter[1])
			// }
			
			// win.ShowCursor(win.TRUE)
		} // end of ctm_enabled if's else branch
		// frame_counter += 1

		// if frame_counter > max_frame_counter do frame_counter = 0
	} // End of infinite for loop
}
