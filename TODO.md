# TODO list

"\*" - core

## TODO

### BUGS

- [ ] atlas packing in cli doesnt happen when files are deleted
  - workaround: delete the atlas file to regenerate it.

### PRIORITY 0

- [ ] collapse types in systems
- [ ] restructure to hide engine core\*
- [ ] controller, touchscreen support\*
- [ ] auto-scaling on immediate ui\*

### PRIORITY 1

- [ ] separate shadow handling (to avoid shadow stacking)\*
- [ ] palette swapping\*
- [ ] particle system
- [ ] entity inspector
- [ ] sloped tiles in LDtk

### PRIORITY 2

- [ ] configuration/settings system (basic api in core)\*
- [ ] debug console\*
  - [ ] fix input consumption for debug ui\*
  - [ ] debug ui text box/number box\*
- [ ] expand feature list of physics system
  - [ ] on collision exit, on collision stay callback
  - [ ] verlet integration
  - [ ] separated axis theorem
  - [ ] circle shape
- [ ] asset hot reloading\*
  - this one is difficult. have to listen to assets/images changes, and on change reload
    atlas, then swap it at runtime. but def worth it
- [ ] ldtk entity custom field array support
- [ ] proper debug inspector using immediate ui for LDtk

### PRIORITY 3

- [ ] steamworks support

### PRIORITY UNKNOWN

- [ ] install utility along side systems

## IN PROGRESS

- [ ] basic physics system
  - [x] swept AABB using Minkowski's difference
  - [x] trigger colliders
  - [x] built-in collision resolution
  - [ ] grid raycast
  - [x] collision layers
  - [x] spatial partitioning
  - [x] on collision enter callback

## DONE

- [x] make systems/camera just a camera controller\*
- [x] rust package manager (v0.1)
- [x] build-time atlas packing\*
- [x] multiple font support\*
- [x] logger\*
- [x] move scenes generation from utils to rust CLI\*
- [x] sokol audio implementation\*
- [x] save/load system\*
  - [x] web localstorage implementation\*
- [x] add better logging and comments\*
- [x] fix entity initialization handling\*
- [x] ldtk support\*
  - [x] parsing JSON
  - [x] rendering tiles
  - [x] collision handling
  - [x] simple culling
  - [x] loading entity custom fields
  - [x] non continuous (warping) level handling
    - technically done, it can be easily implemented by entity uid and level loading
