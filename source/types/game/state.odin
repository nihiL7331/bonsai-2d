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
	camPos:       gmath.Vec2,
	currentScene: ^Scene,
	nextScene:    ^Scene,
}
