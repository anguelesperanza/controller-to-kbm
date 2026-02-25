# Wayland Testing

This branch is for seeing testing / research into seeing if wayland support is feasible.
At this time, v0.0.3-alpha is not yet relased however the controller is properly mapped in the WIP branch for v0.0.3-alpha.
Before v1.0.0-release, I want to determine if linux support is viable and implement it if possible.

If Wayland support is feasible then I would like to include it;

This branch is not for testing x11/xlib support


==============================================

Due to either Wayland being Wayland, or Cosmic DE being in Beta, the device was not properly sticking as being a mouse and keyboard device.
As such, had to add the device to the udev list of controlls.

had to add example-device rule: SUBSYSTEM=="input", ATTRS{name}=="Example Device", ENV{ID_INPUT_MOUSE}="1", ENV{ID_INPUT_KEY}="1"
to this file: sudo nano /etc/udev/rules.d/99-example-device.rules

This tells linux that the device is both a mouse and a keyboard

Had to reload: sudo udevadm control --reload-rules
sudo udevadm trigger

Depending on the system, this may not be required and sudo ./name-of-application should be fine.


## Result of Research:

Should be possible to add Wayland support. And since thse way the input is sent is through kernal level feautres,
it should work on other DEs, not just Wayland. However current version of PopOS only has Cosmic DE so I can't really tell.

This is just an assumption. There's far too many DE's to just know if it will work across the board, as such, the linux development branch with be suffixed with -wayand.

Next Development Version: v0.0.4-wayland 

Research Notes:
---------------

Running right now requires building the application `odin build .` and then runing the application with sudo `sudo ./controller-to-kbm`
This is probably because my user account isn't in the right user groupd right now. Will need to figure this out though.

Wayland doesn't support global hooking into windows like Windows does.
Only feasible way to to use `uinput` and pass values through that.

Need to first however get controller input
  According to: https://stackoverflow.com/questions/54508776/modern-way-to-read-gamepad-input-with-c-on-linux
    - evdev interface: https://www.kernel.org/doc/html/latest/input/joydev/joystick-api.html



# Path to sending into to active window (according to copilot + stack overflow)
evdev → your mapper → uinput → compositor → focused window
1       2             3        4            5



Currenlty I can read input from the controller:
Parts 1 and 2 are done (for the tests at least)

Need parts 3, 4, 5


Permissions: Either add to: sudo usermod -aG input $USER or use sudo

According to Kernal Docs: https://kernel.org/doc/html/v4.12/input/uinput.html
However that requires a dependecy; goal is to have as little dependencies as possible
such that the application can be built using:

`odin build .` or ran with `odin run .` out of the box

For testing, will try using just uinput but may swich to libevdev (need bindings)
if needed/required

	Controller layout (evdev)

	Face:

	Up
		- Pressed
			code = 308, value = 1
		- Released 
			code = 308, value = 0
	Down
		- Pressed
			code = 304, value = 1
		- Released 
			code = 304, value = 0
	Left
		- Pressed
			code = 307, value = 1
		- Released 
			code = 307, value = 0
	Right
		- Pressed
			code = 305, value = 1
		- Released 
			code = 305, value = 0

	Dpad

	Up
		- Pressed
			code = 17 , value = -1
		- Released 
			code = 17, value = 0
	Down
		- Pressed
			code = 17, value = 1
		- Released 
			code = 17, value = 0
	Left
		- Pressed
			code = 16, value = -1
		- Released 
			code = 16, value = 0
	Right
		- Pressed
			code = 16, value = 1
		- Released 
			code = 16, value = 0

	Joystick:
	left
	right

	Bumpers
	left
		- Pressed
			code = 310, value = 1
		- Released 
			code = 310, value = 0

	right
		- Pressed
			code = 311, value = 1
		- Released 
			code = 311, value = 0

	Triggers:
	left
		- Pressed
			code = 2, value = 1..=255
		- Released 
			code = 2, value = 0
	right
		- Pressed
			code = 5, value = 1..=255
		- Released 
			code = 5, value = 0

	start

		- Pressed
			code = 315, value = 1
		- Released 
			code = 315, value = 0

	select
		- Pressed
			code = 314, value = 1
		- Released 
			code = 314, value = 0

