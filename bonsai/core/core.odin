package core

import "bonsai:types/game"

// global singleton storing the engine's core state
// restricted to file scope to force access via the public getter/setter api
@(private = "file")
_coreContext: game.CoreContext

// @ref
// Initializes the core context with **default** values.
// Called by the **main.odin** file at the very start of initialization.
initCoreContext :: proc(windowWidth, windowHeight: i32) -> ^game.CoreContext {
	_coreContext.windowWidth = windowWidth
	_coreContext.windowHeight = windowHeight

	return &_coreContext
}

// @ref
// Updates the global core context state.
// Typically used by the platform layer to push
// window resize events or input state updates into the core engine.
setCoreContext :: proc(coreContext: game.CoreContext) {
	_coreContext = coreContext
}

// @ref
// Returns a **pointer** to the global **CoreContext**.
// This is the primary way systems access shared state (Window size, GameState, Input).
getCoreContext :: proc() -> ^game.CoreContext {
	return &_coreContext
}
