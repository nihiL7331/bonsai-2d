package game_types

// @ref
// The internal design resolution width **in pixels**.
// The game renders to this fixed size, which is then **upscaled to fit the physical window**.
GAME_WIDTH :: 480

// @ref
// The internal design resolution height **in pixels**.
GAME_HEIGHT :: 270

// @ref
// The core context holding global engine state shared across systems.
// Acts as the bridge between the platform layer (**Sokol**), **core logic**, and **renderer**.
CoreContext :: struct {
	gameState:        ^GameState,
	applicationTicks: u64,
	windowWidth:      i32,
	windowHeight:     i32,
}
