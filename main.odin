package main

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

// KEYS
KEY_SPACE :: 57

EVIOCGNAME :: 0x82004506  // example, depends on arch

_IOC_DIRSHIFT  :: 30
_IOC_TYPESHIFT :: 8
_IOC_NRSHIFT   :: 0
_IOC_SIZESHIFT :: 16

_IOC_WRITE :: 1

UINPUT_IOCTL_BASE :: u64('U')


UI_SET_EVBIT :: (_IOC_WRITE << _IOC_DIRSHIFT) |
                (UINPUT_IOCTL_BASE << _IOC_TYPESHIFT) |
                (u64(100) << _IOC_NRSHIFT) |
                (u64(size_of(int)) << _IOC_SIZESHIFT)

BUS_USB :: 0x03


// @(default_calling_convention="c")
// foreign libc {
// }
TimeVal :: struct {
	tv_sec:i64,
	tv_usec:i64,
}


input_event :: struct {
	time: TimeVal,
	type: u16,
	code: u16,
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
import "core:os/os2"
import "core:c/libc"
import "core:sys/linux" // ioctl
import "core:sys/posix" // opening a file that returns a file descriptor

check_buttons :: proc(event_code:u16, event_value:i32) {
	switch event_code {
		// Face buttons
		case 304:
			if event_value == 1 do fmt.println("Face Button Down Pressed")
		case 305:
			if event_value == 1 do fmt.println("Face Button Right Pressed")
		case 307:
			if event_value == 1 do fmt.println("Face Button Left Pressed")
		case 308:
			if event_value == 1 do fmt.println("Face Button Up Pressed")

		// Dpad
		case 16:
			if event_value == 1 do fmt.println("DPAD Right Pressed")
			if event_value == -1 do fmt.println("DPAD Left Pressed")
		case 17:
			if event_value == 1 do fmt.println("DPAD Down Pressed")
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

// emit :: proc(fd: ^os2.file, type:u16, code:u16, value:i32)
// {
//    ie:input_event;

//    ie.type = type;
//    ie.code = code;
//    ie.value = value;
//    /* timestamp values below are ignored */
//    ie.time.tv_sec = 0;
//    ie.time.tv_usec = 0;

//    write(fd, &ie, sizeof(ie));
// }


main :: proc() {
	// Step 1: the controller monitoring
	controller, err := os2.open("/dev/input/event8")

	if err != nil {
		fmt.eprintf("Could not open controller: %v", err)
		return
	}

	// Step 2: input device used that will send commands to the compsitor (wayland)
	//    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	input_device := posix.open(path = "/dev/uinput", flags = posix.O_Flags{.WRONLY, .NONBLOCK})


	// open :: proc(path: cstring, flags: O_Flags, #c_vararg mode: ..mode_t) -> FD ---

	// Step 3: Use ioctl to setup the commands for the input device

	// posix FD and linux Fd are the datatype: i32 -- but each is a distinct so casting to the other
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, EV_KEY)
	linux.ioctl(cast(linux.Fd)input_device, cast(u32)UI_SET_EVBIT, KEY_SPACE)

	usetup:uinput_setup
	usetup.id.bustype = BUS_USB
	usetup.id.vendor = 0x1234


	//    memset(&usetup, 0, sizeof(usetup));
	//    usetup.id.bustype = BUS_USB;
	//    usetup.id.vendor = 0x1234; /* sample vendor */
	//    usetup.id.product = 0x5678; /* sample product */
	//    strcpy(usetup.name, "Example device");

	//    ioctl(fd, UI_DEV_SETUP, &usetup);
	//    ioctl(fd, UI_DEV_CREATE);


	// Step 4: Create the input event instance and query the controller
	ev: input_event

	for {
		n:int
		n, err = os2.read_ptr(controller, &ev, size_of(input_event))
		if n == size_of(ev) {
		
			if err != nil {
				fmt.eprintf("Could not open controller: %v", err)
				return
			}

			check_buttons(ev.code, ev.value)
		}
	}

	// Final Step: Close out the input device and controller
	posix.close(input_device)
	os2.close(controller)
	
}

/*Below is the c code example from kernal docs*/


// int main(void)
// {
//    struct uinput_setup usetup;

//    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);


//    /*
//     * The ioctls below will enable the device that is about to be
//     * created, to pass key events, in this case the space key.
//     */
//    ioctl(fd, UI_SET_EVBIT, EV_KEY);
//    ioctl(fd, UI_SET_KEYBIT, KEY_SPACE);

//    memset(&usetup, 0, sizeof(usetup));
//    usetup.id.bustype = BUS_USB;
//    usetup.id.vendor = 0x1234; /* sample vendor */
//    usetup.id.product = 0x5678; /* sample product */
//    strcpy(usetup.name, "Example device");

//    ioctl(fd, UI_DEV_SETUP, &usetup);
//    ioctl(fd, UI_DEV_CREATE);

//    /*
//     * On UI_DEV_CREATE the kernel will create the device node for this
//     * device. We are inserting a pause here so that userspace has time
//     * to detect, initialize the new device, and can start listening to
//     * the event, otherwise it will not notice the event we are about
//     * to send. This pause is only needed in our example code!
//     */
//    sleep(1);

//    /* Key press, report the event, send key release, and report again */
//    emit(fd, EV_KEY, KEY_SPACE, 1);
//    emit(fd, EV_SYN, SYN_REPORT, 0);
//    emit(fd, EV_KEY, KEY_SPACE, 0);
//    emit(fd, EV_SYN, SYN_REPORT, 0);

//    /*
//     * Give userspace some time to read the events before we destroy the
//     * device with UI_DEV_DESTOY.
//     */
//    sleep(1);

//    ioctl(fd, UI_DEV_DESTROY);
//    close(fd);

//    return 0;
// }
