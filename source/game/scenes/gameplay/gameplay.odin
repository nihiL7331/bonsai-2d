package gameplay

import "../../../core"
import "../../../core/render"
import "../../../systems/camera"
import "../../../systems/entities"
import "../../../systems/ldtk"
import "../../../systems/physics"
import "../../../types/gmath"
import prefabs "../../entities"
import "../../globals"

import "core:log"
import "core:reflect"

Data :: struct {}

init :: proc(data: rawptr) {
	// state := (^Data)(data)

	//NOTE: uncomment the line above, if you want to send data between functions in that scene.
	//it's as easy as declaring it in the struct above, doing state.var = "xyz" in one function
	//and accessing it via the same name in another function.

	globals.physicsWorld = physics.initWorld()
	entities.entityInitCore()
	ldtk.init(.test, onEntitySpawn)

	camera.init()
}

update :: proc(data: rawptr) {
	// state := (^Data)(data)
	deltaTime := core.getDeltaTime()

	physics.updateWorld(globals.physicsWorld, deltaTime)
	entities.updateAll()

	player := entities.getPlayer()
	camera.follow(player.position)
	camera.update()
}

draw :: proc(data: rawptr) {
	// state := (^Data)(data)

	render.getDrawFrame().reset.sortedLayers = {.playspace, .shadow}

	render.setCoordSpace(render.getWorldSpace())
	ldtk.renderLevels(true)
	physics.drawWorld(globals.physicsWorld)
	entities.drawAll()
}

exit :: proc(data: rawptr) {
	// state := (^Data)(data)

	entities.cleanup()
}

onEntitySpawn :: proc(
	entityInstance: ldtk.EntityInstance,
	layer: ldtk.LayerInstance,
	level: ldtk.Level,
) {
	type, ok := reflect.enum_from_name(entities.EntityName, entityInstance.identifier)
	if !ok {
		log.infof("Couldn't spawn entity ID %v. (Enum not found)", entityInstance.identifier)
	}

	position := gmath.Vec2 {
		f32(entityInstance.worldPosition.x),
		f32(entityInstance.worldPosition.y),
	}
	data: entities.EntityData
	data.position = position

	customFields := entityInstance.customFields
	for key, customField in customFields {
		data.fields[key] = entities.FieldValue(customField)
	}

	prefabs.spawn[type](data)
}
