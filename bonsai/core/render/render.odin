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
// :::

import "bonsai:core"
import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import "bonsai:core/platform"
import "bonsai:generated"
import "bonsai:shaders"

import sokol_gfx "bonsai:libs/sokol/gfx"
import sokol_glue "bonsai:libs/sokol/glue"
import sokol_log "bonsai:libs/sokol/log"
import stb_image "bonsai:libs/stb/image"

import "core:log"
import "core:mem"
import "core:slice"

@(private = "file")
_renderContext: RenderContext

@(private = "package")
_atlas: Atlas

@(private = "file")
_drawFrame: DrawFrame

@(private = "file")
_actualQuadData: [MAX_QUADS]Quad

@(private = "file")
_scissorState: ScissorState

// @ref
// Sets the background clear color.
setClearColor :: proc(col: gmath.Vector4) {
	_renderContext.passAction = {
		colors = {0 = {load_action = .CLEAR, clear_value = transmute(sokol_gfx.Color)(col)}},
	}
}

// @ref
// Returns a pointer to the **current frame's** draw data.
getDrawFrame :: proc() -> ^DrawFrame {
	return &_drawFrame
}

// @ref
// Returns a pointer to the [`RenderContext`] struct.
getRenderContext :: proc() -> ^RenderContext {
	return &_renderContext
}

// @ref
// Sets the coordinate space (projection/camera matrices).
//
// **Arguments:**
// - **[`CoordSpace`](#coordspace) struct:** Sets the [`drawFrame.reset.coordSpace`](#drawframe) to given [`CoordSpace`](#coordspace).
// - **`nil`:** Sets the [`drawFrame.reset.coordSpace`](#drawframe) to default.
setCoordSpace :: proc {
	_setCoordSpaceValue,
	_setCoordSpaceDefault,
}

// @ref
// Flushes the current batch and switches coordinate space to **world space (gameplay)**.
// Sets the active draw layer to [`DrawLayer.background`](#drawlayer).
setWorldSpace :: proc() {
	if _drawFrame.reset.activeDrawLayer == DrawLayer.background && _renderContext.activeCanvasId == _renderContext.defaultCanvasId do return
	flushBatch()
	_setCoordSpaceValue(getWorldSpace())
	_drawFrame.reset.activeDrawLayer = DrawLayer.background
}

// @ref
// Flushes the current batch and switches coordinate space to **screen space (UI)**.
// Sets the active draw layer to [`DrawLayer.ui`](#drawlayer).
setScreenSpace :: proc() {
	if _drawFrame.reset.activeDrawLayer == DrawLayer.ui && _renderContext.activeCanvasId == _renderContext.defaultCanvasId do return
	flushBatch()
	_setCoordSpaceValue(getScreenSpace())
	_drawFrame.reset.activeDrawLayer = DrawLayer.ui
}

// @ref
// Calculates the coordinate space for the main gameplay world.
// Creates a **View-Projection matrix** based on the **camera's position** and **zoom**.
getWorldSpace :: proc() -> CoordSpace {
	projectionMatrix := core.getWorldSpaceProjectionMatrix()
	// model matrix
	cameraMatrix := core.getWorldSpaceCameraMatrix()
	// view matrix
	viewMatrix := gmath.matrixInverse(cameraMatrix)

	return {
		projectionMatrix = projectionMatrix,
		cameraMatrix = cameraMatrix,
		viewProjectionMatrix = projectionMatrix * viewMatrix,
	}
}

// @ref
// Calculates the coordinate space for **UI/Screen elements**.
getScreenSpace :: proc() -> CoordSpace {
	projectionMatrix := getScreenSpaceProjectionMatrix()
	cameraMatrix := gmath.Matrix4(1)

	return {
		projectionMatrix = projectionMatrix,
		cameraMatrix = cameraMatrix,
		viewProjectionMatrix = projectionMatrix,
	}
}

// @ref
// Calculates the coordinate space for **a custom [`Canvas`](#canvas)**.
// Called internally by [`setCanvas`](#setcanvas).
getCanvasSpace :: proc(width, height: f32) -> CoordSpace {
	projectionMatrix := gmath.matrixOrtho3d(f32(0.0), width, f32(0.0), height, f32(-1.0), f32(1.0))
	cameraMatrix := gmath.Matrix4(1)

	return {
		projectionMatrix = projectionMatrix,
		cameraMatrix = cameraMatrix,
		viewProjectionMatrix = projectionMatrix * cameraMatrix,
	}
}

// @ref
// Sets the **scissor** (clipping) rectangle.
// Flushes the batch if the scissor state changes.
setScissorCoordinates :: proc(coordinates: gmath.Vector4) {
	if _scissorState.enabled && _scissorState.coordinates == coordinates do return

	flushBatch()

	_scissorState.enabled = true
	_scissorState.coordinates = coordinates
}

// @ref
// Maps a **screen-space** rectangle to a screen-space scissor rectangle.
// Used for clipping rendering to specific regions (masking).
setScissorRectangle :: proc(rectangle: gmath.Rectangle) {
	coreContext := core.getCoreContext()

	projection := _drawFrame.reset.coordSpace.projectionMatrix

	bottomLeftWorld := gmath.Vector4{rectangle.x, rectangle.y, 0, 1}
	topRightWorld := gmath.Vector4{rectangle.z, rectangle.w, 0, 1}

	bottomLeftClip := projection * bottomLeftWorld
	topRightClip := projection * topRightWorld

	bottomLeftNdc := bottomLeftClip.xy / bottomLeftClip.w
	topRightNdc := topRightClip.xy / topRightClip.w

	frameBufferWidth, frameBufferHeight: f32

	if _renderContext.activeCanvasId != 0 {
		canvas := _renderContext.canvases[_renderContext.activeCanvasId]
		frameBufferWidth = canvas.size.x
		frameBufferHeight = canvas.size.y
	} else {
		frameBufferWidth = f32(coreContext.windowWidth)
		frameBufferHeight = f32(coreContext.windowHeight)
	}

	scissorX := (bottomLeftNdc.x + 1.0) * 0.5 * frameBufferWidth
	scissorY := (bottomLeftNdc.y + 1.0) * 0.5 * frameBufferHeight

	scissorWidth := (topRightNdc.x + 1.0) * 0.5 * frameBufferWidth - scissorX
	scissorHeight := (topRightNdc.y + 1.0) * 0.5 * frameBufferHeight - scissorY

	setScissorCoordinates(gmath.Vector4{scissorX, scissorY, scissorWidth, scissorHeight})
}

// @ref
// Disables the scissor test.
clearScissor :: proc() {
	if !_scissorState.enabled do return

	flushBatch()

	_scissorState.enabled = false
}

// Initializes the rendering subsystem (Sokol, buffers, pipelines).
// Called in main.odin.
init :: proc() {
	coreContext := core.getCoreContext()

	sokol_gfx.setup(
		{
			environment = sokol_glue.environment(),
			logger = {func = sokol_log.func},
			d3d11_shader_debugging = ODIN_DEBUG,
		},
	)

	// load the atlas generated at build-time
	loadAtlas(ATLAS_PATH)

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

	defaultSamplerDescription := sokol_gfx.Sampler_Desc {
		min_filter = .NEAREST,
		mag_filter = .NEAREST,
		wrap_u     = .CLAMP_TO_EDGE,
		wrap_v     = .CLAMP_TO_EDGE,
	}
	_renderContext.defaultCanvasSampler = sokol_gfx.make_sampler(defaultSamplerDescription)

	_renderContext.bindings.index_buffer = sokol_gfx.make_buffer(
		{
			usage = {index_buffer = true},
			data = {ptr = raw_data(indices), size = size_of(u16) * indexBufferCount},
		},
	)

	_renderContext.bindings.samplers[shaders.SMP_uDefaultSampler] = sokol_gfx.make_sampler({})
	_renderContext.defaultShaderId = loadShader(shaders.quad_shader_desc)
	_renderContext.defaultCanvasId = loadCanvas(coreContext.windowWidth, coreContext.windowHeight)

	// set the initial clear color
	setClearColor(CLEAR_COLOR)

	_initDrawFrameLayers()
}

// Called at the start of every frame by the Core loop from main.odin.
coreRenderFrameStart :: proc() {
	resetDrawFrame()

	if _atlas.view.id != sokol_gfx.INVALID_ID {
		_renderContext.bindings.views[shaders.VIEW_uTex] = _atlas.view
		_renderContext.bindings.views[shaders.VIEW_uFontTex] = _atlas.view //HACK: do that to avoid crash when font isnt loaded
	}


	_scissorState.enabled = false

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
	if _scissorState.enabled {
		sokol_gfx.apply_scissor_rectf(
			_scissorState.coordinates.x,
			_scissorState.coordinates.y,
			_scissorState.coordinates.z, // width
			_scissorState.coordinates.w, // height 
			false,
		)
	} else {
		// default to full window
		coreContext := core.getCoreContext()
		sokol_gfx.apply_scissor_rect(
			0,
			0,
			coreContext.windowWidth,
			coreContext.windowHeight,
			false,
		)
	}

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

	sokol_gfx.destroy_sampler(_renderContext.defaultCanvasSampler)

	if _atlas.view.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_view(_atlas.view)
		sokol_gfx.destroy_image(_atlas.image)
	}
}

// @ref
loadCanvas :: proc(width: i32, height: i32) -> CanvasId {
	swapchain := sokol_glue.swapchain()
	imageDescription := sokol_gfx.Image_Desc {
		type = ._2D,
		width = width,
		height = height,
		usage = sokol_gfx.Image_Usage{immutable = true, color_attachment = true},
		pixel_format = swapchain.color_format,
	}
	image := sokol_gfx.make_image(imageDescription)

	writerViewDescription := sokol_gfx.View_Desc {
		color_attachment = {image = image, mip_level = 0, slice = 0},
	}
	writerView := sokol_gfx.make_view(writerViewDescription)

	readerViewDescription := sokol_gfx.View_Desc {
		texture = {image = image},
	}
	readerView := sokol_gfx.make_view(readerViewDescription)

	depthImage := sokol_gfx.Image{}
	depthView := sokol_gfx.View{}

	if swapchain.depth_format != .NONE {
		depthImageDescription := sokol_gfx.Image_Desc {
			type = ._2D,
			width = width,
			height = height,
			usage = {immutable = true, depth_stencil_attachment = true},
			pixel_format = swapchain.depth_format,
		}
		depthImage = sokol_gfx.make_image(depthImageDescription)

		depthViewDescription := sokol_gfx.View_Desc {
			depth_stencil_attachment = {image = depthImage},
		}
		depthView = sokol_gfx.make_view(depthViewDescription)
	}

	attachments := sokol_gfx.Attachments{}
	attachments.colors[0] = writerView

	if swapchain.depth_format != .NONE {
		attachments.depth_stencil = depthView
	}

	id := CanvasId(len(_renderContext.canvases))

	append(
		&_renderContext.canvases,
		Canvas {
			image = image,
			depthImage = depthImage,
			readerView = readerView,
			attachments = attachments,
			sampler = _renderContext.defaultCanvasSampler,
			id = id,
			size = gmath.Vector2{f32(width), f32(height)},
		},
	)

	return id
}

// @ref
// Sets the current [`Canvas`](#canvas) (render target).
// Defaults to screen space canvas.
//
// **Arguments:**
// - [`CanvasId`](#canvasid): Handle linked to the targeted [`Canvas`](#canvas). Returned by the [`loadCanvas`](#loadcanvas) function.
// - 'clear': if `true` - clears contents of the canvas, if `false` - preserves previously drawn content.
// - `clearColor`: Clear (background) color, takes effect only if `clear` is `true`.
//
// :::note[Example]
// ```Odin
// draw :: proc() {
//   render.setCanvas(shadowCanvas)
//
//   render.drawSprite({x1, y1}, .shadowMedium)
//   render.drawSprite({x2, y2}, .shadowSmall)
//
//   render.setCanvas()
//
//   render.drawCanvas(shadowCanvas, drawLayer = render.DrawLayer.shadow)
//   render.drawSprite({x3, y3}, .pot)
//   // ...
// }
// ```
// :::
setCanvas :: proc(
	id: CanvasId = _renderContext.defaultCanvasId,
	clear: bool = true,
	clearColor: Maybe(gmath.Color) = nil,
) {
	if id == _renderContext.activeCanvasId && !clear && _renderContext.inPass do return
	flushBatch()

	if _renderContext.inPass {
		sokol_gfx.end_pass()
		_renderContext.inPass = false
	}

	targetCanvas := _renderContext.canvases[id]
	pass := sokol_gfx.Pass{}

	if targetCanvas.image.id == sokol_gfx.INVALID_ID {
		log.warn("Attempted to render to a destroyed Canvas. Fallback to default.")
		setCanvas(_renderContext.defaultCanvasId, clear)
		return
	}

	if targetCanvas.id == 0 {
		pass.action = _renderContext.passAction
	}

	pass.action.colors[0].load_action = .LOAD
	if clear {
		pass.action.colors[0].load_action = .CLEAR

		color: gmath.Color
		if c, ok := clearColor.?; ok {
			color = c
		} else {
			color = CLEAR_COLOR
		}
		pass.action.colors[0].clear_value = transmute(sokol_gfx.Color)(color)
	}

	if targetCanvas.id != 0 {
		pass.attachments = targetCanvas.attachments
		_drawFrame.reset.coordSpace = getCanvasSpace(targetCanvas.size.x, targetCanvas.size.y)
	} else {
		pass.swapchain = sokol_glue.swapchain()
		if _drawFrame.reset.activeDrawLayer == .background {
			// world space
			_drawFrame.reset.coordSpace = getWorldSpace()
		} else {
			// screen space
			_drawFrame.reset.coordSpace = getScreenSpace()
		}
	}

	sokol_gfx.begin_pass(pass)
	_renderContext.inPass = true
	_renderContext.activeCanvasId = id
}

// @ref
// Destroys the GPU resources associated with the [`Canvas`](#canvas).
// :::caution
// Calling this invalidates the [`CanvasId`](#canvasid).
// :::
destroyCanvas :: proc(id: CanvasId) {
	if id == _renderContext.defaultCanvasId do return
	if int(id) >= len(_renderContext.canvases) do return

	canvas := &_renderContext.canvases[id]
	if canvas.image.id == sokol_gfx.INVALID_ID do return

	sokol_gfx.destroy_view(canvas.readerView)
	sokol_gfx.destroy_view(canvas.attachments.colors[0])
	sokol_gfx.destroy_image(canvas.image)

	if canvas.attachments.depth_stencil.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_view(canvas.attachments.depth_stencil)
		sokol_gfx.destroy_image(canvas.depthImage)
	}

	canvas.image.id = sokol_gfx.INVALID_ID
	canvas.readerView.id = sokol_gfx.INVALID_ID
}

// @ref
// Creates a new [`ShaderId`](#shaderid) from a `sokol-shdc` generated description function.
// This function enforces the framework's standard vertex layout to ensure compatibility with batching.
//
// :::note
// This doesn't change the current shader, just loads it into memory.
// :::
//
// :::note[Example]
// ```Odin
// import "shaders"
//
// potShader := render.loadShader(shaders.pot_shader_desc)
// ```
// :::
loadShader :: proc(descriptionFunction: ShaderDescriptionFunction) -> ShaderId {
	backend := sokol_gfx.query_backend()
	description := descriptionFunction(backend)

	shader := sokol_gfx.make_shader(description)

	pipelineDescription: sokol_gfx.Pipeline_Desc = {
		shader = shader,
		index_type = .UINT16,
		layout = {
			attrs = {
				LOCATION_POSITION = {format = .FLOAT3},
				LOCATION_COLOR = {format = .FLOAT4},
				LOCATION_UV = {format = .FLOAT2},
				LOCATION_LOCAL_UV = {format = .FLOAT2},
				LOCATION_SIZE = {format = .FLOAT2},
				LOCATION_BYTES = {format = .UBYTE4N},
				LOCATION_COLOR_OVERRIDE = {format = .FLOAT4},
				LOCATION_PARAMETERS = {format = .FLOAT4},
			},
		},
	}
	blendState: sokol_gfx.Blend_State = {
		enabled          = true,
		src_factor_rgb   = .SRC_ALPHA,
		dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
		op_rgb           = .ADD,
		src_factor_alpha = .ONE,
		dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		op_alpha         = .ADD,
	}
	pipelineDescription.colors[0] = {
		blend = blendState,
	}

	pipeline := sokol_gfx.make_pipeline(pipelineDescription)
	id := ShaderId(len(_renderContext.shaders))

	append(&_renderContext.shaders, Shader{pipeline = pipeline, id = id})
	return id
}

// @ref
// Sets the active shader pipeline for subsequent draw calls.
// Flushes the current batch if the shader changes.
//
// **Arguments:**
// - **`id`**: Expects the [`ShaderId`](#shaderid) returned by [`loadShader`](#loadshader).
setShader :: proc(id: ShaderId = _renderContext.defaultShaderId) {
	if _renderContext.activeShaderId == id do return

	flushBatch()
	_renderContext.activeShaderId = id

	_renderContext.customUniformsSize = 0
}

// @ref
// Uploads custom uniform data to the currently active shader.
// This triggers a batch flush to ensure previous sprites are drawn with old uniforms.
// :::note
// The data is bound to `layout(binding=1)` in **GLSL**.
// :::
// :::note[Example]
// parameters := PotParameters{ time = 1.0, power = 10.0 }
// render.setCustomUniforms(&params, size_of(params))
// :::
setCustomUniforms :: proc(data: rawptr, size: uint) {
	flushBatch()

	if size > len(_renderContext.customUniformsData) {
		log.errorf("Custom uniforms too large.")
		return
	}
	mem.copy(&_renderContext.customUniformsData[0], data, int(size))
	_renderContext.customUniformsSize = size
}

// @ref
// Changes the active **main texture view**.
setTexture :: proc(view: sokol_gfx.View) {
	currentId := _renderContext.bindings.views[shaders.VIEW_uTex].id

	if currentId != view.id {
		flushBatch()
		_renderContext.bindings.views[shaders.VIEW_uTex] = view
	}
}

// @ref
// Changes the active **font texture view**.
setFontTexture :: proc(view: sokol_gfx.View) {
	currentId := _renderContext.bindings.views[shaders.VIEW_uFontTex].id

	if currentId != view.id {
		flushBatch()
		_renderContext.bindings.views[shaders.VIEW_uFontTex] = view
	}
}

// @ref
// Helper to retrieve **texture info** from `SpriteName`.
getAtlasUv :: proc(sprite: generated.SpriteName) -> gmath.Vector4 {
	return generated.getSpriteData(sprite).uv
}

// @ref
// Helper to retrieve **size** from [`SpriteName`](https://bonsai-framework.dev/reference/generated/#spritename).
getSpriteSize :: proc(sprite: generated.SpriteName) -> gmath.Vector2 {
	return generated.getSpriteData(sprite).size
}

@(private = "file")
_setCoordSpaceDefault :: proc() {
	_drawFrame.reset.coordSpace = getScreenSpace()
}

@(private = "file")
_setCoordSpaceValue :: proc(coordSpace: CoordSpace) {
	_drawFrame.reset.coordSpace = coordSpace
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

	_drawFrame.reset.quads[DrawLayer.background] = make([dynamic]Quad, 0, 512, allocator)
	_drawFrame.reset.quads[DrawLayer.shadow] = make([dynamic]Quad, 0, 128, allocator)
	_drawFrame.reset.quads[DrawLayer.playspace] = make([dynamic]Quad, 0, 256, allocator)
	_drawFrame.reset.quads[DrawLayer.tooltip] = make([dynamic]Quad, 0, 256, allocator)
	_drawFrame.reset.quads[DrawLayer.ui] = make([dynamic]Quad, 0, 1024, allocator)
}

// @ref
// Core function for pushing a quad into the **draw list**.
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

	quadArray := &_drawFrame.reset.quads[mutDrawLayer]

	if len(quadArray) >= cap(quadArray) {
		reserve(quadArray, max(8, cap(quadArray) * 2))
	}

	oldLength := len(quadArray)
	resize(quadArray, oldLength + 1)

	vertices := &quadArray[oldLength]

	vertices[0].position = {positions[0].x, positions[0].y, sortKey}
	vertices[1].position = {positions[1].x, positions[1].y, sortKey}
	vertices[2].position = {positions[2].x, positions[2].y, sortKey}
	vertices[3].position = {positions[3].x, positions[3].y, sortKey}

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

// @ref
// Draws the contents of a [`Canvas`](#canvas) onto the screen (or current target) at the given position.
// This triggers an immediate batch flush because it requires switching textures.
drawCanvas :: proc(
	id: CanvasId,
	position: gmath.Vector2 = {0, 0},
	rotation: f32 = 0.0,
	pivot: gmath.Pivot = .bottomLeft,
	scale: gmath.Vector2 = {1, 1},
	size: Maybe(gmath.Vector2) = nil,
	transform := gmath.Matrix4(1),
	color := colors.WHITE,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	if id == 0 || int(id) >= len(_renderContext.canvases) do return

	canvas := _renderContext.canvases[id]
	if canvas.image.id == sokol_gfx.INVALID_ID do return

	setTexture(canvas.readerView)

	localTransform := gmath.Matrix4(1)
	localTransform *= gmath.matrixTranslate(position)
	if rotation != 0 {
		localTransform *= gmath.matrixRotate(rotation)
	}
	localTransform *= gmath.matrixScale(scale)
	localTransform *= transform
	canvasSize, ok := size.?
	if !ok {
		canvasSize = canvas.size
	}
	pivotOffset := canvasSize * -gmath.scaleFromPivot(pivot)
	localTransform *= gmath.matrixTranslate(pivotOffset)

	bottomLeft := gmath.Vector2{0, 0}
	topLeft := gmath.Vector2{0, canvasSize.y}
	topRight := gmath.Vector2{canvasSize.x, canvasSize.y}
	bottomRight := gmath.Vector2{canvasSize.x, 0}

	//transform local -> world
	worldBottomLeft := gmath.transformPoint(localTransform, bottomLeft)
	worldTopLeft := gmath.transformPoint(localTransform, topLeft)
	worldTopRight := gmath.transformPoint(localTransform, topRight)
	worldBottomRight := gmath.transformPoint(localTransform, bottomRight)

	uvs: [4]gmath.Vector2
	if sokol_gfx.query_features().origin_top_left {
		uvs = {{0, 1}, {0, 0}, {1, 0}, {1, 1}}
	} else {
		uvs = {{0, 0}, {0, 1}, {1, 1}, {1, 0}}
	}

	drawQuadProjected(
		positions = {worldBottomLeft, worldTopLeft, worldTopRight, worldBottomRight},
		colors = {color, color, color, color},
		uvs = uvs,
		textureIndex = 0,
		quadSize = canvasSize,
		colorOverride = {},
		flags = {},
		drawLayer = drawLayer,
		sortKey = sortKey,
	)
}

// image loading helpers

loadAtlas :: proc(filepath: string) {
	pngData, success := platform.read_entire_file(filepath)
	if !success {
		log.warnf("Failed to read atlas file at: %v. Defaulting to blank atlas.", filepath)
		loadAtlas("bonsai/core/render/atlas/blank.png")
		return
	}
	defer delete(pngData)

	width, height, channels: i32
	imageData := getImageData(raw_data(pngData), i32(len(pngData)), &width, &height, &channels)
	if imageData == nil do return // error already handled in getImageData
	defer stb_image.image_free(imageData)

	description: sokol_gfx.Image_Desc
	description.width = width
	description.height = height
	description.pixel_format = .RGBA8
	description.data.subimage[0][0] = {
		ptr  = imageData,
		size = uint(width * height * 4),
	}

	sgImage := sokol_gfx.make_image(description)
	if sgImage.id == sokol_gfx.INVALID_ID {
		log.error("Failed to make an image.")
		return
	}

	_atlas.image = sgImage
	_atlas.view = sokol_gfx.make_view({texture = sokol_gfx.Texture_View_Desc({image = sgImage})})
}

getImageData :: proc(
	buffer: [^]byte,
	bufferLength: i32,
	width, height, channels: ^i32,
) -> [^]byte {
	imageData := stb_image.load_from_memory(buffer, bufferLength, width, height, channels, 4)
	if imageData == nil {
		log.error("STB failed to decode image data.")
		return nil
	}
	return imageData
}
