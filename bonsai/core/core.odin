package core

import "bonsai:core/gmath"
import "bonsai:core/scene/type"

// @ref
// Defines how the game content scales to fit the window aspect ratio.
ScaleMode :: enum {
	// Locks vertical height.
	// Game height is constant, width is matched to fit.
	FixedHeight,
	// Locks horizontal width.
	// Game width is constant, height is matched to fit.
	FixedWidth,
}

// @ref
// The global configuration determining which scaling logic is active.
SCALE_MODE :: ScaleMode.FixedHeight

// @ref
// The internal design resolution width **in pixels**.
GAME_WIDTH :: 480

// @ref
// The internal design resolution height **in pixels**.
GAME_HEIGHT :: 270

WINDOW_TITLE :: "bonsai"

// @ref
// A standard 2D Camera definition.
Camera :: struct {
	position: gmath.Vector2,
	zoom:     f32,
	bounds:   gmath.Rectangle,
}

// @ref
// The core context holding global engine state shared across systems.
// Acts as the bridge between the platform layer (**Sokol**), **core logic**, and **renderer**.
CoreContext :: struct {
	// updated on every window resize event
	windowWidth:  i32, // equal to sokol_app.width()
	windowHeight: i32, // equal to sokol_app.height()

	// .update() and .draw() are called from here
	currentScene: ^type.Scene,
	nextScene:    ^type.Scene,
	camera:       Camera,

	// userData can be used to plug in own game-specific state
	userData:     rawptr,
}

// global singleton storing the engine's core state
// restricted to file scope to force access via the public getter/setter api
@(private = "file")
_coreContext: CoreContext

// Initializes the core context with default values.
// Called by the main.odin file at the very start of initialization.
initCoreContext :: proc(windowWidth, windowHeight: i32) -> ^CoreContext {
	_coreContext.windowWidth = windowWidth
	_coreContext.windowHeight = windowHeight

	return &_coreContext
}

// @ref
// Updates the global core context state.
setCoreContext :: proc(coreContext: CoreContext) {
	_coreContext = coreContext
}

// @ref
// Returns a **pointer** to the global `CoreContext`.
// This is the primary way systems access shared state (Window size, GameState, Input).
getCoreContext :: proc() -> ^CoreContext {
	return &_coreContext
}
