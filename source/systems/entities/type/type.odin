package entity_type

import "../../../types/game"
import "../../../types/gmath"

MAX_ENTITIES :: 2048

EntityHandle :: struct {
	index: int,
	id:    int,
}

Entity :: struct {
	handle:           EntityHandle,
	kind:             EntityName,
	updateProc:       proc(_: ^Entity),
	drawProc:         proc(_: ^Entity),
	pos:              gmath.Vec2,
	lastKnownXDir:    f32,
	flipX:            bool,
	drawOffset:       gmath.Vec2,
	drawPivot:        gmath.Pivot,
	rotation:         f32,
	hitFlash:         gmath.Vec4,
	sprite:           game.SpriteName,
	animIndex:        int,
	nextFrameEndTime: f64,
	loop:             bool,
	frameDuration:    f32,
	scratch:          struct {
		colOverride: gmath.Vec4,
	},
}

EntityStorage :: struct {
	topCount:     int,
	latestId:     int,
	data:         [MAX_ENTITIES]Entity,
	freeList:     [dynamic]int,
	playerHandle: EntityHandle,
}
