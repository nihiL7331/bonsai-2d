package game_types

import "../gmath"

GameState :: struct {
	ticks:           u64,
	gameTimeElapsed: f64,
	camPos:          gmath.Vec2,
	entityTopCount:  int,
	latestEntityId:  int,
	entities:        [MAX_ENTITIES]Entity,
	entityFreeList:  [dynamic]int,
	playerHandle:    EntityHandle,
	scratch:         struct {
		allEntities: []EntityHandle,
	},
}
