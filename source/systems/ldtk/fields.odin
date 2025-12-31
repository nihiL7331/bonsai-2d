package ldtk

import "core:encoding/json"
import "core:strings"

import "../../types/color"
import "../../types/gmath"

getPoint :: proc(
	field: FieldInstance,
	level: Level,
	default: gmath.Vec2 = {0, 0},
) -> (
	gmath.Vec2,
	bool,
) {
	object, isObject := field.value.(json.Object)
	if !isObject do return default, false

	cxValue := object["cx"]
	cyValue := object["cy"]

	cx := int(cxValue.(i64))
	cy := int(cyValue.(i64))

	gridSize := f32(level.layerInstances.?[0].gridSize)

	localX := f32(cx) * gridSize
	localY := f32(cy) * gridSize

	worldX := localX + f32(level.worldPosition.x)
	worldY := localY - f32(level.worldPosition.y)

	finalPosition := gmath.Vec2{worldX, (f32(level.pxHeight) - worldY)}

	return finalPosition, true
}

getField :: proc(field: FieldInstance, level: Level) -> (FieldInstanceType, bool) {
	#partial switch value in field.value {
	case i64:
		return int(value), true
	case f64:
		if field.type == "Int" do return int(value), true
		return f32(value), true
	case bool:
		return value, true
	case string:
		if field.type == "Color" {
			return color.stringHexToRGBA(value), true
		} else {
			return strings.clone(value), true
		}
	case json.Object:
		if field.type == "Point" {
			return getPoint(field, level)
		} else do return {}, false
	case json.Array:
	//TODO:
	}
	assert(false, "Failed to set a custom field value.")

	return {}, false
}
