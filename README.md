### Controller to MKB

Converts controller input to mouse and keyboard input

## Supported Operating systems
| OS      | Description                                 |
| ------- | ------------------------------------------- |
| Windows | Requires send_input() function in Win32 API |

## Tested Games
| Name   | Settings                                               |
| -------| -------------------------------------------------------|
| Hytale | Mouse Movement in game settings: 0.3, sprint on toggle.

## Version History

`Current version` 0.0.1-alpha

`WIP Version` 0.0.2-alpha

`Goal Version` 1.0.0-release

Status: Done, WIP (Work In Progress), NSY (Not Started Yet)

Status | Version     | Description                           |
|------|-------------|---------------------------------------|
| Done | 0.0.1-alpha | First release. Usable, but rough      |
| WIP  | 0.0.2-alhpa | Refined input movement                |

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
  Probably caused by calling the send_input() function for win32 like crazy. Need to test on more games first to be sure.
  
  Need to look into way to reduce call count if possible.

  Right thumb stick mouse movement too high depending on wether in game or in menu
  
  Currenlty, mouse speed in code is set to 0.5, anything lower than that (0.4 onward) the mouse does not move.
  Anything higher, then the mouse zooms all over the place.
  This mouse speed is **not** the the same as mouse sentivity set by the OS.
  
  The mouse gives for more precise control than a thumbstick can, so some difference in speed/sensitivy is expected. But not
  as drastic as it currenlty is. The mouse feel is being compared to how it feels on the ROG Ally using the Desktop control mode.

## Features in the works (WIP stuff):
Circular Movement for both thumsticks as right now, both thumbsticks move in a very square like pattern.
Way to load different controller to kbm mappings based on active window.
