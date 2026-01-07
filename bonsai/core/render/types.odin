package render

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"

import sokol_gfx "bonsai:libs/sokol/gfx"
import stb_truetype "bonsai:libs/stb/truetype"

// @ref
// Maximum number of quads per batch flush.
//
// **Increase if you see "Quad buffer full" warnings, decrease to save memory.**
MAX_QUADS :: 8192

// @ref
// Default UV coordinates covering the full texture (0,0 to 1,1).
DEFAULT_UV :: gmath.Vector4{0, 0, 1, 1}

// @ref
// Default clear color **(background)**.
CLEAR_COLOR :: colors.BLACK

// @ref
// Internal render state wrapping **Sokol** pipelines and bindings.
RenderState :: struct {
	passAction: sokol_gfx.Pass_Action,
	pipeline:   sokol_gfx.Pipeline,
	bindings:   sokol_gfx.Bindings,
}

// @ref
// Tracks the state of the scissor test (clipping).
ScissorState :: struct {
	enabled:     bool,
	coordinates: gmath.Vector4,
}

// @ref
// Represents the global sprite atlas.
Atlas :: struct {
	view: sokol_gfx.View,
}

// size constraints for the font bitmap texture.
BITMAP_WIDTH :: 512
BITMAP_HEIGHT :: 512

// texture index for font atlas
FONT_TEXTURE_INDEX: u8 : 1

// @ref
// Represents a loaded and baked font **ready for rendering**.
Font :: struct {
	texture:       sokol_gfx.Image,
	view:          sokol_gfx.View,
	characterData: [96]stb_truetype.bakedchar,
	name:          string,
}

// @ref
// Uniform block data uploaded to the GPU for the global shader state.
//
// **Must align to 16 bytes (via std140 Layout Rules)**
ShaderGlobals :: struct #align (16) {
	uViewProjectionMatrix: gmath.Matrix4,
}

// @ref
// Bit flags for special rendering behaviors in the shader.
//
// **Currently unused by the core**.
QuadFlags :: enum u8 {
	flag1 = (1 << 0),
	flag2 = (1 << 1),
}

// @ref
// Defines the rendering order **(Z-sorting)**.
// Layers are **drawn from top to bottom** (nil first, top last).
DrawLayer :: enum u8 {
	nil,
	background,
	shadow,
	playspace,
	vfx,
	ui,
	tooltip,
	pauseMenu,
	top,
}

// @ref
// A container for all data required to render **a single frame**.
DrawFrame :: struct {
	reset: struct {
		// Dynamic arrays of quads bucketed by DrawLayer
		quads:           [DrawLayer][dynamic]Quad,

		// The active coordinate space (camera, projection)
		coordSpace:      CoordSpace,

		// Current layer being drawn to
		activeDrawLayer: DrawLayer,

		// Current scissor/clipping rectangle
		activeScissor:   gmath.Rectangle,

		// Global flags applied to all subsequent quads in the batch
		activeFlags:     QuadFlags,

		// Shader uniform data
		shaderData:      ShaderGlobals,

		// Tracks which layers need Y-sorting
		sortedLayers:    bit_set[DrawLayer],
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
	quadFlags:     QuadFlags, // u8
	_:             [1]u8, // Padding to align next Vector4 to 4 byte boundary
	colorOverride: gmath.Vector4,
	parameters:    gmath.Vector4,
}
