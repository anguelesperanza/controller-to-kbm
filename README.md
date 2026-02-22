### Controller input to Mouse and Keyboard Input

This application is meant to run in the background. It converts controller input to mouse and keyboard input.
Currenlty the buttons to KBM are hard coded. There are plans to work on a config file / config system of sorts
so the program can read in a file and set the key mappings that way. But as this is still very early in development
nothing has started on that yet.



# Versions
`Current version` 0.0.2-alpha

`WIP Version` 0.0.3-alpha

`Goal Version` 1.0.0-release


## Supported Operating systems
| OS      | Description                                 |
| ------- | ------------------------------------------- |
| Windows | Requires send_input() function in Win32 API |


## Why no other operating systems.
MacOS: Don't own a Mac

Linux/Unix: It would be complicated to handle input across Wayland and Xlib (at least) as I do swap between the two every so often.
Upon finishing the windows version, but before v1.0.0-release, I want to look into this and see how doable it is.

## Tested Games
| Name         | Settings                                                                            |
| ------------ | ----------------------------------------------------------------------------------- |
| Hytale       | Works but in-game settings may need to be tweaked                                   |
| Menace (Demo)| Super Quick Testing (as I don't know how to play the game)                          |
| New Arc Line | Need v0.0.3-alpha to be finished as current controls don't map to New Arc Line well | 



## WIP Version Goal:

`v0.0.3-alpha` will focues on creating a config based system to allow users to edit the keybindings.

There is still quite a bit of figuring out to do for this so nothing is promised yet until more of this has been figured out.

The rough idea is:

- Config files on a per game basis
- Swapping config files based on active windows (maybe)
- Implementing the remaining controller buttons (right thumbstick press (R3), Triggers)


## Version History

Status: Done, WIP (Work In Progress), NSY (Not Started Yet)

Status | Version       | Description                                                               |
|------|---------------|---------------------------------------------------------------------------|
| Done | 0.0.1-alpha   | First release. Usable, but rough                                          |
| Done | 0.0.2-alpha   | Refined Joystick movement                                                 |
| WIP  | 0.0.3-alpha   | Keymapping configs to change controller mappings on a per game basis      |
| NSY  | -----------   | Whatever number of versions that come before 1.0.0-release                |
| NSY  | 1.0.0-release | Final Version (except for bug fixes). Has all features, all  suppored OS  | 

## Controlls

| Input           | Direction   | Key / Action                                                                              |
|-----------------|-------------|-------------------------------------------------------------------------------------------|
| Dpad            | Up          | Z                                                                                         |
|                 | Down        | 0                                                                                         |
|                 | Left        | Key is either 1 - 9 depending on the last value when the direction was pressed (Decrement)|
|                 | Right       | Key is either 1 - 9 depending on the last value when the direction was pressed (Incremetn)|
| Face            | Up          | Y                                                                                         |
|                 | Down        | Space                                                                                     |
|                 | Left        | F                                                                                         |
|                 | Right       | Left Control                                                                              |
| Left stick      | Up          | W                                                                                         |
|                 | Down        | S                                                                                         |
|                 | Left        | A                                                                                         |
|                 | Right       | D                                                                                         |
|                 | Pressed     | Left Shift                                                                                |
| Right stick     | Mouse Move  | Moves mouse                                                                               |
| Start           | Pressed     | Escape                                                                                    |
| select / back   | Pressed     | M                                                                                         |


## Known Issues:
Sudden lag spikes
  Probably caused by calling the send_input() function for win32 like crazy. Need to test on more games first to be sure. Need to look into way to reduce call count if possible.

The mouse gives for more precise control than a thumbstick can, so some difference in speed/sensitivy is expected. But not
as drastic as it currenlty is. The mouse feel is being compared to how it feels on the ROG Ally using the Desktop control mode.

## Features in the works (WIP stuff):
Creating config based system to load different mapping values.

## Planned Features
Way to load different controller to kbm mappings based on active window.
