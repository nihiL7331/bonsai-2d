// @overview
// This package contains the definitions for the `bonsai:core/scene` package.
// It's separated to avoid a circular dependency issue.

package scene_types

/// @ref
// Represents a self-contained game state.
// Uses an approach where each scene defines its own **lifecycle procedures**
// and passes a **pointer** to its own persistent data.
Scene :: struct {
	// Pointer to the scene-specific data struct.
	// This is passed back to every lifecycle procedure (init, update, draw, exit).
	data:   rawptr,

	// Called once when the scene becomes active.
	// Use this to reset state, load level-specific resources, etc.
	init:   proc(data: rawptr),

	// Called every frame to handle game logic, input and physics.
	update: proc(data: rawptr),

	// Called every frame after update to handle rendering.
	draw:   proc(data: rawptr),

	// Called once before the scene is swapped out for a new one.
	// Use this to clean up resources or save state.
	exit:   proc(data: rawptr),
}
