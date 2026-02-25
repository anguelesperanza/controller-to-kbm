package main

import "core:strings"
import "core:mem"
/*
	Wayland testing
	---------------
	Seeing if controller to kbm can be used on Wayland

	evtest -> /dev/input/event8: Generic X-Box pad

	
*/

EV_SYN  :: 0
EV_KEY  :: 1
EV_REL  :: 2
EV_ABS  :: 3

SYN_REPORT :: 0x00

// KEYS
KEY_SPACE :: 57

_IOC_DIRSHIFT  :: 30
_IOC_TYPESHIFT :: 8
_IOC_NRSHIFT   :: 0
_IOC_SIZESHIFT :: 16

_IOC_WRITE :: u64(1)

UINPUT_IOCTL_BASE :: u64('U')

UI_SET_EVBIT :: (_IOC_WRITE << _IOC_DIRSHIFT) |
                (UINPUT_IOCTL_BASE << _IOC_TYPESHIFT) |
                (u64(100) << _IOC_NRSHIFT) |
                (u64(4) << _IOC_SIZESHIFT)

UI_SET_KEYBIT :: (_IOC_WRITE << _IOC_DIRSHIFT) |
                 (UINPUT_IOCTL_BASE << _IOC_TYPESHIFT) |
                 (u64(101) << _IOC_NRSHIFT) |
                 (u64(4) << _IOC_SIZESHIFT)

BUS_USB :: 0x03

UINPUT_SETUP_SIZE :: 92

UI_DEV_SETUP :: (_IOC_WRITE << _IOC_DIRSHIFT) |
                (UINPUT_IOCTL_BASE << _IOC_TYPESHIFT) |
                (u64(3) << _IOC_NRSHIFT) |
                (u64(UINPUT_SETUP_SIZE) << _IOC_SIZESHIFT)

_IOC_READ :: u64(2)

EVIOCGNAME :: proc(length: u64) -> u64 {
    return (_IOC_READ << _IOC_DIRSHIFT) |
           (u64('E') << _IOC_TYPESHIFT) |
           (u64(0x06) << _IOC_NRSHIFT) |
           (length << _IOC_SIZESHIFT)
}

UI_DEV_CREATE :: (UINPUT_IOCTL_BASE << _IOC_TYPESHIFT) | (u64(1) << _IOC_NRSHIFT)

REL_X :: 0
REL_Y :: 1

UI_SET_RELBIT :: (_IOC_WRITE << _IOC_DIRSHIFT) |
                 (UINPUT_IOCTL_BASE << _IOC_TYPESHIFT) |
                 (u64(102) << _IOC_NRSHIFT) |
                 (u64(4) << _IOC_SIZESHIFT)


ABS_RX :: 3
ABS_RY :: 4

// Add a deadzone to avoid drift
DEADZONE :: 8000


ABS_X :: 0
ABS_Y :: 1

KEY_W :: 17
KEY_A :: 30
KEY_S :: 31
KEY_D :: 32



TimeVal :: struct {
	tv_sec:  i64,
	tv_usec: i64,
}

input_event :: struct {
	time:  TimeVal,
	type:  u16,
	code:  u16,
	value: i32,
}

// Matches: struct input_id in <linux/input.h>
input_id :: struct {
    bustype : u16,
    vendor  : u16,
    product : u16,
    version : u16,
}

// Matches: struct uinput_setup in <linux/uinput.h>
uinput_setup :: struct {
    id              : input_id,
    name            : [80]u8,   // UINPUT_MAX_NAME_SIZE is 80
    ff_effects_max  : u32,
}

import "core:fmt"
import "core:time"
import "core:os/os2"
import "core:sys/linux"

emit :: proc(fd: linux.Fd, type: u16, code: u16, value: i32) {
	ie: input_event
	ie.type  = type
	ie.code  = code
	ie.value = value

    buf := mem.byte_slice(&ie, size_of(input_event))
    _, _ = linux.write(fd, buf)

}


move_mouse :: proc(input_device: linux.Fd, dx: i32, dy: i32) {
    emit(input_device, EV_REL, REL_X, dx)
    emit(input_device, EV_REL, REL_Y, dy)
    emit(input_device, EV_SYN, SYN_REPORT, 0)
}

check_buttons :: proc(event: input_event, input_device: linux.Fd) {
    switch event.type {
        case EV_KEY:
            switch event.code {
                // Face buttons
                case 304:
                    if event.value == 1 {
                        fmt.println("Face Button Down Pressed")
                        emit(input_device, EV_KEY, KEY_SPACE, 1)
                        emit(input_device, EV_SYN, SYN_REPORT, 0)
                    } else {
                        emit(input_device, EV_KEY, KEY_SPACE, 0)
                        emit(input_device, EV_SYN, SYN_REPORT, 0)
                    }
                case 305:
                    if event.value == 1 do fmt.println("Face Button Right Pressed")
                case 307:
                    if event.value == 1 do fmt.println("Face Button Left Pressed")
                case 308:
                    if event.value == 1 do fmt.println("Face Button Up Pressed")
                // Dpad
                case 16:
                    if event.value == 1  do fmt.println("DPAD Right Pressed")
                if event.value == -1 do fmt.println("DPAD Left Pressed")
                case 17:
                    if event.value == 1  do fmt.println("DPAD Down Pressed")
                    if event.value == -1 do fmt.println("DPAD Up Pressed")
                // Bumpers
                case 310:
                    if event.value == 1 do fmt.println("Bumper Left Pressed")
                case 311:
                    if event.value == 1 do fmt.println("Bumper Right Pressed")
                // Triggers
                case 2:
                    if event.value == 255 do fmt.println("Trigger Left Fully Pressed")
                case 5:
                    if event.value == 255 do fmt.println("Trigger Right Fully Pressed")
                // Select
                case 314:
                    if event.value == 1 do fmt.println("Select Pressed")
                // Start
                case 315:
                    if event.value == 1 do fmt.println("Start Pressed")
            }
        case EV_ABS:
		    // fmt.println("ABS event - code:", event.code, "value:", event.value)
            switch event.code {
                case ABS_RX:
		            // fmt.println("RX value:", event.value, "deadzone:", DEADZONE)
                    if abs(event.value) > DEADZONE {
                        dx := event.value / 500
                        move_mouse(input_device, dx, 0)
                    }
                case ABS_RY:
		            // fmt.println("RY value:", event.value, "deadzone:", DEADZONE)
                    if abs(event.value) > DEADZONE {
                        dy := event.value / 500
                        move_mouse(input_device, 0, dy)
                    }

                case ABS_X:
				    if event.value > DEADZONE {
				        emit(input_device, EV_KEY, KEY_D, 1)
				        emit(input_device, EV_KEY, KEY_A, 0)
				    } else if event.value < -DEADZONE {
				        emit(input_device, EV_KEY, KEY_A, 1)
				        emit(input_device, EV_KEY, KEY_D, 0)
				    } else {
				        emit(input_device, EV_KEY, KEY_D, 0)
				        emit(input_device, EV_KEY, KEY_A, 0)
				    }
				    emit(input_device, EV_SYN, SYN_REPORT, 0)

				case ABS_Y:
				    if event.value > DEADZONE {
				        emit(input_device, EV_KEY, KEY_S, 1)
				        emit(input_device, EV_KEY, KEY_W, 0)
				    } else if event.value < -DEADZONE {
				        emit(input_device, EV_KEY, KEY_W, 1)
				        emit(input_device, EV_KEY, KEY_S, 0)
				    } else {
				        emit(input_device, EV_KEY, KEY_W, 0)
				        emit(input_device, EV_KEY, KEY_S, 0)
				    }
				    emit(input_device, EV_SYN, SYN_REPORT, 0)
            }
    }
}

find_controller_by_name :: proc(name:string) -> string {
	files, err := os2.read_directory_by_path("/dev/input", 0, context.allocator)
	if err != nil {
		fmt.eprintf("Could not read /dev/input folder: %v", err)
		return ""
	}

	for file in files {
		result := strings.starts_with(file.name, "event")
		if result {
			controller, err := linux.open(strings.clone_to_cstring(file.fullpath), linux.Open_Flags{})
			buf: [256]u8
			linux.ioctl(controller, cast(u32)EVIOCGNAME(256), cast(uintptr)&buf)
			linux.close(controller)

			fmt.println(string(buf[:]))

			if strings.trim_null(string(buf[:])) == name {
				return file.fullpath
			}

		}
	}

	return ""
}

main :: proc() {

	fmt.println("UI_SET_EVBIT value:",  UI_SET_EVBIT)
	fmt.println("UI_SET_RELBIT value:", UI_SET_RELBIT)
	fmt.println("UI_SET_KEYBIT value:", UI_SET_KEYBIT)
	fmt.println("UI_DEV_SETUP value:",  UI_DEV_SETUP)
	fmt.println("UI_DEV_CREATE value:", UI_DEV_CREATE)

	fmt.println()
	
	// Step 1: open the controller (this changed from event8 to event12 when I restared. Need a better way to set)
	controller_name := "Generic X-Box pad"
	// controller_name := "Valve Software Steam Deck Controller"	
	// controller_name := "DualSense Wireless Controller"
	// controller_name := "Xbox Wireless Controller"
	// controller_name := "Microsoft X-Box 360 pad"
	input_file_name := find_controller_by_name(controller_name)

	if input_file_name == "" {
		fmt.printf("Could not find input called, %v\n", controller_name)
		return
	}
	controller, err := os2.open(input_file_name)
	if err != nil {
		fmt.eprintf("Could not open controller: %v", err)
		return
	}

	// Step 2: open uinput device
    input_device, errno := linux.open(name = cstring("/dev/uinput"), flags = linux.Open_Flags{.WRONLY, .NONBLOCK})

	fmt.println("Created input_device")

	// Step 4: configure the virtual device
	usetup: uinput_setup
	usetup.id.bustype = BUS_USB
	usetup.id.vendor  = 0x1234
	usetup.id.product = 0x5678


	fmt.println("Configured the virutal device")




	name := "Example Device"
	for i in 0..<len(name) {
	    usetup.name[i] = name[i]
	}
	
	mem.copy(dst = raw_data(usetup.name[:]), src = raw_data(name), len = len(name))

	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_SYN))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_REL))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_KEY))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_RELBIT, uintptr(REL_X))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_RELBIT, uintptr(REL_Y))

	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_SPACE))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_W))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_A))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_S))
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_D))

	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_DEV_SETUP,  cast(uintptr)&usetup)
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_DEV_CREATE, 0)


	// Give user space time to pick up the new device
	time.sleep(1 * time.Millisecond)

	// Step 6: poll the controller and forward events
	ev: input_event

	for {
		n: int
		n, err = os2.read_ptr(controller, &ev, size_of(input_event))
		if n == size_of(ev) {
			if err != nil {
				fmt.eprintf("Could not read controller: %v", err)
				return
			}

			fmt.println(ev)
			check_buttons(ev, input_device)
		}
	}

	// Final step: close devices
	linux.close(input_device)
	os2.close(controller)

	free_all(context.temp_allocator)
}

