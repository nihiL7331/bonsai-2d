package utils

import game "../types/game"

@(private)
_coreContext: game.CoreContext

setCoreContext :: proc(ctx: game.CoreContext) {
	_coreContext = ctx
}

getCoreContext :: proc() -> ^game.CoreContext {
	return &_coreContext
}
