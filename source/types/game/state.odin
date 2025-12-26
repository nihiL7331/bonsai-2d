package game_types

import "../gmath"

GameState :: struct {
	time:  TimeState,
	world: ^WorldState,
}

TimeState :: struct {
	ticks:           u64,
	gameTimeElapsed: f64,
}

WorldState :: struct {
	cameraPosition: gmath.Vec2,
	currentScene:   ^Scene,
	nextScene:      ^Scene,
}
