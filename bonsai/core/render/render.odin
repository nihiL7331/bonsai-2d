package render

// @overview
// This package implements a batched 2D rendering pipeline.
// It serves as the primary interface for drawing sprites, text and geometric primitives,
// automatically handling coordinate space transformations and draw call batching.
//
// **Features:**
// - **Automated asset pipeline:** Utilizes a build-time generated texture atlas and
//   auto-generated sprite and font enums ([`SpriteName`](https://bonsai-framework.dev/reference/generated/#spritename) and [`FontName`](https://bonsai-framework.dev/reference/generated/#fontname) in [`bonsai:generated`](https://bonsai-framework.dev/reference/generated) package)
//   for type-safe, optimized asset access.
// - **Batched rendering:** Automatically batches draw calls (up to [`MAX_QUADS`](#max_quads)) to minimize GPU overhead,
//   with manual control via [`flushBatch`](#flushbatch).
// - **Coordinate systems:** Easy switching between **world space** (gameplay) and **screen space** (UI) using
//   helper functions: [`setWorldSpace`](#setworldspace) and [`setScreenSpace`](#setscreenspace).
// - **Text drawing:** Integrated **TTF** font support with utilities like [`drawTextWithDropShadow`](#drawtextwithdropshadow) and
//   [`drawTextSimple`](#drawtextsimple).
// - **Scissoring:** Built-in support for clipping regions via [`ScissorState`](#scissorstate).
//
// :::note[Usage]
// ```Odin
// draw :: proc() {
//   render.setWorldSpace()
//
//   // Draw game objects using auto-generated sprite enums
//   render.drawSprite(.potShadow, potPosition, drawLayer = .shadow)
//   render.drawSprite(.potIdle, potPosition)
//
//   // Draw ui with auto-generated font enum
//   render.setScreenSpace()
//   render.drawTextSimple(fmt.tprintf("Health: %d", potHealth), textPosition, .PixelCode)
// }
// ```
// :::
//
// :::note[Notes]
// Currently it only supports **PNG** files for images and **TTF** files for fonts.
//
// The CLI generates enums from images located in **assets/images**. For animated sprite sheets, they **have to**
// be a horizontal stripe. You can declare the amount of animation frames by naming the file **fileName_{**X**}x1.png**,
// where **X** is the amount of frames. The animation frames suffix gets removed from the enum name.
//
// The CLI also allows for **tileset loading**, with each tile being a separate sprite. Simply create a **tilesets**
// directory in **assets/images**, and save the tileset here. Similarly to animation frame declaration, you can suffix
// the tileset file name like so: **tilesetName_{**W**}x{**H**}.png**, where **W** is width of one tile in pixels, and **H** is height
// of one tile in pixels. Each tile gets saved to the atlas with its edges extruded by one pixel, to ensure there's no
// edge bleeding issue. When no suffix is provided, the default size for a tile in a tileset is **16x16 pixels**.
//
// The CLI also handles **font scaling** via filenames. Naming a font **fontName_{**N**}.ttf**
// (e.g., `PixelCode_12.ttf`) marks it as a **Pixel Font** with a native size of **N**. These are baked
// at integer multiples of **N** to preserve the pixel grid. Fonts without a suffix are treated as **Vector Fonts**
// and are baked at the requested size (with oversampling) for smooth edges.
// :::

import "bonsai:core"
import "bonsai:core/gmath"
import "bonsai:shaders"

import sokol_gfx "bonsai:libs/sokol/gfx"
import sokol_glue "bonsai:libs/sokol/glue"
import sokol_log "bonsai:libs/sokol/log"

import "core:log"
import "core:mem"
import "core:slice"

BACKGROUND_QUAD_SIZE :: 512
SHADOW_QUAD_SIZE :: 128
PLAYSPACE_QUAD_SIZE :: 256
TOOLTIP_QUAD_SIZE :: 256
UI_QUAD_SIZE :: 1024

@(private = "package")
_renderContext: RenderContext

@(private = "package")
_drawFrame: DrawFrame

@(private = "file")
_actualQuadData: [MAX_QUADS]Quad

// @ref
// Returns a pointer to the **current frame's** draw data.
getDrawFrame :: proc() -> ^DrawFrame {
	return &_drawFrame
}

// @ref
// Returns a pointer to the `RenderContext` struct.
getRenderContext :: proc() -> ^RenderContext {
	return &_renderContext
}


// Initializes the rendering subsystem (Sokol, buffers, pipelines).
// Called in main.odin.
init :: proc() {
	coreContext := core.getCoreContext()

	_initScissorStack()

	sokol_gfx.setup(
		{
			environment = sokol_glue.environment(),
			logger = {func = sokol_log.func},
			d3d11_shader_debugging = ODIN_DEBUG,
		},
	)

	// load the atlas generated at build-time
	loadSpriteMetadata()
	loadAtlas()
	loadFonts()

	// create dynamic vertex buffer
	_renderContext.bindings.vertex_buffers[0] = sokol_gfx.make_buffer(
		{usage = {stream_update = true}, size = size_of(_actualQuadData)},
	)

	// create and fill static index buffer
	indexBufferCount :: MAX_QUADS * 6
	indices, _ := mem.make([]u16, indexBufferCount, allocator = context.allocator)
	defer delete(indices)

	for i := 0; i < indexBufferCount; i += 6 {
		// { 0, 1, 2,  0, 2, 3 }
		baseIndex := u16((i / 6) * 4)
		indices[i + 0] = baseIndex + 0
		indices[i + 1] = baseIndex + 1
		indices[i + 2] = baseIndex + 2
		indices[i + 3] = baseIndex + 0
		indices[i + 4] = baseIndex + 2
		indices[i + 5] = baseIndex + 3
	}

	nearestSamplerDescription := sokol_gfx.Sampler_Desc {
		min_filter = .NEAREST,
		mag_filter = .NEAREST,
		wrap_u     = .CLAMP_TO_EDGE,
		wrap_v     = .CLAMP_TO_EDGE,
	}
	linearSamplerDescription := sokol_gfx.Sampler_Desc {
		min_filter = .LINEAR,
		mag_filter = .LINEAR,
		wrap_u     = .CLAMP_TO_EDGE,
		wrap_v     = .CLAMP_TO_EDGE,
	}
	_renderContext.nearestSampler = sokol_gfx.make_sampler(nearestSamplerDescription)
	_renderContext.linearSampler = sokol_gfx.make_sampler(linearSamplerDescription)

	_renderContext.bindings.index_buffer = sokol_gfx.make_buffer(
		{
			usage = {index_buffer = true},
			data = {ptr = raw_data(indices), size = size_of(u16) * indexBufferCount},
		},
	)

	_renderContext.bindings.samplers[shaders.SMP_uNearestSampler] = _renderContext.nearestSampler
	_renderContext.bindings.samplers[shaders.SMP_uLinearSampler] = _renderContext.linearSampler
	_renderContext.defaultShaderId = loadShader(shaders.quad_shader_desc)
	_renderContext.defaultCanvasId = loadCanvas(coreContext.windowWidth, coreContext.windowHeight)

	// set the initial clear color
	setClearColor(CLEAR_COLOR)

	_initDrawFrameLayers()
}

// Called at the start of every frame by the Core loop from main.odin.
coreRenderFrameStart :: proc() {
	resetDrawFrame()

	atlas := &_renderContext.atlas
	if atlas.view.id != sokol_gfx.INVALID_ID {
		_renderContext.bindings.views[shaders.VIEW_uTex] = atlas.view
		_renderContext.bindings.views[shaders.VIEW_uFontTex] = atlas.view //HACK: do that to avoid crash when font isnt loaded
		_renderContext.bindings.samplers[shaders.SMP_uNearestSampler] =
			_renderContext.nearestSampler
		_renderContext.bindings.samplers[shaders.SMP_uLinearSampler] = _renderContext.linearSampler
	}

	_resetScissorStack()

	setCanvas(_renderContext.defaultCanvasId, clear = true)

	setWorldSpace()
}

// Called at the end of every frame. Submits final batches to GPU.
// Called from main.odin.
coreRenderFrameEnd :: proc() {
	flushBatch()
	sokol_gfx.end_pass()
	sokol_gfx.commit()
}

// @ref
// Resets the [`DrawFrame`](#drawframe) (clears quads, resets camera) and sets the shader to default.
resetDrawFrame :: proc() {
	_drawFrame.reset.coordSpace = {}
	_drawFrame.reset.shaderData = {}

	for &layer in _drawFrame.reset.quads {
		clear(&layer)
	}

	_renderContext.inPass = false
	_renderContext.customUniformsSize = 0

	_renderContext.activeCanvasId = _renderContext.defaultCanvasId

	coreContext := core.getCoreContext()
	aspect := f32(coreContext.windowWidth) / f32(coreContext.windowHeight)
	when core.SCALE_MODE == core.ScaleMode.FixedHeight {
		coreContext.camera.bounds = gmath.rectangleMake(
			coreContext.camera.position,
			gmath.Vector2{core.GAME_HEIGHT * aspect, core.GAME_HEIGHT},
			gmath.Pivot.centerCenter,
		)
	}
	when core.SCALE_MODE == core.ScaleMode.FixedWidth {
		coreContext.camera.bounds = gmath.rectangleMake(
			coreContext.camera.position,
			gmath.Vector2{core.GAME_WIDTH, core.GAME_WIDTH / aspect},
			gmath.Pivot.centerCenter,
		)
	}
	setShader(_renderContext.defaultShaderId)
}

// @ref
// Flushes all queued quads to the GPU.
// Sorts layers if necessary. Warns when [`MAX_QUADS`](#max_quads) is exceeded.
flushBatch :: proc() {
	quadIndex := 0

	for &quadsInLayer, layerIndex in _drawFrame.reset.quads {
		count := len(quadsInLayer)
		if count == 0 do continue

		currentLayer := DrawLayer(layerIndex)
		if currentLayer in _drawFrame.reset.sortedLayers {
			slice.sort_by(quadsInLayer[:], _ySortCompare)
		} else {
			slice.sort_by(quadsInLayer[:], _drawKeyCompare)
		}

		spaceLeft := MAX_QUADS - quadIndex
		if count > spaceLeft {
			count = spaceLeft
			log.warnf("Quad buffer full. Truncating %d quads.", len(quadsInLayer) - count)
		}

		if count <= 0 do break

		// copy into single flat buffer
		destinationPtr := &_actualQuadData[quadIndex]
		sourcePtr := raw_data(quadsInLayer)

		mem.copy(destinationPtr, sourcePtr, count * size_of(Quad))

		quadIndex += count
		if quadIndex >= MAX_QUADS do break
	}

	if quadIndex == 0 do return

	activeShader := _renderContext.shaders[_renderContext.activeShaderId]
	sokol_gfx.apply_pipeline(activeShader.pipeline)

	// upload to gpu
	offset := sokol_gfx.append_buffer(
		_renderContext.bindings.vertex_buffers[0],
		{ptr = raw_data(_actualQuadData[:]), size = uint(quadIndex) * size_of(Quad)},
	)

	_renderContext.bindings.vertex_buffer_offsets[0] = offset
	sokol_gfx.apply_bindings(_renderContext.bindings)

	// apply scissor
	_applyScissor()

	// upload uniforms
	_drawFrame.reset.shaderData.uViewProjectionMatrix =
		_drawFrame.reset.coordSpace.viewProjectionMatrix
	sokol_gfx.apply_uniforms(
		BINDING_GLOBAL_UNIFORMS,
		{ptr = &_drawFrame.reset.shaderData, size = size_of(shaders.Shaderdata)},
	)

	if _renderContext.customUniformsSize > 0 {
		sokol_gfx.apply_uniforms(
			BINDING_CUSTOM_UNIFORMS,
			{
				ptr = &_renderContext.customUniformsData[0],
				size = _renderContext.customUniformsSize,
			},
		)
	}

	// draw
	sokol_gfx.draw(0, 6 * i32(quadIndex), 1)

	for &quadsInLayer in _drawFrame.reset.quads {
		clear(&quadsInLayer)
	}
}

// @ref
// Cleans up all rendering resources.
// Called internally by **main.odin**.
shutdown :: proc() {
	destroyFonts()

	_destroyScissorStack()

	for i := 1; i < len(_renderContext.canvases); i += 1 {
		destroyCanvas(CanvasId(i))
	}

	clear(&_renderContext.canvases)

	for shader in _renderContext.shaders {
		sokol_gfx.destroy_pipeline(shader.pipeline)
	}
	clear(&_renderContext.shaders)

	sokol_gfx.destroy_buffer(_renderContext.bindings.vertex_buffers[0])
	sokol_gfx.destroy_buffer(_renderContext.bindings.index_buffer)

	sokol_gfx.destroy_sampler(_renderContext.nearestSampler)
	sokol_gfx.destroy_sampler(_renderContext.linearSampler)

	atlas := &_renderContext.atlas
	if atlas.view.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_view(atlas.view)
		sokol_gfx.destroy_image(atlas.image)
	}
}


@(private = "file")
_ySortCompare :: proc(a, b: Quad) -> bool {
	aY := min(a[0].position.y, a[1].position.y, a[2].position.y, a[3].position.y)
	bY := min(b[0].position.y, b[1].position.y, b[2].position.y, b[3].position.y)
	return aY > bY
}

@(private = "file")
_drawKeyCompare :: proc(a, b: Quad) -> bool {
	return a[0].position.z < b[0].position.z
}

@(private = "file")
_initDrawFrameLayers :: proc() {
	allocator := context.allocator

	_drawFrame.reset.quads[DrawLayer.background] = make(
		[dynamic]Quad,
		0,
		BACKGROUND_QUAD_SIZE,
		allocator,
	)
	_drawFrame.reset.quads[DrawLayer.shadow] = make([dynamic]Quad, 0, SHADOW_QUAD_SIZE, allocator)
	_drawFrame.reset.quads[DrawLayer.playspace] = make(
		[dynamic]Quad,
		0,
		PLAYSPACE_QUAD_SIZE,
		allocator,
	)
	_drawFrame.reset.quads[DrawLayer.tooltip] = make(
		[dynamic]Quad,
		0,
		TOOLTIP_QUAD_SIZE,
		allocator,
	)
	_drawFrame.reset.quads[DrawLayer.ui] = make([dynamic]Quad, 0, UI_QUAD_SIZE, allocator)
}

// @ref
// Core function for pushing a quad into the **draw list**.
//
// This is a low-level rendering function used by higher-level drawing utilities.
// It directly submits a quad (4 vertices) with full control over positions, UVs, colors, and rendering parameters.
//
// **Arguments:**
// - `positions`: World-space positions of the quad's 4 corners (bottom-left, top-left, top-right, bottom-right).
// - `colors`: Vertex colors (RGBA) for each corner.
// - `uvs`: Texture coordinates for each corner (x,y = bottom-left, x,w = top-left, z,w = top-right, z,y = bottom-right).
// - `textureIndex`: Texture slot (0 = atlas, 1 = font, 255 = white pixel).
// - `quadSize`: Original size of the quad (before transforms).
// - `colorOverride`: Optional tint color (multiplied with vertex colors).
// - `drawLayer`: Target draw layer (defaults to current active layer).
// - `flags`: Special shader flags (e.g., effects).
// - `parameters`: Custom shader parameters (vec4).
// - `sortKey`: Z-order key (higher values draw on top).
//
// :::note[Performance]
// Prefer higher-level helpers like `drawSprite` or `drawRectangle` unless you need per-vertex control.
// :::
//
// :::note[Example]
// ```Odin
// render.drawQuadProjected(
//     positions = { ... },
//     colors    = { colors.WHITE, ... },
//     uvs       = { uv.xy, uv.xw, uv.zw, uv.zy },
//     textureIndex = 0,
//     quadSize = {64, 64},
//     drawLayer = .background,
// )
// ```
// :::
drawQuadProjected :: proc(
	positions: [4]gmath.Vector2,
	colors: [4]gmath.Color,
	uvs: [4]gmath.Vector2,
	textureIndex: u8,
	quadSize: gmath.Vector2,
	colorOverride: gmath.Color,
	drawLayer: DrawLayer = DrawLayer.nil,
	flags: QuadFlags,
	parameters := gmath.Vector4{},
	sortKey: f32 = 0.0,
) {
	mutDrawLayer := drawLayer
	if mutDrawLayer == .nil { 	// default value for drawLayer
		mutDrawLayer = _drawFrame.reset.activeDrawLayer
	}

	// HACK:
	// encode the index into sortKey to ensure stable sorting
	// (if object is called to draw before an object of the same sortKey,
	// they preserve the order)
	currentCount := len(_drawFrame.reset.quads[drawLayer])
	bias := f32(currentCount) * 0.000001
	finalSortKey := sortKey + bias

	quadArray := &_drawFrame.reset.quads[mutDrawLayer]

	if len(quadArray) >= cap(quadArray) {
		reserve(quadArray, max(8, cap(quadArray) * 2))
	}

	oldLength := len(quadArray)
	resize(quadArray, oldLength + 1)

	vertices := &quadArray[oldLength]

	vertices[0].position = {positions[0].x, positions[0].y, finalSortKey}
	vertices[1].position = {positions[1].x, positions[1].y, finalSortKey}
	vertices[2].position = {positions[2].x, positions[2].y, finalSortKey}
	vertices[3].position = {positions[3].x, positions[3].y, finalSortKey}

	vertices[0].color = colors[0]; vertices[1].color = colors[1]
	vertices[2].color = colors[2]; vertices[3].color = colors[3]

	vertices[0].uv = uvs[0]; vertices[1].uv = uvs[1]
	vertices[2].uv = uvs[2]; vertices[3].uv = uvs[3]

	vertices[0].localUv = {0, 0}; vertices[1].localUv = {0, 1}
	vertices[2].localUv = {1, 1}; vertices[3].localUv = {1, 0}

	vertices[0].textureIndex = textureIndex; vertices[1].textureIndex = textureIndex
	vertices[2].textureIndex = textureIndex; vertices[3].textureIndex = textureIndex

	vertices[0].size = quadSize; vertices[1].size = quadSize
	vertices[2].size = quadSize; vertices[3].size = quadSize

	vertices[0].colorOverride = colorOverride; vertices[1].colorOverride = colorOverride
	vertices[2].colorOverride = colorOverride; vertices[3].colorOverride = colorOverride

	vertices[0].drawLayer = u8(mutDrawLayer); vertices[1].drawLayer = u8(mutDrawLayer)
	vertices[2].drawLayer = u8(mutDrawLayer); vertices[3].drawLayer = u8(mutDrawLayer)

	combinedFlags := flags | _drawFrame.reset.activeFlags
	vertices[0].quadFlags = combinedFlags; vertices[1].quadFlags = combinedFlags
	vertices[2].quadFlags = combinedFlags; vertices[3].quadFlags = combinedFlags

	vertices[0].parameters = parameters; vertices[1].parameters = parameters
	vertices[2].parameters = parameters; vertices[3].parameters = parameters
}
