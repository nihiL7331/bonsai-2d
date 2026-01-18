package render

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"

import sokol_gfx "bonsai:libs/sokol/gfx"
import stb_truetype "bonsai:libs/stb/truetype"

// @ref
// Path relative to project root pointing to the generated sprite atlas.
// :::caution
// This isn't the only place where this variable exists.
// Editing just this variable doesnt change where the atlas is generated.
// :::
ATLAS_PATH :: "bonsai/core/render/atlas/atlas.png"

// @ref
// Maximum number of quads per batch flush.
// :::tip
// Increase if you see "Quad buffer full" warnings, decrease to save memory.
// :::
MAX_QUADS :: 8192

// @ref
// Default UV coordinates covering the full texture (0,0 to 1,1).
DEFAULT_UV :: gmath.Vector4{0, 0, 1, 1}

// @ref
// Default clear color **(background)**.
CLEAR_COLOR :: colors.BLACK

// @ref
// Constants prefixed with `LOCATION` define the memory layout relation between the CPU [`Vertex`](#vertex) struct
// and the GPU shader attributes (`layout(location = X)`).
// :::caution
// Do not change these unless you update `shader_vs_core.glsl` to match.
// :::
LOCATION_POSITION :: 0
LOCATION_COLOR :: 1
LOCATION_UV :: 2
LOCATION_LOCAL_UV :: 3
LOCATION_SIZE :: 4
LOCATION_BYTES :: 5
LOCATION_COLOR_OVERRIDE :: 6
LOCATION_PARAMETERS :: 7

// @ref
// Constants prefixed with `BINDING` define the binding index used for uniform data. By default `0` is occupied by
// [`ShaderGlobals`](#shaderglobals) and `1` is left for custom shader uniform data.
BINDING_GLOBAL_UNIFORMS :: 0
BINDING_CUSTOM_UNIFORMS :: 1

// @ref
// A handle used to identify a loaded [`Shader`](#shader)
ShaderId :: distinct i32

// @ref
// A handle used to identify a loaded [`Canvas`](#canvas)
CanvasId :: distinct i32

// @ref
// Wraps a compiled **Sokol** pipeline and its ID.
Shader :: struct {
	pipeline: sokol_gfx.Pipeline,
	id:       ShaderId,
}

// @ref
// Function signature for the auto-generated shader descriptors created by `sokol-shdc`.
ShaderDescriptionFunction :: proc(backend: sokol_gfx.Backend) -> sokol_gfx.Shader_Desc // {}

// @ref
// Internal context holding the global **Sokol** GFX state.
// Manages active bindings (atlas/font) and stores the list of loaded [`Shaders`](#shader)
RenderContext :: struct {
	passAction:           sokol_gfx.Pass_Action,
	inPass:               bool,
	bindings:             sokol_gfx.Bindings,
	shaders:              [dynamic]Shader,
	defaultShaderId:      ShaderId,
	activeShaderId:       ShaderId,
	customUniformsData:   [1024]byte,
	customUniformsSize:   uint,
	canvases:             [dynamic]Canvas,
	defaultCanvasId:      CanvasId,
	activeCanvasId:       CanvasId,
	defaultCanvasSampler: sokol_gfx.Sampler,
}

// @ref
// Wraps all data needed for each `Canvas` object. Each has unique [`CanvasId`](#canvasid).
// Shouldn't be modified directly.
Canvas :: struct {
	image:       sokol_gfx.Image,
	depthImage:  sokol_gfx.Image,
	readerView:  sokol_gfx.View,
	attachments: sokol_gfx.Attachments,
	sampler:     sokol_gfx.Sampler,
	id:          CanvasId,
	size:        gmath.Vector2,
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
	view:  sokol_gfx.View,
	image: sokol_gfx.Image,
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
// :::note
// Must align to 16 bytes (via std140 Layout Rules).
// :::
ShaderGlobals :: struct #align (16) {
	uViewProjectionMatrix: gmath.Matrix4,
}

// @ref
// Bit flags for special rendering behaviors in the shader.
// :::note
// Currently unused by the core.
// :::
QuadFlags :: enum u8 {
	flag1 = (1 << 0),
	flag2 = (1 << 1),
}

// @ref
// Defines the rendering order **(Z-sorting)**.
// :::note
// Layers are **drawn from top to bottom** (`nil` first, `top` last).
// :::
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
	position:      gmath.Vector3,
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
