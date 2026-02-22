# Wayland Testing

This branch is for seeing testing / research into seeing if wayland support is feasible.
At this time, v0.0.3-alpha is not yet relased however the controller is properly mapped in the WIP branch for v0.0.3-alpha.
Before v1.0.0-release, I want to determine if linux support is viable and implement it if possible.

If Wayland support is feasible then I would like to include it;

This branch is not for testing x11/xlib support


==============================================

Research Notes:
---------------

Wayland doesn't support global hooking into windows like Windows does.
Only feasible way to to use `uinput` and pass values through that.

Need to first however get controller input
  According to: https://stackoverflow.com/questions/54508776/modern-way-to-read-gamepad-input-with-c-on-linux
    - evdev interface: https://www.kernel.org/doc/html/latest/input/joydev/joystick-api.html

evdev:
