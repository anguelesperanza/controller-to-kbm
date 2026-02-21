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

smooth_x         : f32
smooth_y         : f32
accel_buildup    : f32
// base_sensitivity : f32
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

Button :: struct {
	pressed:       bool,
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

	// Start / Select
	start:  Button,
	select: Button,
}

controller: Controller

setup_defaults :: proc() {
	// dpad

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

	config.sensitivity = 8.0
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

main :: proc() {
	setup_defaults()

	// load_config("./config/hytale.ini")
	config := load_default_config()

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

		// up
		if normalized_ly > 0 {
			if !config.controller.left_thumb_up.pressed {
				config.controller.left_thumb_up.pressed = true
				send_input(config.controller.left_thumb_up.key, .PRESSED)
			}
		} else if config.controller.left_thumb_up.pressed {
			config.controller.left_thumb_up.pressed = false
			send_input(config.controller.left_thumb_up.key, .RELEASED)
		}

		// down
		if normalized_ly < 0 {
			if !config.controller.left_thumb_down.pressed {
				config.controller.left_thumb_down.pressed = true
				send_input(config.controller.left_thumb_down.key, .PRESSED)
			}
		} else if config.controller.left_thumb_down.pressed {
			config.controller.left_thumb_down.pressed = false
			send_input(config.controller.left_thumb_down.key, .RELEASED)
		}

		// left
		if normalized_lx < 0 {
			if !config.controller.left_thumb_left.pressed {
				config.controller.left_thumb_left.pressed = true
				send_input(config.controller.left_thumb_left.key, .PRESSED)
			}
		} else if config.controller.left_thumb_left.pressed {
			config.controller.left_thumb_left.pressed = false
			send_input(config.controller.left_thumb_left.key, .RELEASED)
		}

		// right
		if normalized_lx > 0 {
			if !config.controller.left_thumb_right.pressed {
				config.controller.left_thumb_right.pressed = true
				send_input(config.controller.left_thumb_right.key, .PRESSED)
			}
		} else if config.controller.left_thumb_right.pressed {
			config.controller.left_thumb_right.pressed = false
			send_input(config.controller.left_thumb_right.key, .RELEASED)
		}

		// left stick click
		if win.XINPUT_GAMEPAD_BUTTON_BIT.LEFT_THUMB in state.Gamepad.wButtons {
			if !config.controller.left_thumb_click.pressed {
				config.controller.left_thumb_click.pressed = true
				send_input(config.controller.left_thumb_click.key, .PRESSED)
			}
		} else if config.controller.left_thumb_click.pressed {
			config.controller.left_thumb_click.pressed = false
			send_input(config.controller.left_thumb_click.key, .RELEASED)
		}

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
			scale := (magnitude_right - cast(f32)config.right_deadzone) / (1.0 - cast(f32)config.right_deadzone)
			scale = clamp(scale, 0, 1)
			normalized_x_right = (normalized_x_right / magnitude_right) * scale
			normalized_y_right = (normalized_y_right / magnitude_right) * scale
		}

		target_x := math.copy_sign_f32(math.pow_f32(math.abs(normalized_x_right), config.curve), normalized_x_right)
		target_y := math.copy_sign_f32(math.pow_f32(math.abs(normalized_y_right), config.curve), normalized_y_right)

		smooth_x += (target_x - smooth_x) * config.smoothing
		smooth_y += (target_y - smooth_y) * config.smoothing

		remainder_x += smooth_x * config.sensitivity
		remainder_y += smooth_y * config.sensitivity* config.ymult

		dx := i32(remainder_x)
		dy := i32(remainder_y)

		remainder_x -= f32(dx)
		remainder_y -= f32(dy)

		send_mouse_move(dx, -dy)

		// ── D-pad ─────────────────────────────────────────────────────────────

		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_UP in state.Gamepad.wButtons {
			if !config.controller.dpad_up.pressed {
				config.controller.dpad_up.pressed = true
				send_input(config.controller.dpad_up.key, .PRESSED)
			}
		} else if config.controller.dpad_up.pressed {
			config.controller.dpad_up.pressed = false
			send_input(config.controller.dpad_up.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_DOWN in state.Gamepad.wButtons {
			if !config.controller.dpad_down.pressed {
				config.controller.dpad_down.pressed = true
				send_input(config.controller.dpad_down.key, .PRESSED)
			}
		} else if config.controller.dpad_down.pressed {
			config.controller.dpad_down.pressed = false
			send_input(config.controller.dpad_down.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_LEFT in state.Gamepad.wButtons {
			if !config.controller.dpad_left.pressed {
				config.controller.dpad_left.pressed = true
				config.controller.dpad_left.key = get_scroll_index(.LEFT)
				send_input(config.controller.dpad_left.key, .PRESSED)
			}
		} else if config.controller.dpad_left.pressed {
			config.controller.dpad_left.pressed = false
			send_input(config.controller.dpad_left.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.DPAD_RIGHT in state.Gamepad.wButtons {
			if !config.controller.dpad_right.pressed {
				config.controller.dpad_right.pressed = true
				config.controller.dpad_right.key = get_scroll_index(.RIGHT)
				send_input(config.controller.dpad_right.key, .PRESSED)
			}
		} else if config.controller.dpad_right.pressed {
			config.controller.dpad_right.pressed = false
			send_input(config.controller.dpad_right.key, .RELEASED)
		}

		// ── Face buttons ──────────────────────────────────────────────────────

		if win.XINPUT_GAMEPAD_BUTTON_BIT.Y in state.Gamepad.wButtons {
			if !config.controller.face_up.pressed {
				config.controller.face_up.pressed = true
				send_input(config.controller.face_up.key, .PRESSED)
			}
		} else if config.controller.face_up.pressed {
			config.controller.face_up.pressed = false
			send_input(config.controller.face_up.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.A in state.Gamepad.wButtons {
			if !config.controller.face_down.pressed {
				config.controller.face_down.pressed = true
				send_input(config.controller.face_down.key, .PRESSED)
			}
		} else if config.controller.face_down.pressed {
			config.controller.face_down.pressed = false
			send_input(config.controller.face_down.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.X in state.Gamepad.wButtons {
			if !config.controller.face_left.pressed {
				config.controller.face_left.pressed = true
				send_input(config.controller.face_left.key, .PRESSED)
			}
		} else if config.controller.face_left.pressed {
			config.controller.face_left.pressed = false
			send_input(config.controller.face_left.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.B in state.Gamepad.wButtons {
			if !config.controller.face_right.pressed {
				config.controller.face_right.pressed = true
				send_input(config.controller.face_right.key, .PRESSED)
			}
		} else if config.controller.face_right.pressed {
			config.controller.face_right.pressed = false
			send_input(config.controller.face_right.key, .RELEASED)
		}

		// ── Bumpers ───────────────────────────────────────────────────────────

		if win.XINPUT_GAMEPAD_BUTTON_BIT.LEFT_SHOULDER in state.Gamepad.wButtons {
			if !config.controller.left_bumper.pressed {
				config.controller.left_bumper.pressed = true
				send_mouse_input(config.controller.left_bumper.mouse_button)
			}
		} else if config.controller.left_bumper.pressed {
			config.controller.left_bumper.pressed = false
			send_mouse_input(config.controller.left_bumper.mouse_release)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.RIGHT_SHOULDER in state.Gamepad.wButtons {
			if !config.controller.right_bumper.pressed {
				config.controller.right_bumper.pressed = true
				send_mouse_input(config.controller.right_bumper.mouse_button)
			}
		} else if config.controller.right_bumper.pressed {
			config.controller.right_bumper.pressed = false
			send_mouse_input(config.controller.right_bumper.mouse_release)
		}

		// ── Start / Select ────────────────────────────────────────────────────

		if win.XINPUT_GAMEPAD_BUTTON_BIT.START in state.Gamepad.wButtons {
			if !config.controller.start.pressed {
				config.controller.start.pressed = true
				send_input(config.controller.start.key, .PRESSED)
			}
		} else if config.controller.start.pressed {
			config.controller.start.pressed = false
			send_input(config.controller.start.key, .RELEASED)
		}

		if win.XINPUT_GAMEPAD_BUTTON_BIT.BACK in state.Gamepad.wButtons {
			if !config.controller.select.pressed {
				config.controller.select.pressed = true
				send_input(config.controller.select.key, .PRESSED)
			}
		} else if config.controller.select.pressed {
			config.controller.select.pressed = false
			send_input(config.controller.select.key, .RELEASED)
		}
	}
}
