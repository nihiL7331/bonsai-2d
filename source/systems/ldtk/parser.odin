package ldtk

import "core:encoding/json"
import "core:log"
import "core:mem"

import io "../../core/platform"
import "../../types/gmath"
import type "type"

@(private)
_ldtkArena: mem.Dynamic_Arena
@(private)
_ldtkArenaInitialized: bool


loadData :: proc(name: type.WorldName) -> bool {
	if name == type.WorldName.nil {
		log.error("nil world can't be loaded.")
		return false
	}

	path := type.worldFilename[name]
	bytes, success := io.read_entire_file(path)
	if !success {
		log.errorf("Failed to read world file: %v.", name)
		return false
	}
	defer delete(bytes)

	if !_ldtkArenaInitialized {
		mem.dynamic_arena_init(&_ldtkArena, context.allocator)
		_ldtkArenaInitialized = true
	} else {
		mem.dynamic_arena_free_all(&_ldtkArena)
	}

	context.allocator = mem.dynamic_arena_allocator(&_ldtkArena)

	error := json.unmarshal(bytes, &_world)
	if error != nil {
		log.errorf("JSON parsing error for %v: %v", path, error)
		return false
	}

	calculateWorldPosition()

	return true
}

unloadData :: proc() {
	if _ldtkArenaInitialized {
		mem.dynamic_arena_destroy(&_ldtkArena)
		_ldtkArenaInitialized = false
	}
}

calculateWorldPosition :: proc() {
	worldPosition := gmath.Vec2Int{0, 0}
	for &level in _world.levels {
		if _world.worldLayout == type.WorldLayout.Free ||
		   _world.worldLayout == type.WorldLayout.GridVania {
			level.worldPosition = gmath.Vec2Int{level.rawWorldX, -level.rawWorldY}
			calculateWorldEntityPosition(level)
			continue
		}

		level.worldPosition = worldPosition
		calculateWorldEntityPosition(level)


		if _world.worldLayout == type.WorldLayout.LinearHorizontal do worldPosition += gmath.Vec2Int{level.pxWidth, 0}
		else if _world.worldLayout == type.WorldLayout.LinearVertical do worldPosition -= gmath.Vec2Int{0, level.pxHeight}
	}
}

calculateWorldEntityPosition :: proc(level: type.Level) {
	layers, ok := level.layerInstances.?
	if ok {
		for layer in layers {
			entities := layer.entityInstances
			if len(entities) == 0 do continue

			for &entity in entities {
				entity.worldPosition = gmath.Vec2Int {
					level.worldPosition.x + entity.pxPosition[0],
					level.worldPosition.y + level.pxHeight - entity.pxPosition[1],
				}
			}
		}
	}
}

generateWorldColliders :: proc() {
	for &level in _world.levels {
		colliders := make([dynamic]gmath.Rect)

		layers, ok := level.layerInstances.?
		if !ok {
			level.colliders = colliders
			continue
		}

		grid: [dynamic]int
		gridWidth: int
		gridHeight: int
		gridSize: f32

		found := false
		for layer in layers {
			if layer.type == "IntGrid" && layer.identifier == type.COLLISIONS_LAYER_IDENTIFIER {
				grid = layer.intGrid
				gridWidth = layer.gridWidth
				gridHeight = layer.gridHeight
				gridSize = f32(layer.gridSize)
				found = true
				break
			}
		}
		if !found || len(grid) == 0 {
			level.colliders = colliders
			continue
		}

		for y := 0; y < gridHeight; y += 1 {
			startX := -1

			for x := 0; x < gridWidth; x += 1 {
				index := y * gridWidth + x
				value := grid[index]

				isWall := (value == type.INTGRID_WALL_VALUE)
				if isWall && startX == -1 do startX = x
				else if !isWall && startX != -1 {
					position := gmath.Vec2{f32(level.worldPosition.x) + f32(startX) * gridSize, f32(level.worldPosition.y) - f32(y + 1 - gridHeight) * gridSize}
					size := gmath.Vec2{f32(x - startX) * gridSize, gridSize}
					// size := gmath.Vec2{8.0, 8.0}
					rect := gmath.rectMake(position, size)
					log.infof("Found collider X: %v Y: %v, W: %v, H: %v", position.x, position.y, size.x, size.y)
					append(&colliders, rect)
					startX = -1
				}
			}
			// if row has finished and didn't create the collider yet
			if startX != -1 {
				position := gmath.Vec2 {
					f32(level.worldPosition.x) + f32(startX) * gridSize,
					f32(level.worldPosition.y) - f32(y + 1 - gridHeight) * gridSize,
				}
				size := gmath.Vec2{f32(gridWidth - startX) * gridSize, gridSize}
				rect := gmath.rectMake(position, size)
				log.infof(
					"Found collider X: %v Y: %v, W: %v, H: %v",
					position.x,
					position.y,
					size.x,
					size.y,
				)
				append(&colliders, rect)
			}
		}

		level.colliders = colliders
	}
}
