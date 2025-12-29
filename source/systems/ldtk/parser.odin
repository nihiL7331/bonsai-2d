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
