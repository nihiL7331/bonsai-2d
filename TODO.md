# TODO list

"\*" - core

## TODO

### BUGS

- [ ] atlas packing in cli doesnt happen when files are deleted

### PRIORITY 0

- [ ] restructure to hide engine core\*
- [ ] basic aabb rework (swept?)\*
- [ ] controller, touchscreen support\*
- [ ] auto-scaling on immediate ui\*

### PRIORITY 1

- [ ] separate shadow handling (to avoid shadow stacking)\*
- [ ] palette swapping\*
- [ ] particle system
- [ ] entity inspector

### PRIORITY 2

- [ ] configuration/settings system (basic api in core)\*
- [ ] debug console\*
  - [ ] fix input consumption for debug ui\*
  - [ ] debug ui text box/number box\*
- [ ] make own/implement box2d for physics
  - [ ] spatial hash grid for collisions
- [ ] asset hot reloading\*
  - this one is difficult. we have to listen to assets/images changes, and on change reload
    atlas, then swap it at runtime. but def worth it

### PRIORITY 3

- [ ] steamworks support

### PRIORITY UNKNOWN

- [ ] install utility along side systems

## IN PROGRESS

- [ ] ldtk support\*
  - [x] parsing JSON
  - [x] rendering tiles
  - [x] collision handling
  - [ ] simple culling
  - [ ] non continuous (warping) level handling (?)
  - [ ] runtime level loading
  - [ ] debug inspector
  - [ ] remove capitalization (project settings)

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
