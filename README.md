### Controller input to Mouse and Keyboard Input

This is a small application that allows a controller to be used as a mouse and keyboard. This application is meant for playing games that do not have controller support.
Currenlty works on windows however the process is not easy

To run the application, you much launch it from the terminal `./controller-to-kbm.exe {name of the config to run}` for example `./controller-to-kbm.exe config/repo.ini`

# Versions
`Current version` 0.0.3-alpha

`WIP Version` 0.0.4-wayland

`Goal Version` 1.0.0-release


## Supported Operating systems
| OS      | Description                                 |
| ------- | ------------------------------------------- |
| Windows | Requires send_input() function in Win32 API |


## Why no other operating systems.
MacOS: Don't own a Mac

Linux: WIP Build. Did some testing on seems possible. Going to try an proper implementation.
If all pans well, Linux support will be done before v1.0.0-release.

## Tested Games
| Name            | Settings                                                                            |
| --------------- | ----------------------------------------------------------------------------------- |
| Hytale (survival) | Works well. Ingame settings may need to be tweaked to liking                      |
| Menace (Demo)     | Super Quick Testing (as I don't know how to play the game)                        |
| New Arc Line      | Works well. No noticable perforamnce difference                                   | 
| Demonologist      | Works well. No big performance lags, but there was some screen tearing            |
| Relative Frame    | Incorrect inputs are registering. Issues with game even on mouse and keyboard     |
| R.E.P.O           | Works fine. Played a round just fine                                              |

## Versions (Past Current Future) 

Status: Done, WIP (Work In Progress), NSY (Not Started Yet)

Status | Version       | Description                                                               |
|------|---------------|---------------------------------------------------------------------------|
| Done | 0.0.1-alpha   | First release. Barely Usable, but rough                                   |
| Done | 0.0.2-alpha   | Refined Joystick movement                                                 |
| Done  | 0.0.3-alpha  | Keymapping configs to change controller mappings on a per game basis      |
|      |               | Accidentely fixed lag issue (so far) with Hytle by reducing calls         |
| WIP  | 0.0.4-wayland | Implemen Wayland (Linux) support                                          |
| NSY  | 0.0.5-ui      | Add Graphical User Interface                                              |
| NSY  | 0.1.0-beta    | Properly try out the tool with different games and adjust as needed       |
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
