package gameplay

import "../../../core"
import "../../../core/render"

import prefabs "../../../game/entities"

import "../../../systems/camera"
import "../../../systems/entities"

import "../../../types/game"
import "../../../types/gmath"

import "core:math/linalg"

Data :: struct {}

init :: proc(data: rawptr) {
	// state := (^Data)(data)
	coreContext := core.getCoreContext()

	player := prefabs.spawnPlayer()
	coreContext.gameState.world.playerHandle = player.handle
	prefabs.spawnThing()

	camera.init()
}

update :: proc(data: rawptr) {
	// state := (^Data)(data)
	coreContext := core.getCoreContext()

	entities.updateAll()

	player := entities.entityFromHandle(coreContext.gameState.world.playerHandle)
	camera.follow(player.pos)
	camera.update()
}

draw :: proc(data: rawptr) {
	// state := (^Data)(data)
	render.getDrawFrame().reset.sortedLayers = {.playspace, .shadow}

	drawBackgroundLayer()

	render.setCoordSpace(camera.getWorldSpace())
	entities.drawAll()
}

exit :: proc(data: rawptr) {
	// state := (^Data)(data)
}

drawBackgroundLayer :: proc() {
	drawFrame := render.getDrawFrame()

	drawFrame.reset.shaderData.ndcToWorldXForm =
		camera.getWorldSpaceCamera() * linalg.inverse(camera.getWorldSpaceProj())
	drawFrame.reset.shaderData.bgRepeatTexAtlasUv = render.atlasUvFromSprite(
		game.SpriteName.bg_repeat_tex0,
	)
	render.setCoordSpace()

	render.drawRect(
		gmath.Rect{-1, -1, 1, 1},
		flags = game.QuadFlags.backgroundPixels,
		zLayer = game.ZLayer.background,
	)
}
