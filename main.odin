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
// import "core:c/libc"
import "core:sys/linux"
// import "core:sys/posix"


emit :: proc(fd: linux.Fd, type: u16, code: u16, value: i32) {
	ie: input_event
	ie.type  = type
	ie.code  = code
	ie.value = value

    buf := mem.byte_slice(&ie, size_of(input_event))
    _, _ = linux.write(fd, buf)

}

check_buttons :: proc(event_code: u16, event_value: i32, input_device: linux.Fd) {
	switch event_code {
		// Face buttons
		case 304:
			if event_value == 1 {
				fmt.println("Face Button Down Pressed")
				emit(input_device, EV_KEY, KEY_SPACE, 1)
				emit(input_device, EV_SYN, SYN_REPORT, 0)
			} else {
				emit(input_device, EV_KEY, KEY_SPACE, 0)
				emit(input_device, EV_SYN, SYN_REPORT, 0)
			}

		case 305:
			if event_value == 1 do fmt.println("Face Button Right Pressed")
		case 307:
			if event_value == 1 do fmt.println("Face Button Left Pressed")
		case 308:
			if event_value == 1 do fmt.println("Face Button Up Pressed")

		// Dpad
		case 16:
			if event_value == 1  do fmt.println("DPAD Right Pressed")
			if event_value == -1 do fmt.println("DPAD Left Pressed")
		case 17:
			if event_value == 1  do fmt.println("DPAD Down Pressed")
			if event_value == -1 do fmt.println("DPAD Up Pressed")

		// Bumpers
		case 310:
			if event_value == 1 do fmt.println("Bumper Left Pressed")
		case 311:
			if event_value == 1 do fmt.println("Bumper Right Pressed")

		// Triggers
		case 2:
			if event_value == 255 do fmt.println("Trigger Left Fully Pressed")
		case 5:
			if event_value == 255 do fmt.println("Trigger Right Fully Pressed")

		// select
		case 314:
			if event_value == 1 do fmt.println("Select Pressed")
		// start
		case 315:
			if event_value == 1 do fmt.println("Start Pressed")
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

			if strings.trim_null(string(buf[:])) == name {
				return file.fullpath
			}

		}
	}

	return ""
}


/*BELOW IS WORKING MAIN: Uncomment once find out way to get propery input event*/

main :: proc() {
	// Step 1: open the controller (this changed from event8 to event12 when I restared. Need a better way to set)
	controller_name := "Generic X-Box pad" 
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

	// Step 3: register EV_KEY event type, then the specific key we want
	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT,  uintptr(EV_KEY))
	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_SPACE))
	ret1 := linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_SYN))
	fmt.println("SET_EVBIT EV_SYN:", ret1)

	ret2 := linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_KEY))
	fmt.println("SET_EVBIT EV_KEY:", ret2)

	fmt.println("Registered EV_KEY events")

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

	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_DEV_SETUP,  cast(uintptr)&usetup)

	// // Step 5: create the device (no data argument needed, pass 0)
	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_DEV_CREATE, 0)

	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_SYN))
	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, uintptr(EV_KEY))
	// linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_SPACE))

	ret3 := linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_KEYBIT, uintptr(KEY_SPACE))
	fmt.println("SET_KEYBIT KEY_SPACE:", ret3)

	ret4 := linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_DEV_SETUP, cast(uintptr)&usetup)
	fmt.println("DEV_SETUP:", ret4)

	ret5 := linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_DEV_CREATE, 0)
	fmt.println("DEV_CREATE:", ret5)


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

			// fmt.println(ev)
			check_buttons(ev.code, ev.value, input_device)
		}
	}

	// Final step: close devices
	linux.close(input_device)
	os2.close(controller)

	free_all(context.temp_allocator)
}

