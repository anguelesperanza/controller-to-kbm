### Controller to MKB

Converts controller input to mouse and keyboard input

Currenlty Supported Operating Systems:
  Windows
    rely's on Win32 API -- specifically the WORD datatype and the send_input() function
  
Current version: 0.0.1-alpha

Version Desc:

0.0.1-aplha: Technically usuable but realistically, meh, frustaiting to use. Rough around the edges.

Note: Currenlty tested game: Hytale (exploration mode); recommend settings in Hytale: 0.3 for mouse movement (up/down + left/right), Sprint toggle on

Due to using only Hytale as the testing, the controlls are currenlty set for Playing Hytale.
There's plans to have some form of a config file that will be loaded on a per game basis, but I haven't figured that out
nor have I gotten that far yet. Still more stuff to refine first.

## Controlls
DPAD: Up -> Z
      Down -> 0
      Left -> Decrimental (keys 1-9 depending on what the last number was)
      Right -> Incremental (keys 1-9 depending on what the last number was)

Left Thumb Stick: Up - W
                  Down - S
                  Left - A
                  Right - D
                  Press - Left shift
(Does not support diagonal movement)
 
Right Thumb Stick: General Mouse Movement (Does not support diagonal movement, only one direction at a time)

Face (ABXY...): Up: Y
                Down: Space
                Left: F
                Right: Left Control
Start: Escape
Select/Back: M

Currenlty does nothing:
Pressing right thumb stick
Both Triggers

## Known Issues:
Sudden lag spikes
  : Probably caused by calling the send_input() function for win32 like crazy.
      Need to look into way to reduce call count if possible
  : Right thumb stick mouse movement too high depending on wether in game or in menu
      Currenlty, mouse speed in code is set to 0.5, anything lower than that (0.4 onward) the mouse does not move.
      Anything higher, then the mouse zooms all over the place.

## Features in the works (WIP stuff):
Circular Movement for both thumsticks
Better mouse mouse movent when using the right thumb stick
  Would like to find a way to tie it to the computers mouse sensetiity at least
