package ldtk

import "../../core"
import "../../core/render"
import "../../types/color"
import "../../types/game"
import "../../types/gmath"

EntitySpawnProc :: #type proc(entityInstance: EntityInstance, layer: LayerInstance, level: Level)

CULLING_TILES :: false // enabled per-tile culling along the per-level one. should benefit performance if levels are big

@(private = "package")
_spriteCache: map[int]game.SpriteName
@(private = "package")
_world: Root
@(private)
_onEntitySpawn: EntitySpawnProc // this has to be set to be called for every entity, allows entity spawning from LDtk directly

init :: proc(worldName: WorldName, callback: EntitySpawnProc) {
	loadData(worldName)
	generateData()
	setEntitySpawner(callback)
	for level in _world.levels do spawnLevelEntities(level)
	render.setClearColor(color.stringHexToRGBA(_world.backgroundColor))
}

setEntitySpawner :: proc(callback: EntitySpawnProc) {
	_onEntitySpawn = callback
}

spawnLevelEntities :: proc(level: Level) {
	if _onEntitySpawn == nil do return

	layers, ok := level.layerInstances.?
	if !ok do return

	for layer in layers {
		entities := layer.entityInstances
		if len(entities) == 0 do continue

		for entity in entities {
			_onEntitySpawn(entity, layer, level)
		}
	}
}

renderLevels :: proc(debug: bool) {
	if len(_world.levels) == 0 do return

	coreContext := core.getCoreContext()
	cameraRect := coreContext.gameState.world.cameraRect

	for level in _world.levels {
		layers, hasLayers := level.layerInstances.?
		if !hasLayers do return

		levelPosition := gmath.Vec2{f32(level.worldPosition.x), f32(level.worldPosition.y)} // we need to convert Vec2Int to Vec2
		levelSize := gmath.Vec2{f32(level.pxWidth), f32(level.pxHeight)}
		levelRect := gmath.rectMake(levelPosition, levelSize)
		if !gmath.rectIntersects(cameraRect, levelRect) do continue

		#reverse for layer in layers {
			if layer.type != "Tiles" && layer.type != "AutoLayer" && layer.type != "IntGrid" {
				continue
			}
			drawTileList(layer.gridTiles, layer, level)
			drawTileList(layer.autoLayerTiles, layer, level)
		}
	}

	if debug do drawDebug()
}

drawDebug :: proc() {
	if len(_world.levels) == 0 do return

	for level in _world.levels {
		for collider in level.colliders {
			render.drawRect(collider, col = {1, 1, 1, 0.2}, culling = true)
		}
	}
}

getColliderRects :: proc(level: Level) -> []gmath.Rect {
	return level.colliders[:]
}
