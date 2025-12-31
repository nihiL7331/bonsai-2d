package ldtk

import "bonsai:core/render"
import "bonsai:types/game"
import "bonsai:types/gmath"

import "core:fmt"
import "core:log"
import "core:reflect"

// get tile in atlas from unique id of tileset and tile id grabbed from LDtk data
getTileSprite :: proc(tilesetUid: int, tileId: int) -> game.SpriteName {
	cacheKey := (tilesetUid << 32) | tileId
	if sprite, found := _spriteCache[cacheKey]; found {
		return sprite
	}

	tilesetName := ""
	for def in _world.definitions.tilesets {
		if def.uid == tilesetUid {
			tilesetName = def.identifier
			break
		}
	}
	if tilesetName == "" do return game.SpriteName.nil // not found
	// this slow lookup happens only once per sprite/tile, then it's added to fast cache
	enumString := fmt.tprintf("%s_%d", tilesetName, tileId)

	value, ok := reflect.enum_from_name(game.SpriteName, enumString)
	if !ok { 	// failed to get enum from name
		log.warnf("Sprite not found: %v", enumString)
		_spriteCache[cacheKey] = game.SpriteName.nil
		return game.SpriteName.nil
	}

	sprite := game.SpriteName(value)
	_spriteCache[cacheKey] = sprite
	return sprite
}

// draw a "type" of tiles (grid, autolayer)
drawTileList :: proc(tiles: Maybe([dynamic]TileInstance), layer: LayerInstance, level: Level) {
	tileList, ok := tiles.?
	if !ok || len(tileList) == 0 do return

	gridSize := layer.gridSize
	tilesetUid, exists := layer.tilesetDefinitionUid.?
	if !exists {
		log.error("Tileset definition doesn't exist.")
		return
	}

	for tile in tileList {
		sprite := getTileSprite(tilesetUid, tile.tileId)
		if sprite == game.SpriteName.nil do continue

		localX := tile.pxPosition[0]
		localY := tile.pxPosition[1]

		ldtkX := level.worldPosition.x + localX

		pos := gmath.Vec2Int {
			ldtkX + gridSize / 2,
			level.pxHeight - localY + level.worldPosition.y - gridSize / 2,
		}

		flipX := Flip.flipX in tile.flip
		flipY := Flip.flipY in tile.flip

		flipMatrix := gmath.Mat4(1)
		if flipY {
			flipMatrix = gmath.xFormScale({1.0, -1.0})
		}

		render.drawSprite(
			position = gmath.Vec2{f32(pos.x), f32(pos.y)},
			sprite = sprite,
			flipX = flipX,
			xForm = flipMatrix,
			col = gmath.Vec4{1, 1, 1, tile.opacity * layer.opacity},
			culling = CULLING_TILES,
		)
	}
}

getCollisionAt :: proc(position: gmath.Vec2Int, level: Level) -> int {
	layers, ok := level.layerInstances.?
	if !ok do return 0

	collisionLayer: ^LayerInstance = nil
	for &layer in layers {
		if layer.identifier == "Collisions" || layer.type == "IntGrid" {
			collisionLayer = &layer
			break
		}
	}
	if collisionLayer == nil do return 0

	csv := collisionLayer.intGrid
	if len(csv) == 0 do return 0

	gridSize := collisionLayer.gridSize

	ldtkX := position.x
	ldtkY := level.pxHeight - position.y

	gridX := ldtkX / gridSize
	gridY := ldtkY / gridSize

	index := gridY * collisionLayer.gridWidth + gridX

	if index >= 0 && index < len(csv) {
		return csv[index]
	}

	return 0
}

getEntity :: proc(uid: string) -> ^EntityInstance {
	return _world.entities[uid]
}
