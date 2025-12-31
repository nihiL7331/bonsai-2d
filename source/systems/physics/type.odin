package physics

import "../../types/gmath"

DEFAULT_LAYER :: CollisionLayer{.Default}
DEFAULT_MASK :: CollisionLayer{.Default}

CollisionCallback :: #type proc(self: ^Collider, other: ^Collider)

CollisionLayerValue :: enum {
	Default,
}

CollisionLayer :: bit_set[CollisionLayerValue]

SpatialGrid :: struct {
	cellSize:     f32,
	staticCells:  map[[2]int][dynamic]^Collider,
	dynamicCells: map[[2]int][dynamic]^Collider,
	queryId:      u32,
}

World :: struct {
	colliders: [dynamic]^Collider,
	cursor:    u32,
	grid:      SpatialGrid,
}

Collider :: struct {
	id:               u32,
	lastQueryId:      u32,
	layer:            CollisionLayer,
	mask:             CollisionLayer,
	tag:              string,
	isTrigger:        bool,
	isStatic:         bool,
	onCollisionEnter: CollisionCallback,
	// onCollisionStay: CollisionCallback, //TODO:
	// onCollisionExit: CollisionCallback, //TODO:
	position:         ^gmath.Vec2, // NOTE: they are pointers
	velocity:         ^gmath.Vec2,
	debugColor:       gmath.Vec4,
	userData:         rawptr,
	_rect:            gmath.Rect, // helper values, not recommended to edit
}

// result of a collision check
Hit :: struct {
	valid:    bool,
	time:     f32, // 0.0 -> +1.0
	normal:   gmath.Vec2, // normal of face we hit
	position: gmath.Vec2, // collision point
}
