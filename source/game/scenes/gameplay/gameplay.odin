package gameplay

import "../../../core/render"
import prefabs "../../../game/entities"
import "../../../systems/camera"
import "../../../systems/entities"
import "../../../systems/ldtk"

Data :: struct {}

init :: proc(data: rawptr) {
	// state := (^Data)(data)

	//NOTE: uncomment the line above, if you want to send data between functions in that scene.
	//it's as easy as declaring it in the struct above, doing state.var = "xyz" in one function
	//and accessing it via the same name in another function.

	entities.entityInitCore()
	player := prefabs.spawnPlayer()
	entities.setPlayerHandle(player.handle)
	prefabs.spawnThing()
	ldtk.loadData(.test)

	camera.init()
}

update :: proc(data: rawptr) {
	// state := (^Data)(data)

	entities.updateAll()

	player := entities.getPlayer()
	camera.follow(player.pos)
	camera.update()
}

draw :: proc(data: rawptr) {
	// state := (^Data)(data)

	render.getDrawFrame().reset.sortedLayers = {.playspace, .shadow}

	render.setCoordSpace(render.getWorldSpace())
	ldtk.renderLevels()
	entities.drawAll()
}

exit :: proc(data: rawptr) {
	// state := (^Data)(data)

	entities.cleanup()
}
