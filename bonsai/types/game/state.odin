package game_types

import "bonsai:core/gmath"

// @ref
// The top-level container for all game-specific data.
// **This struct is persistent across scenes**.
GameState :: struct {
	world: ^WorldState,
}

// @ref
// Contains the state of the physical game world.
WorldState :: struct {
	cameraPosition:  gmath.Vector2,
	cameraRectangle: gmath.Rectangle, // The world space bounds currently visible
	currentScene:    ^Scene, // The currently active scene logic
	nextScene:       ^Scene, // The pending scene (if transition is queued)
}
