
package main

/*
	CTM -- Controller to Mouse
	==========================
	A small script that converts controller input into mouse input

	Resources:
	Thumbstick and Deadzone: https://learn.microsoft.com/en-us/windows/win32/xinput/getting-started-with-xinput
*/

import "core:math"
import win "core:sys/windows"

smooth_x    : f32
smooth_y    : f32
remainder_x : f32
remainder_y : f32

scroll_index : int = 0


Direction :: enum {
	LEFT,
	RIGHT,
}

State :: enum {
	PRESSED,
	RELEASED,
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
}

send_mouse_input :: proc(event: win.DWORD) {
	inputs: [1]win.INPUT
	inputs[0].type       = .MOUSE
	inputs[0].mi.dwFlags = event
	win.SendInput(len(inputs), raw_data(inputs[:]), size_of(win.INPUT))
}

send_input :: proc(key: win.WORD, key_state: State) {
	inputs: [1]win.INPUT
	inputs[0].type   = .KEYBOARD
	inputs[0].ki.wVk = key
	if key_state == .RELEASED {
		inputs[0].ki.dwFlags = 0x0002
	}
	win.SendInput(len(inputs), raw_data(inputs[:]), size_of(win.INPUT))
}

send_mouse_move :: proc(dx: i32, dy: i32) {
	inputs: [1]win.INPUT
	inputs[0]            = win.INPUT{}
	inputs[0].type       = .MOUSE
	inputs[0].mi.dx      = dx
	inputs[0].mi.dy      = dy
	inputs[0].mi.dwFlags = win.MOUSEEVENTF_MOVE
	win.SendInput(len(inputs), raw_data(inputs[:]), size_of(win.INPUT))
}

handle_button :: proc(button: ^Button, is_pressed: bool) {
	if is_pressed {
		if !button.pressed {
			button.pressed = true
			switch button.type {
			case .KEY:
				send_input(button.key, .PRESSED)
			case .MOUSE_BUTTON:
				send_mouse_input(button.mouse_button)
			case .SCROLL_UP:
				button.key = get_scroll_index(.RIGHT)
				send_input(button.key, .PRESSED)
			case .SCROLL_DOWN:
				button.key = get_scroll_index(.LEFT)
				send_input(button.key, .PRESSED)
			}
		}
	} else {
		if button.pressed {
			button.pressed = false
			switch button.type {
			case .KEY:
				send_input(button.key, .RELEASED)
			case .MOUSE_BUTTON:
				send_mouse_input(button.mouse_release)
			case .SCROLL_UP, .SCROLL_DOWN:
				send_input(button.key, .RELEASED)
			}
		}
	}
}

main :: proc() {
	// config := load_config("./config/hytale.ini")
	config := load_config("./config/nal.ini")
	// config := load_default_config()

	for {
		user  : win.XUSER
		state : win.XINPUT_STATE
		win.XInputGetState(user, &state)

		// ── Left stick → WASD ────────────────────────────────────────────────

		lx := cast(f16)state.Gamepad.sThumbLX
		ly := cast(f16)state.Gamepad.sThumbLY

		normalized_lx: f16 = 0
		normalized_ly: f16 = 0

		if math.abs(lx) > cast(f16)config.left_deadzone {
			normalized_lx = lx > 0 ? 1 : -1
		}
		if math.abs(ly) > cast(f16)config.left_deadzone {
			normalized_ly = ly > 0 ? 1 : -1
		}

		handle_button(&config.controller.left_thumb_up,    normalized_ly > 0)
		handle_button(&config.controller.left_thumb_down,  normalized_ly < 0)
		handle_button(&config.controller.left_thumb_left,  normalized_lx < 0)
		handle_button(&config.controller.left_thumb_right, normalized_lx > 0)
		handle_button(&config.controller.left_thumb_click, .LEFT_THUMB in state.Gamepad.wButtons)

		// ── Right stick → mouse movement (radial deadzone) ───────────────────

		rx := cast(f32)state.Gamepad.sThumbRX
		ry := cast(f32)state.Gamepad.sThumbRY

		normalized_x_right := rx / 32767.0
		normalized_y_right := ry / 32767.0

		magnitude_right := math.sqrt(
			normalized_x_right * normalized_x_right +
			normalized_y_right * normalized_y_right,
		)

		if magnitude_right < cast(f32)config.right_deadzone {
			normalized_x_right = 0
			normalized_y_right = 0
		} else {
			scale := (magnitude_right - cast(f32)config.right_deadzone) /
			         (1.0 - cast(f32)config.right_deadzone)
			scale = clamp(scale, 0, 1)
			normalized_x_right = (normalized_x_right / magnitude_right) * scale
			normalized_y_right = (normalized_y_right / magnitude_right) * scale
		}

		target_x := math.copy_sign_f32(math.pow_f32(math.abs(normalized_x_right), config.curve), normalized_x_right)
		target_y := math.copy_sign_f32(math.pow_f32(math.abs(normalized_y_right), config.curve), normalized_y_right)

		smooth_x += (target_x - smooth_x) * config.smoothing
		smooth_y += (target_y - smooth_y) * config.smoothing

		remainder_x += smooth_x * config.sensitivity
		remainder_y += smooth_y * config.sensitivity * config.ymult

		dx := i32(remainder_x)
		dy := i32(remainder_y)

		remainder_x -= f32(dx)
		remainder_y -= f32(dy)

		send_mouse_move(dx, -dy)

		// ── D-pad ─────────────────────────────────────────────────────────────

		handle_button(&config.controller.dpad_up,    .DPAD_UP    in state.Gamepad.wButtons)
		handle_button(&config.controller.dpad_down,  .DPAD_DOWN  in state.Gamepad.wButtons)
		handle_button(&config.controller.dpad_left,  .DPAD_LEFT  in state.Gamepad.wButtons)
		handle_button(&config.controller.dpad_right, .DPAD_RIGHT in state.Gamepad.wButtons)

		// ── Face buttons ──────────────────────────────────────────────────────

		handle_button(&config.controller.face_up,    .Y in state.Gamepad.wButtons)
		handle_button(&config.controller.face_down,  .A in state.Gamepad.wButtons)
		handle_button(&config.controller.face_left,  .X in state.Gamepad.wButtons)
		handle_button(&config.controller.face_right, .B in state.Gamepad.wButtons)

		// ── Bumpers ───────────────────────────────────────────────────────────

		handle_button(&config.controller.left_bumper,  .LEFT_SHOULDER  in state.Gamepad.wButtons)
		handle_button(&config.controller.right_bumper, .RIGHT_SHOULDER in state.Gamepad.wButtons)

		// ── Start / Select ────────────────────────────────────────────────────

		handle_button(&config.controller.start,  .START in state.Gamepad.wButtons)
		handle_button(&config.controller.select, .BACK  in state.Gamepad.wButtons)
	}
}
