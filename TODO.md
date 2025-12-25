# TODO list

"\*" - core

## TODO

### BUGS

- [ ] player teleports to (0,0) after a couple of seconds, probably a tweening issue

### PRIORITY 0

- [ ] add better logging and comments\*
- [ ] controller, touchscreen support\*
- [ ] web localstorage implementation\*
- [ ] save/load system\*
- [ ] ldtk support\*
- [ ] basic aabb rework (swept?)\*
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
  - [ ] automatically sized debug ui\*
  - [ ] debug ui text box/number box\*
- [ ] make own/implement box2d for physics
  - [ ] spatial hash grid for collisions
- [ ] asset hot reloading\*
  - this one is difficult. we have to listen to assets/images changes, and on change reload
    atlas, then swap it at runtime. but def worth it

### PRIORITY 3

- [ ] steamworks support

## IN PROGRESS

- [ ] sokol audio implementation\*

## DONE

- [x] make systems/camera just a camera controller\*
- [x] rust package manager (v0.1)
- [x] build-time atlas packing\*
- [x] multiple font support\*
- [x] logger\*
- [x] move scenes generation from utils to rust CLI\*
