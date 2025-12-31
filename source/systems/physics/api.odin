package physics

import "../../core/render"
import "../../types/color"
import "../../types/gmath"

import "core:log"

DRAW_DEBUG :: true

// WORLD API

initWorld :: proc(
	cellSize: int = 128,
	reserveCapacity: int = 100,
	allocator := context.allocator,
) -> ^World {
	world := new(World, allocator)

	world.grid.cellSize = f32(cellSize)
	world.grid.queryId = 0

	world.grid.staticCells = make(map[[2]int][dynamic]^Collider, 16, allocator)
	world.grid.dynamicCells = make(map[[2]int][dynamic]^Collider, 16, allocator)

	world.colliders = make([dynamic]^Collider, 0, reserveCapacity, allocator)

	world.cursor = 0

	return world
}

updateWorld :: proc(world: ^World, deltaTime: f32) {
	//create spatial grid
	for _, &list in world.grid.dynamicCells do clear(&list)
	for collider in world.colliders {
		if !collider.isStatic do _insertCollider(&world.grid, collider)
	}

	//update physics and draw if debug
	for collider in world.colliders {
		if !collider.isStatic do updateCollider(world, collider, deltaTime)
	}
}

drawWorld :: proc(world: ^World) {
	if !DRAW_DEBUG do return
	for collider in world.colliders {
		drawDebugCollider(collider)
	}
}

destroyWorld :: proc(world: ^World) {
	if world == nil do return

	for collider in world.colliders {
		free(collider)
	}
	delete(world.colliders)

	for _, list in world.grid.staticCells {
		delete(list)
	}
	delete(world.grid.staticCells)

	free(world)
}

// COLLIDERS API

newCollider :: proc {
	newColliderWithVelocityAndPositionPointers,
	newColliderWithVelocityPointer,
	newColliderWithPositionPointer,
	newColliderWithNoPointers,
}

newColliderWithVelocityAndPositionPointers :: proc(
	world: ^World,
	positionPointer: ^gmath.Vec2,
	velocityPointer: ^gmath.Vec2,
	size: gmath.Vec2 = {0, 0},
	offset: gmath.Vec2 = {0, 0},
	pivot: gmath.Pivot = gmath.Pivot.bottomLeft,
	tag: string = "Default",
	layer: CollisionLayer = DEFAULT_LAYER,
	mask: CollisionLayer = DEFAULT_MASK,
	isTrigger: bool = false,
	isStatic: bool = false,
	userData: rawptr = nil,
	debugColor: gmath.Vec4 = color.WHITE,
	onCollisionEnter: CollisionCallback = nil,
) -> ^Collider {
	collider := new(Collider)

	collider.id = world.cursor
	collider.tag = tag
	collider.layer = layer
	collider.mask = mask
	collider.isTrigger = isTrigger
	collider.isStatic = isStatic
	collider.position = positionPointer
	collider.velocity = velocityPointer
	collider.userData = userData
	collider.debugColor = debugColor
	collider._rect = _getColliderRect(collider.position, size, offset, pivot)
	collider.onCollisionEnter = onCollisionEnter

	append(&world.colliders, collider)
	world.cursor += 1

	_insertCollider(&world.grid, collider)

	return collider
}

newColliderWithVelocityPointer :: proc(
	world: ^World,
	position: gmath.Vec2,
	velocityPointer: ^gmath.Vec2,
	size: gmath.Vec2 = {0, 0},
	offset: gmath.Vec2 = {0, 0},
	pivot: gmath.Pivot = gmath.Pivot.bottomLeft,
	tag: string = "Default",
	layer: CollisionLayer = DEFAULT_LAYER,
	mask: CollisionLayer = DEFAULT_MASK,
	isTrigger: bool = false,
	isStatic: bool = false,
	userData: rawptr = nil,
	debugColor: gmath.Vec4 = color.WHITE,
	onCollisionEnter: CollisionCallback = nil,
) -> ^Collider {
	collider := new(Collider)

	collider.id = world.cursor
	collider.tag = tag
	collider.layer = layer
	collider.mask = mask
	collider.isTrigger = isTrigger
	collider.isStatic = isStatic
	collider.position = new(gmath.Vec2)
	collider.position^ = position
	collider.velocity = velocityPointer
	collider.userData = userData
	collider.debugColor = debugColor
	collider._rect = _getColliderRect(collider.position, size, offset, pivot)
	collider.onCollisionEnter = onCollisionEnter

	append(&world.colliders, collider)
	world.cursor += 1

	_insertCollider(&world.grid, collider)

	return collider
}

newColliderWithPositionPointer :: proc(
	world: ^World,
	positionPointer: ^gmath.Vec2,
	velocity: gmath.Vec2 = {0, 0},
	size: gmath.Vec2 = {0, 0},
	offset: gmath.Vec2 = {0, 0},
	pivot: gmath.Pivot = gmath.Pivot.bottomLeft,
	tag: string = "Default",
	layer: CollisionLayer = DEFAULT_LAYER,
	mask: CollisionLayer = DEFAULT_MASK,
	isTrigger: bool = false,
	isStatic: bool = false,
	userData: rawptr = nil,
	debugColor: gmath.Vec4 = color.WHITE,
	onCollisionEnter: CollisionCallback = nil,
) -> ^Collider {
	collider := new(Collider)

	collider.id = world.cursor
	collider.tag = tag
	collider.layer = layer
	collider.mask = mask
	collider.isTrigger = isTrigger
	collider.isStatic = isStatic
	collider.position = positionPointer
	collider.velocity = new(gmath.Vec2)
	collider.velocity^ = velocity
	collider.userData = userData
	collider.debugColor = debugColor
	collider._rect = _getColliderRect(collider.position, size, offset, pivot)
	collider.onCollisionEnter = onCollisionEnter

	append(&world.colliders, collider)
	world.cursor += 1

	_insertCollider(&world.grid, collider)

	return collider
}

newColliderWithNoPointers :: proc(
	world: ^World,
	position: gmath.Vec2,
	velocity: gmath.Vec2 = {0, 0},
	size: gmath.Vec2 = {0, 0},
	offset: gmath.Vec2 = {0, 0},
	pivot: gmath.Pivot = gmath.Pivot.bottomLeft,
	tag: string = "Default",
	layer: CollisionLayer = DEFAULT_LAYER,
	mask: CollisionLayer = DEFAULT_MASK,
	isTrigger: bool = false,
	isStatic: bool = false,
	userData: rawptr = nil,
	debugColor: gmath.Vec4 = color.WHITE,
	onCollisionEnter: CollisionCallback = nil,
) -> ^Collider {
	collider := new(Collider)

	collider.id = world.cursor
	collider.tag = tag
	collider.layer = layer
	collider.mask = mask
	collider.isTrigger = isTrigger
	collider.isStatic = isStatic
	collider.position = new(gmath.Vec2)
	collider.position^ = position
	collider.velocity = new(gmath.Vec2)
	collider.velocity^ = velocity
	collider.userData = userData
	collider.debugColor = debugColor
	collider._rect = _getColliderRect(collider.position, size, offset, pivot)
	collider.onCollisionEnter = onCollisionEnter

	append(&world.colliders, collider)
	world.cursor += 1

	_insertCollider(&world.grid, collider)

	log.infof(
		"Created new collider at X: %v, Y: %v, SX: %v, SY: %v",
		position.x,
		position.y,
		size.x,
		size.y,
	)

	return collider
}

//NOTE: if you already call updateWorld, dont call this function
updateCollider :: proc(world: ^World, collider: ^Collider, deltaTime: f32) {
	if collider.velocity == nil || collider.position == nil do return

	// first check if is in a wall,
	// Minkowski's difference doesnt handle that edge case well
	startOverlaps := _queryGrid(world, collider._rect)
	for other in startOverlaps {
		if other == collider do continue
		if other.isTrigger do continue
		if card(collider.mask & other.layer) == 0 do continue
		if card(other.mask & collider.layer) == 0 do continue

		_resolveOverlap(collider, other)
	}

	velocity := collider.velocity^ * deltaTime
	remainingTime := f32(1.0)

	// go 3 frames into the future
	for _ in 0 ..< 3 {
		queryRect := gmath.rectShift(collider._rect, velocity)
		nearby := _queryGrid(world, queryRect)

		earliestHit: Hit
		earliestHit.time = 1.0 // by default we move the full distance

		// we iterate only through nearby colliders to check for collisions
		// via spatial grid/hashmap
		for other in nearby {
			if other == collider do continue // we skip ourselfes
			if other.isTrigger do continue // dont resolve collisions with trigger colliders
			if card(collider.mask & other.layer) == 0 do continue
			if card(other.mask & collider.layer) == 0 do continue

			// swept aabb
			hit := _aabb(collider._rect, other._rect, velocity)

			if hit.valid && hit.time < earliestHit.time {
				earliestHit = hit

				center := gmath.rectGetCenter(collider._rect)
				earliestHit.position = center + (velocity * hit.time)

				if collider.onCollisionEnter != nil {
					collider.onCollisionEnter(collider, other)
				}
				if other.onCollisionEnter != nil {
					other.onCollisionEnter(other, collider)
				}
			}
		}

		// move furthest we can (to the earliest collision)
		moveAmount := velocity * earliestHit.time
		collider.position^ += moveAmount
		collider._rect = gmath.rectShift(collider._rect, moveAmount)

		if !earliestHit.valid do break

		// movement after collision
		remainingTime -= earliestHit.time
		if remainingTime <= 0 do break

		dot := velocity.x * earliestHit.normal.x + velocity.y * earliestHit.normal.y
		remainingVelocity := gmath.Vec2 {
			velocity.x - earliestHit.normal.x * dot,
			velocity.y - earliestHit.normal.y * dot,
		}

		velocity = remainingVelocity * remainingTime

		if earliestHit.normal.x != 0 {
			collider.velocity.x = 0
		}
		if earliestHit.normal.y != 0 {
			collider.velocity.y = 0
		}
	}
}

destroyCollider :: proc(world: ^World, collider: ^Collider) {
	for col, index in world.colliders {
		if col == collider {
			unordered_remove(&world.colliders, index)
			break
		}
	}
	free(collider)
}

drawDebugCollider :: proc(collider: ^Collider) {
	render.drawRect(collider._rect, col = collider.debugColor, culling = true)
}

// CHECK API

// checkPoint :: proc(world: ^World, point: gmath.Vec2) -> bool {
//
// }
//
// checkRect :: proc(world: ^World, rect: gmath.Rect) -> bool {
//
// }
//
// raycast :: proc(world: ^World, start: gmath.Vec2, end: gmath.Vec2) -> bool {
//
// }
