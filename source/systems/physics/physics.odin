package physics

import "../../types/gmath"

import "core:math"

@(private = "package")
_updateColliderRect :: proc(collider: ^Collider) {
	colliderRect := gmath.rectMake(collider.position^, collider.size, collider.pivot)
	colliderRect = gmath.rectShift(colliderRect, collider.offset)
	collider._rect = colliderRect
}

@(private = "package")
_insertCollider :: proc(grid: ^SpatialGrid, collider: ^Collider) {
	targetMap := &grid.dynamicCells
	if collider.isStatic do targetMap = &grid.staticCells

	minX := int(math.floor(collider._rect.x / grid.cellSize))
	minY := int(math.floor(collider._rect.y / grid.cellSize))
	maxX := int(math.floor(collider._rect.z / grid.cellSize))
	maxY := int(math.floor(collider._rect.w / grid.cellSize))

	for x in minX ..= maxX {
		for y in minY ..= maxY {
			key := gmath.Vec2Int{x, y}

			if key not_in targetMap {
				targetMap[key] = make([dynamic]^Collider, 0, 16)
			}
			append(&targetMap[key], collider)
		}
	}
}

@(private = "file")
_checkMap :: proc(
	cells: ^map[[2]int][dynamic]^Collider,
	rect: gmath.Rect,
	cellSize: f32,
	id: u32,
	results: ^[dynamic]^Collider,
) {
	minX := int(math.floor(rect.x / cellSize))
	minY := int(math.floor(rect.y / cellSize))
	maxX := int(math.floor(rect.z / cellSize))
	maxY := int(math.floor(rect.w / cellSize))

	for x in minX ..= maxX {
		for y in minY ..= maxY {
			key := gmath.Vec2Int{x, y}
			if list, ok := cells[key]; ok {
				for collider in list {
					if collider.lastQueryId != id {
						collider.lastQueryId = id
						append(results, collider)
					}
				}
			}
		}
	}
}

@(private = "package")
_queryGrid :: proc(world: ^World, area: gmath.Rect) -> [dynamic]^Collider {
	grid := &world.grid
	results := make([dynamic]^Collider, context.temp_allocator)

	grid.queryId += 1

	_checkMap(&grid.staticCells, area, grid.cellSize, grid.queryId, &results)
	_checkMap(&grid.dynamicCells, area, grid.cellSize, grid.queryId, &results)

	return results
}

// this AABB approach uses Minkowski's difference (implicitly) to ensure proper collision with fast moving objects.
// Instead of calculating an expanded rect it skips that part, since
// expanded.minX - moving.minX = static.minX - moving.width - moving.minX = static.minX - (moving.minX + moving.width) = static.minX - moving.maxX
// similarly for every other axis and case
// via blog.hamaluik.ca/posts/swept-aabb-collision-using-minkowski-difference/
@(private = "package")
_aabb :: proc(moving: gmath.Rect, static: gmath.Rect, velocity: gmath.Vec2) -> Hit {
	hit: Hit

	// raycast against expanded
	inverseEntry: gmath.Vec2 // distance to collision start
	inverseExit: gmath.Vec2 // distance to collision end

	if velocity.x > 0 {
		inverseEntry.x = static.x - moving.z
		inverseExit.x = static.z - moving.x
	} else {
		inverseEntry.x = static.z - moving.x
		inverseExit.x = static.x - moving.z
	}

	if velocity.y > 0 {
		inverseEntry.y = static.y - moving.w
		inverseExit.y = static.w - moving.y
	} else {
		inverseEntry.y = static.w - moving.y
		inverseExit.y = static.y - moving.w
	}

	entry: gmath.Vec2
	exit: gmath.Vec2

	if velocity.x == 0 {
		if (moving.z <= static.x || moving.x >= static.z) {
			hit.valid = false
			return hit
		}
		entry.x = -max(f32)
		exit.x = max(f32)
	} else {
		entry.x = inverseEntry.x / velocity.x
		exit.x = inverseExit.x / velocity.x
	}

	if velocity.y == 0 {
		if (moving.w <= static.y || moving.y >= static.w) {
			hit.valid = false
			return hit
		}
		entry.y = -max(f32)
		exit.y = max(f32)
	} else {
		entry.y = inverseEntry.y / velocity.y
		exit.y = inverseExit.y / velocity.y
	}

	// calculate time (0 - 1)
	entryTime := max(entry.x, entry.y)
	exitTime := min(exit.x, exit.y)

	// no collision if:
	// entry > exit, or
	// started inside, or (handled separately)
	// moving away, or
	// entry > 1.0
	if entryTime > exitTime || (entry.x < 0 && entry.y < 0) || entryTime > 1.0 {
		hit.valid = false // this is already false but to be explicit what happens here its called:p
		return hit
	}

	hit.valid = true
	hit.time = entryTime

	// calculate normal
	// since its AABB, only {-1/0/1, -1/0/1} normals
	if entry.x > entry.y {
		if inverseEntry.x < 0 do hit.normal = gmath.Vec2{1, 0}
		else do hit.normal = gmath.Vec2{-1, 0}
	} else {
		if inverseEntry.y < 0 do hit.normal = gmath.Vec2{0, 1}
		else do hit.normal = gmath.Vec2{0, -1}
	}

	return hit
}

@(private = "package")
_resolveOverlap :: proc(collider: ^Collider, other: ^Collider) {
	colliderCenter := gmath.rectGetCenter(collider._rect)
	otherCenter := gmath.rectGetCenter(other._rect)

	delta := colliderCenter - otherCenter

	colliderSize := gmath.rectSize(collider._rect)
	otherSize := gmath.rectSize(other._rect)

	halfSizeCollider := colliderSize * 0.5
	halfSizeOther := otherSize * 0.5

	overlapX := (halfSizeCollider.x + halfSizeOther.x) - abs(delta.x)
	overlapY := (halfSizeCollider.y + halfSizeOther.y) - abs(delta.y)

	if overlapX > 0 && overlapY > 0 {
		push := gmath.Vec2{0, 0}

		if overlapX < overlapY {
			sign := math.sign(delta.x)
			if sign == 0 do sign = 1
			push.x = overlapX * sign
		} else {
			sign := math.sign(delta.y)
			if sign == 0 do sign = 1
			push.y = overlapY * sign
		}

		collider.position^ += push
		collider._rect = gmath.rectShift(collider._rect, push)
	}
}
