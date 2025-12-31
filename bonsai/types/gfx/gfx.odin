package gfx

import "bonsai:types/game"
import "bonsai:types/gmath"

ShaderGlobals :: struct {
	ndcToWorldXForm:    gmath.Mat4,
}

DrawFrame :: struct {
	reset: struct {
		quads:         [game.ZLayer][dynamic]Quad,
		coordSpace:    CoordSpace,
		activeZLayer:  game.ZLayer,
		activeScissor: gmath.Rect,
		activeFlags:   game.QuadFlags,
		shaderData:    ShaderGlobals,
		sortedLayers:  bit_set[game.ZLayer],
	},
}

CoordSpace :: struct {
	proj:     gmath.Mat4,
	camera:   gmath.Mat4,
	viewProj: gmath.Mat4,
}

Quad :: [4]Vertex
Vertex :: struct {
	position:      gmath.Vec2,
	color:         gmath.Vec4,
	uv:            gmath.Vec2,
	localUv:       gmath.Vec2,
	size:          gmath.Vec2,
	textureIndex:  u8,
	zLayer:        u8,
	quadFlags:     game.QuadFlags,
	_:             [1]u8,
	colorOverride: gmath.Vec4,
	parameters:    gmath.Vec4,
}
