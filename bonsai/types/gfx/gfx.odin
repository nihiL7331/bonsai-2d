package gfx

import "bonsai:core/gmath"
import "bonsai:types/game"

// @ref
// Uniform block data uploaded to the GPU for the global shader state.
//
// **Must align to 16 bytes (via std140 Layout Rules)**
ShaderGlobals :: struct #align (16) {
	uViewProjectionMatrix: gmath.Matrix4,
}

// @ref
// A container for all data required to render **a single frame**.
DrawFrame :: struct {
	reset: struct {
		// Dynamic arrays of quads bucketed by DrawLayer
		quads:           [game.DrawLayer][dynamic]Quad,

		// The active coordinate space (camera, projection)
		coordSpace:      CoordSpace,

		// Current layer being drawn to
		activeDrawLayer: game.DrawLayer,

		// Current scissor/clipping rectangle
		activeScissor:   gmath.Rectangle,

		// Global flags applied to all subsequent quads in the batch
		activeFlags:     game.QuadFlags,

		// Shader uniform data
		shaderData:      ShaderGlobals,

		// Tracks which layers need Y-sorting
		sortedLayers:    bit_set[game.DrawLayer],
	},
}

// @ref
// Defines the matrices used for coordinate transformation in a **render pass**.
CoordSpace :: struct {
	projectionMatrix:     gmath.Matrix4,
	cameraMatrix:         gmath.Matrix4, // Model matrix of the camera
	viewProjectionMatrix: gmath.Matrix4, // Projection * Inverse(Camera) (view matrix)
}

// @ref
// A visual quad composed of 4 vertices.
Quad :: [4]Vertex

// @ref
// Represents a single vertex in the sprite batcher.
Vertex :: struct #packed {
	position:      gmath.Vector2,
	color:         gmath.Vector4,
	uv:            gmath.Vector2,
	localUv:       gmath.Vector2,
	size:          gmath.Vector2,
	textureIndex:  u8,
	drawLayer:     u8,
	quadFlags:     game.QuadFlags, // u8
	_:             [1]u8, // Padding to align next Vector4 to 4 byte boundary
	colorOverride: gmath.Vector4,
	parameters:    gmath.Vector4,
}
