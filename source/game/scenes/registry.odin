package scenes

import "../../types/game"

import "../../core/scene"

import "gameplay"
import "splash"

@(private)
_splashData: splash.Data
@(private)
_gameplayData: gameplay.Data

initRegistry :: proc() {
	scene.register(
		game.SceneKind.Splash,
		game.Scene {
			data = &_splashData,
			init = splash.init,
			update = splash.update,
			draw = splash.draw,
			exit = splash.exit,
		},
	)
	scene.register(
		game.SceneKind.Gameplay,
		game.Scene {
			init = gameplay.init,
			update = gameplay.update,
			draw = gameplay.draw,
			exit = gameplay.exit,
		},
	)
}
