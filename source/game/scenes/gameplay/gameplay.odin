package gameplay

import "../../../core/render"
import prefabs "../../../game/entities"
import "../../../systems/camera"
import "../../../systems/entities"
import entityType "../../../systems/entities/type"
import "../../../systems/ldtk"
import ldtkType "../../../systems/ldtk/type"
import "../../../types/gmath"

import "core:log"
import "core:reflect"

Data :: struct {}

init :: proc(data: rawptr) {
	// state := (^Data)(data)

	//NOTE: uncomment the line above, if you want to send data between functions in that scene.
	//it's as easy as declaring it in the struct above, doing state.var = "xyz" in one function
	//and accessing it via the same name in another function.

	entities.entityInitCore()
	ldtk.init(.test, onEntitySpawn)

	camera.init()
}

update :: proc(data: rawptr) {
	// state := (^Data)(data)

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
	entities.drawAll()
}

exit :: proc(data: rawptr) {
	// state := (^Data)(data)

	entities.cleanup()
}

onEntitySpawn :: proc(
	entityInstance: ldtkType.EntityInstance,
	layer: ldtkType.LayerInstance,
	level: ldtkType.Level,
) {
	type, ok := reflect.enum_from_name(entityType.EntityName, entityInstance.identifier)
	if !ok {
		log.infof("Couldn't spawn entity ID %v. (Enum not found)", entityInstance.identifier)
	}

	position := gmath.Vec2 {
		f32(entityInstance.worldPosition.x),
		f32(entityInstance.worldPosition.y),
	}
	data: entityType.EntityData
	data.position = position

	customFields := entityInstance.customFields
	for key, customField in customFields {
		data.fields[key] = entityType.FieldValue(customField)
	}

	prefabs.spawn[type](data)
}
