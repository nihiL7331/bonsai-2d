package game_types

CoreContext :: struct {
	gameState: ^GameState,
	deltaTime: f32,
	appTicks:  u64,
}
