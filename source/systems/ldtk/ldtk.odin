package ldtk

import "../../core/render"
import "../../types/color"
import "../../types/game"
import "../../types/gmath"
import "type"

import "core:log"

EntitySpawnProc :: #type proc(
	entityInstance: type.EntityInstance,
	layer: type.LayerInstance,
	level: type.Level,
)

@(private = "package")
_spriteCache: map[int]game.SpriteName
@(private = "package")
_world: type.Root
@(private)
_onEntitySpawn: EntitySpawnProc // this has to be set to be called for every entity, allows entity spawning from LDtk directly

init :: proc(worldName: type.WorldName, callback: EntitySpawnProc) {
	loadData(worldName)
	setEntitySpawner(callback)
	for level in _world.levels do spawnLevelEntities(level)
	render.setClearColor(color.stringHexToRGBA(_world.backgroundColor))
}

setEntitySpawner :: proc(callback: EntitySpawnProc) {
	_onEntitySpawn = callback
}

spawnLevelEntities :: proc(level: type.Level) {
	if _onEntitySpawn == nil do return

	layers, ok := level.layerInstances.?
	if !ok do return

	for layer in layers {
		entities := layer.entityInstances
		if len(entities) == 0 do continue

		for entity in entities {
			_onEntitySpawn(entity, layer, level)
			log.infof(
				"Spawned entity ID: %v at X: %v Y: %v",
				entity.identifier,
				entity.worldPosition.x,
				entity.worldPosition.y,
			)
		}
	}
}

renderLevels :: proc(debug: bool) {
	if len(_world.levels) == 0 do return

	for level in _world.levels {
		layers, hasLayers := level.layerInstances.?
		if !hasLayers do return

		#reverse for layer in layers {
			if layer.type != "Tiles" && layer.type != "AutoLayer" && layer.type != "IntGrid" {
				continue
			}
			drawTileList(layer.gridTiles, layer, level)
			drawTileList(layer.autoLayerTiles, layer, level)
			if debug do drawDebug(level)
		}
	}
}

drawDebug :: proc(level: type.Level) {
	if len(_world.levels) == 0 do return

	tileSize: int = 8
	for y := 0; y < level.pxHeight; y += int(tileSize) {
		for x := 0; x < level.pxWidth; x += int(tileSize) {
			testPos := gmath.Vec2Int{x + tileSize / 2, y + tileSize / 2}

			val := getCollisionAt(testPos, level)

			if val == 1 {
				render.drawRectXForm(
					xForm = gmath.xFormTranslate(
						{f32(x + level.worldPosition.x), f32(y + level.worldPosition.y)},
					),
					size = {f32(tileSize), f32(tileSize)},
					col = {1, 0, 0, 0.5},
					texIndex = 255,
				)
			}
		}
	}
}
