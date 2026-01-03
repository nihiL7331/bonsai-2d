# TODO list

## TODO

### BUGS

- [ ] atlas packing in cli doesnt happen when files are deleted
  - workaround: delete the atlas file to regenerate it.

### PRIORITY 0 (v0.1)

### PRIORITY 1 (v0.2)

- [ ] separate shadow handling (to avoid shadow stacking)
- [ ] palette swapping
- [ ] particle system
- [ ] entity inspector
- [ ] sloped tiles in LDtk
- [ ] gamepad support
- [ ] complex, modular touchscreen support
  - a great option would be to implement an api
    allowing to easily create virtual buttons
    and sticks on the screen to be used by a touch screen

### PRIORITY 2 (v0.3)

- [ ] configuration/settings system (basic api in core)
- [ ] debug console
  - [ ] fix input consumption for debug ui
  - [ ] debug ui text box/number box
- [ ] expand feature list of physics system
  - [ ] on collision exit, on collision stay callback
  - [ ] verlet integration
  - [ ] separated axis theorem
  - [ ] circle shape
- [ ] asset hot reloading
  - this one is difficult. have to listen to assets/images changes, and on change reload
    atlas, then swap it at runtime. but def worth it
- [ ] ldtk entity custom field array support
- [ ] proper debug inspector using immediate ui for LDtk

### PRIORITY 3 (v0.4)

- [ ] steamworks support

## IN PROGRESS

- [ ] immediate ui rework
  - [x] robust customization setup
  - [x] proper width handling (with margin and padding)
  - [ ] full pixelcode support (additional glyphs)
  - [ ] scrolling windows
  - [ ] new color picker
  - [ ] proper input consumption
  - [ ] reactive positioning with added objects
  - [ ] borders with opacity
  - [ ] inline text
  - [ ] togglable subheader
  - [ ] checkbox
- [ ] basic physics system
  - [x] swept AABB using Minkowski's difference
  - [x] trigger colliders
  - [x] built-in collision resolution
  - [ ] grid raycast
  - [x] collision layers
  - [x] spatial partitioning
  - [x] on collision enter callback

## DONE

- [x] make systems/camera just a camera controller
- [x] rust package manager (v0.1)
- [x] build-time atlas packing
- [x] multiple font support
- [x] logger
- [x] move scenes generation from utils to rust CLI
- [x] sokol audio implementation
- [x] save/load system
  - [x] web localstorage implementation
- [x] add better logging and comments
- [x] fix entity initialization handling
- [x] ldtk support
  - [x] parsing JSON
  - [x] rendering tiles
  - [x] collision handling
  - [x] simple culling
  - [x] loading entity custom fields
  - [x] non continuous (warping) level handling
    - technically done, it can be easily implemented by entity uid and level loading
- [x] collapse types in systems
- [x] restructure to hide engine core
- [x] add setWorldSpace and setScreenSpace helpers
- [x] move setFont to internal drawText function
- [x] install utility along side systems
- [x] basic touchscreen support (mouse emulation)
- [x] rotation in draw functions
- [x] change icon to pot
- [x] move PixelCode to bonsai/core/ui
- [x] camera rect isn't calculated properly causing culling issues in edge cases (wide monitors)
