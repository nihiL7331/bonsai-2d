package camera

import "../../core"
import "../../types/game"
import "../../types/gmath"

import "core:math"

Camera :: struct {
	position:    gmath.Vec2,
	target:      gmath.Vec2,
	followRate:  f32,
	bounds:      Maybe(gmath.Rect),
	shakeAmount: f32,
	shakeTimer:  f32,
}

defaultCamera :: proc() -> Camera {
	return Camera{position = {0, 0}, target = {0, 0}, followRate = 10.0}
}

@(private)
_camera: Camera

setPosition :: proc(position: gmath.Vec2) {
	_camera.position = position
}

follow :: proc(target: gmath.Vec2, rate: f32 = 10.0) {
	_camera.target = target
	_camera.followRate = rate
}

init :: proc() {
	_camera = defaultCamera()
}

update :: proc() {
	coreContext := core.getCoreContext()

	if _camera.followRate > 0 {
		t := 1.0 - math.exp_f32(-_camera.followRate * coreContext.deltaTime)
		_camera.position = math.lerp(_camera.position, _camera.target, t)
	} else {
		_camera.position = _camera.target
	}

	bounds, ok := _camera.bounds.?
	if ok {
		aspect := f32(coreContext.windowWidth) / f32(coreContext.windowHeight)

		halfW := f32(game.GAME_HEIGHT) / 2
		halfH := halfW * aspect

		_camera.position = gmath.Vec2 {
			math.clamp(_camera.position.x, bounds.x + halfW, bounds.z - halfW),
			math.clamp(_camera.position.y, bounds.y + halfH, bounds.w - halfH),
		}
	}

	//NOTE: if anyone does his own camera controller, remember to include this line
	coreContext.gameState.world.cameraPosition = _camera.position

	//TODO:
	// if _camera.shakeTimer > 0 {
	//   _camera.shakeTimer -= dt
	// }
}
