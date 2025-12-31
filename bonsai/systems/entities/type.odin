package entities

import "bonsai:types/game"
import "bonsai:types/gmath"

MAX_ENTITIES :: 2048

EntityHandle :: struct {
	index: int,
	id:    int,
}

Entity :: struct {
	handle:           EntityHandle,
	name:             EntityName,
	updateProc:       proc(_: ^Entity),
	drawProc:         proc(_: ^Entity),
	position:         gmath.Vec2,
	velocity:         gmath.Vec2,
	lastKnownXDir:    f32,
	flipX:            bool,
	drawOffset:       gmath.Vec2,
	drawPivot:        gmath.Pivot,
	rotation:         f32,
	hitFlash:         gmath.Vec4,
	sprite:           game.SpriteName,
	animationIndex:   int,
	nextFrameEndTime: f64,
	looping:          bool,
	frameDuration:    f32,
	scratch:          struct {
		colorOverride: gmath.Vec4,
	},
}

EntityStorage :: struct {
	topCount:     int,
	latestId:     int,
	data:         [MAX_ENTITIES]Entity,
	freeList:     [dynamic]int,
	playerHandle: EntityHandle,
}

EntityData :: struct {
	// data array that we pass on spawn
	position: gmath.Vec2,
	fields:   map[string]FieldValue, // this can be used to e.g. pass custom fields from LDtk, simiarly with Tiled
}

FieldValue :: union {
	int,
	f32,
	bool,
	string,
	gmath.Vec2,
	gmath.Vec4, // for color
}

SpawnProc :: #type proc(data: EntityData) -> ^Entity
