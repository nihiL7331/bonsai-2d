package core

import game "bonsai:types/game"

@(private = "file")
_coreContext: game.CoreContext

initCoreContext :: proc() -> ^game.CoreContext {
	_coreContext.windowWidth = 1280
	_coreContext.windowHeight = 720
	return &_coreContext
}

setCoreContext :: proc(coreContext: game.CoreContext) {
	_coreContext = coreContext
}

getCoreContext :: proc() -> ^game.CoreContext {
	return &_coreContext
}

getDeltaTime :: proc() -> f32 {
	return _coreContext.deltaTime
}
