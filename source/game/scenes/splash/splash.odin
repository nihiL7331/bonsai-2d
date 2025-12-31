package splash

import "bonsai:core/input"
import "bonsai:core/render"
import "bonsai:core/scene"
import "bonsai:systems/tween"
import "bonsai:types/game"
import "bonsai:types/gmath"

Data :: struct {
	logoAlpha: f32,
}

init :: proc(data: rawptr) {
	state := (^Data)(data)
	state.logoAlpha = 0.0
	onEnd := proc(data: rawptr) {scene.change(game.SceneName.gameplay)}
	t1 := tween.to(&state.logoAlpha, 1.0, 3.0, ease = gmath.EaseName.InSine)
	t2 := tween.to(&state.logoAlpha, 0.0, 2.0, ease = gmath.EaseName.OutSine, onEnd = onEnd)
	tween.then(t1, t2)
}

update :: proc(data: rawptr) {
	// state := (^Data)(data)

	if input.anyKeyPressAndConsume() {
		scene.change(game.SceneName.gameplay)
	}
}

draw :: proc(data: rawptr) {
	state := (^Data)(data)
	render.setCoordSpace(render.getScreenSpace())

	centerCenter := render.screenPivot(gmath.Pivot.centerCenter)
	render.drawSprite(
		centerCenter,
		game.SpriteName.bonsai_logo,
		col = gmath.Vec4{1.0, 1.0, 1.0, state.logoAlpha},
	)
}

exit :: proc(data: rawptr) {
	// state := (^Data)(data)

}
