package core

// @overview
// This package acts as the central hub of the engine.
// Manages global state and configuration. Holds the primary [`CoreContext`](#corecontext).
//
// **Features:**
// - **Global context:** Global engine state shared across all packages via [`getCoreContext`](#getcorecontext).
//   Contains window information, camera and scene data.
// - **Window definition:** Contains the core definitions related to the applications windows,
//   like [`GAME_WIDTH`](#game_width), [`GAME_HEIGHT`](#game_height), [`windowWidth`](#corecontext), [`windowHeight`](#corecontext) and [`WINDOW_TITLE`](#window_title).
// - **Camera definition:** Contains the [`Camera`](#camera) struct definition used to track [`position`](#camera),
//   [`zoom`](#camera) and [`bounds`](#camera) of the camera.
//
// :::note[Usage]
// ```Odin
// update :: proc() {
//   coreContext := core.getCoreContext()
//
//   // The camera follows Pot
//	 t := 1.0 - math.exp_f32(-10 * deltaTime)
//	 coreContext.camera.position = gmath.lerp(coreContext.camera.position, pot.position, t)
//
//   // If pot goes far enough, change the level
//   if pot.position.x > core.GAME_WIDTH {
//      scene.change(.Level2)
//   }
// }
// ```
// :::

import "bonsai:core/gmath"
import "bonsai:core/scene/type"

// @ref
// **On desktop:** Assigns the window name
//
// **On web:** Assings the tab name
WINDOW_TITLE :: "bonsai"

// @ref
// A standard 2D Camera definition.
Camera :: struct {
	position: gmath.Vector2,
	zoom:     f32,
	bounds:   gmath.Rectangle, // world space
}

// @ref
// Returns **game window** bounds (in screen space).
getWindowBounds :: proc() -> gmath.Rectangle {
	size := gmath.getRectangleSize(_coreContext.camera.bounds)
	return gmath.Rectangle{0, 0, size.x, size.y}
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
// Returns a **pointer** to the global [`CoreContext`](#corecontext).
// This is the primary way systems access shared state (Window size, GameState, Input).
getCoreContext :: proc() -> ^CoreContext {
	return &_coreContext
}
