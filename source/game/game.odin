// This file is the entry point for all gameplay code.

package game

import "bonsai:core"
import "bonsai:core/input"
import "bonsai:core/render"
import "bonsai:core/scene"
import "bonsai:core/ui"
import "bonsai:systems/entities"
import "bonsai:systems/ldtk"
import "bonsai:systems/tween"
import "bonsai:types/color"
import "bonsai:types/game"
import "bonsai:types/gmath"

import "core:fmt"

VERSION :: "v0.0.0"
WINDOW_TITLE :: "Blueprint"

init :: proc() {
	ui.init()
	scene.init(game.SceneName.gameplay)
}

update :: proc() {
	scene.update()
	tween.update()
}

draw :: proc() {
	scene.draw()
	drawUiLayer()
}

shutdown :: proc() {
	ldtk.unloadData()
}

drawUiLayer :: proc() {
	coreContext := core.getCoreContext()
	player := entities.getPlayer()

	render.setCoordSpace(render.getScreenSpace())

	bottomLeft := render.screenPivot(gmath.Pivot.bottomLeft)

	ui.begin(input.getScreenMousePos())
	if ui.Window(
		"Debug Player",
		gmath.rectMake(bottomLeft, gmath.Vec2{80, 100}),
		pivot = gmath.Pivot.bottomLeft,
	) {
		if ui.Button("Reset Player Pos") {
			tween.to(&player.position, gmath.Vec2{0.0, 0.0}, 1.0, ease = gmath.EaseName.InOutQuad)
		}
		ui.Button("Test2")
	}
	ui.end()

	topRight := render.screenPivot(gmath.Pivot.topRight)
	fpsText := fmt.tprintf("FPS: %.2f", 1.0 / coreContext.deltaTime)
	render.drawText(
		topRight - 2,
		fpsText,
		.alagard,
		15,
		scale = 0.5,
		zLayer = game.ZLayer.ui,
		pivot = gmath.Pivot.topRight,
		col = color.WHITE,
	)
}
