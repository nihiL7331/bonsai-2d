package ldtk

import "../../core/render"
import "../../types/game"
import "../../types/gmath"

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
	for def in _project.definitions.tilesets {
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
drawTileList :: proc(tiles: Maybe([dynamic]TileInstance), layer: LayerInstance, levelHeight: int) {
	tileList, ok := tiles.?
	if !ok || len(tileList) == 0 do return

	gridSize := f32(layer.gridSize)
	tilesetUid, exists := layer.tilesetDefinitionUid.?
	if !exists {
		log.error("Tileset definition doesn't exist.")
		return
	}

	for tile in tileList {
		sprite := getTileSprite(tilesetUid, tile.tileId)
		if sprite == game.SpriteName.nil do continue

		ldtkX := f32(tile.pxPosition[0])
		ldtkY := f32(tile.pxPosition[1])

		pos := gmath.Vec2{ldtkX, f32(levelHeight) - ldtkY - gridSize}

		//TODO: y flip
		flipX := Flip.flipX in tile.flip
		flipY := Flip.flipY in tile.flip

		flipMatrix := gmath.Mat4(1)
		if flipY {
			flipMatrix = gmath.xFormScale({1.0, -1.0})
		}

		drawOffset := gmath.Vec2{gridSize * 0.5, gridSize * 0.5}

		render.drawSprite(
			pos = pos + drawOffset,
			sprite = sprite,
			flipX = flipX,
			xForm = flipMatrix,
		)
	}
}
