// This file is the entry point for all gameplay code.

package game

import "bonsai:core/clock"
import "bonsai:core/gmath"
import "bonsai:core/render"
init :: proc() {
}

textRotation: gmath.Vector3

update :: proc() {
	deltaTime: f32 = clock.getDeltaTime()
	textRotation.x += deltaTime
	textRotation.y += deltaTime
	textRotation.z += deltaTime
}

draw :: proc() {
	render.setScreenSpace()
	centerCenter := render.getViewportPivot(.centerCenter)
	render.drawText(centerCenter, "test", pivot = .centerCenter, rotation = textRotation)
}

shutdown :: proc() {
}
