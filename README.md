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
| Hytale         | Works well. Ingame settings may need to be tweaked to liking                      |
| Menace (Demo)  | Super Quick Testing (as I don't know how to play the game)                        |
| New Arc Line   | Works well. No noticable perforamnce difference                                   | 
| Demonologist   | Works well. No big performance lags, but there was some screen tearing            |
| Relative Frame | Incorrect inputs are registering. Need to look into more to find out the reason   |
| R.E.P.O        | Works fine. Passed the tutorial using controller                                  |



## WIP Version Goal:

`v0.0.3-alpha` will focues on creating a config based system to allow users to edit the keybindings.

There is still quite a bit of figuring out to do for this so nothing is promised yet until more of this has been figured out.

The rough idea is:

- [x]Config files on a per game basis
- [x]Implementing the remaining controller buttons (right thumbstick press (R3), Triggers)

## Version History

Status: Done, WIP (Work In Progress), NSY (Not Started Yet)

Status | Version       | Description                                                               |
|------|---------------|---------------------------------------------------------------------------|
| Done | 0.0.1-alpha   | First release. Barely Usable, but rough                                   |
| Done | 0.0.2-alpha   | Refined Joystick movement                                                 |
| WIP  | 0.0.3-alpha   | Keymapping configs to change controller mappings on a per game basis      |
|      |               | Accidentely fixed lag issue (so far) with Hytle by reducing calls         |
| NSY  | 0.0.4-wayland | Implemen Wayland (Linux) support                                          |
| NSY  | 0.0.5-ui      | Add Graphical User Interface                                              |
| NSY  | 0.0.x-testing | Properly try out the tool with different games and adjust as needed       |
| NSY  | -----------   | Whatever number of versions that come before 1.0.0-release                |
| NSY  | 1.0.0-release | Final Version (except for bug fixes). Has all features, all  suppored OS  | 

## Controls (Default)

When no maped config file is provided, these are the default controls.
(They were the original controls used when testing Hytale at the start of this tools development).

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

## Features in the works (WIP stuff):
Creating config based system to load different mapping values.

## Planned Features
Way to load different controller to kbm mappings based on active window.
