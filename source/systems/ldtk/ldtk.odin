package ldtk

import "../../types/game"

@(private = "package")
_spriteCache: map[int]game.SpriteName

@(private = "package")
_project: Root

renderLevels :: proc() {
	if len(_project.levels) == 0 do return
	for level in _project.levels {
		layers, hasLayers := level.layerInstances.?
		if !hasLayers do return

		levelHeight := level.pxHeight

		#reverse for layer in layers {
			if layer.type != "Tiles" && layer.type != "AutoLayer" && layer.type != "IntGrid" {
				continue
			}
			drawTileList(layer.gridTiles, layer, levelHeight)
			drawTileList(layer.autoLayerTiles, layer, levelHeight)
		}
	}
}
