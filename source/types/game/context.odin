package game_types

GAME_WIDTH :: 480
GAME_HEIGHT :: 270

CoreContext :: struct {
	gameState:    ^GameState,
	deltaTime:    f32,
	appTicks:     u64,
	windowWidth:  i32,
	windowHeight: i32,
}
