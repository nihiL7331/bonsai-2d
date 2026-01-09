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
// be a horizontal stripe. You can declare the amount of animation frames by naming the file **file_name_{x}x1.png**,
// where x is the amount of frames. The animation frames suffix gets removed from the enum name.
//
// The CLI also allows for **tileset loading**, with each tile being a separate sprite. Simply create a **tilesets**
// directory in **assets/images**, and save the tileset here. Similarly to animation frame declaration, you can suffix
// the tileset file name like so: **tileset_name_{w}x{h}.png**, where w is width of one tile in pixels, and h is height
// of one tile in pixels. Each tile gets saved to the atlas with its edges extruded by one pixel, to ensure there's no
// edge bleeding issue. When no suffix is provided, the default size for a tile is **16x16 pixels**.
// :::

import "bonsai:core"
import "bonsai:core/gmath"
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
_renderState: RenderState

@(private = "file")
_atlas: Atlas

@(private = "file")
_drawFrame: DrawFrame

@(private = "file")
_clearedFrame: bool

@(private = "file")
_actualQuadData: [MAX_QUADS]Quad

@(private = "file")
_scissorState: ScissorState

// @ref
// Sets the background clear color.
setClearColor :: proc(col: gmath.Vector4) {
	_renderState.passAction = {
		colors = {0 = {load_action = .CLEAR, clear_value = transmute(sokol_gfx.Color)(col)}},
	}
}

// @ref
// Returns a pointer to the **current frame's** draw data.
getDrawFrame :: proc() -> ^DrawFrame {
	return &_drawFrame
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
// Flushses the current batch and switches coordinate space to **world space (gameplay)**.
// Sets the active draw layer to [`DrawLayer.background`](#drawlayer).
setWorldSpace :: proc() {
	flushBatch()
	_setCoordSpaceValue(getWorldSpace())
	getDrawFrame().reset.activeDrawLayer = DrawLayer.background
}

// @ref
// Flushes the current batch and switches coordinate space to **screen space (UI)**.
// Sets the active draw layer to [`DrawLayer.ui`](#drawlayer).
setScreenSpace :: proc() {
	flushBatch()
	_setCoordSpaceValue(getScreenSpace())
	getDrawFrame().reset.activeDrawLayer = DrawLayer.ui
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
// Disables the scissor test.
clearScissor :: proc() {
	if !_scissorState.enabled do return

	flushBatch()

	_scissorState.enabled = false
}

// Initializes the rendering subsystem (Sokol, buffers, pipelines).
// Called in main.odin.
init :: proc() {
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
	_renderState.bindings.vertex_buffers[0] = sokol_gfx.make_buffer(
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

	_renderState.bindings.index_buffer = sokol_gfx.make_buffer(
		{
			usage = {index_buffer = true},
			data = {ptr = raw_data(indices), size = size_of(u16) * indexBufferCount},
		},
	)

	_renderState.bindings.samplers[shaders.SMP_uDefaultSampler] = sokol_gfx.make_sampler({})

	// setup pipeline
	pipelineDesc: sokol_gfx.Pipeline_Desc = {
		shader = sokol_gfx.make_shader(shaders.quad_shader_desc(sokol_gfx.query_backend())),
		index_type = .UINT16,
		layout = {
			attrs = {
				shaders.ATTR_quad_aPosition = {format = .FLOAT2},
				shaders.ATTR_quad_aColor = {format = .FLOAT4},
				shaders.ATTR_quad_aUv = {format = .FLOAT2},
				shaders.ATTR_quad_aLocalUv = {format = .FLOAT2},
				shaders.ATTR_quad_aSize = {format = .FLOAT2},
				shaders.ATTR_quad_aBytes = {format = .UBYTE4N},
				shaders.ATTR_quad_aColorOverride = {format = .FLOAT4},
				shaders.ATTR_quad_aParams = {format = .FLOAT4},
			},
		},
	}

	// setup blending (alpha blend)
	blendState: sokol_gfx.Blend_State = {
		enabled          = true,
		src_factor_rgb   = .SRC_ALPHA,
		dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
		op_rgb           = .ADD,
		src_factor_alpha = .ONE,
		dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		op_alpha         = .ADD,
	}
	pipelineDesc.colors[0] = {
		blend = blendState,
	}
	_renderState.pipeline = sokol_gfx.make_pipeline(pipelineDesc)


	// set the initial clear color
	setClearColor(CLEAR_COLOR)

	_initDrawFrameLayers()
}

// Called at the start of every frame by the Core loop from main.odin.
coreRenderFrameStart :: proc() {
	resetDrawFrame()

	if _atlas.view.id != sokol_gfx.INVALID_ID {
		_renderState.bindings.views[shaders.VIEW_uTex] = _atlas.view
		_renderState.bindings.views[shaders.VIEW_uFontTex] = _atlas.view //HACK: do that to avoid crash when font isnt loaded
	}

	_renderState.passAction.colors[0].load_action = .CLEAR

	_scissorState.enabled = false

	sokol_gfx.begin_pass({action = _renderState.passAction, swapchain = sokol_glue.swapchain()})

	sokol_gfx.apply_pipeline(_renderState.pipeline)

	setWorldSpace()

	_clearedFrame = false
}

// Called at the end of every frame. Submits final batches to GPU.
// Called from main.odin.
coreRenderFrameEnd :: proc() {
	flushBatch()
	sokol_gfx.end_pass()
	sokol_gfx.commit()
}

// @ref
// Resets the [`DrawFrame`](#drawframe) (clears quads, resets camera).
resetDrawFrame :: proc() {
	drawFrame := getDrawFrame()
	drawFrame.reset.coordSpace = {}
	drawFrame.reset.shaderData = {}

	for &layer in drawFrame.reset.quads {
		clear(&layer)
	}

	// reset default camera to center of the game height
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
}

// @ref
// Flushes all queued quads to the GPU.
// Sorts layers if necessary and handles batch splitting if [`MAX_QUADS`](#max_quads) is exceeded.
flushBatch :: proc() {
	drawFrame := getDrawFrame()

	quadIndex := 0

	for &quadsInLayer, layerIndex in drawFrame.reset.quads {
		count := len(quadsInLayer)
		if count == 0 do continue

		currentLayer := DrawLayer(layerIndex)
		if currentLayer in drawFrame.reset.sortedLayers {
			slice.sort_by(quadsInLayer[:], _ySortCompare)
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

	// upload to gpu
	offset := sokol_gfx.append_buffer(
		_renderState.bindings.vertex_buffers[0],
		{ptr = raw_data(_actualQuadData[:]), size = uint(quadIndex) * size_of(Quad)},
	)

	_renderState.bindings.vertex_buffer_offsets[0] = offset
	sokol_gfx.apply_bindings(_renderState.bindings)

	// appply scissor
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
	drawFrame.reset.shaderData.uViewProjectionMatrix =
		drawFrame.reset.coordSpace.viewProjectionMatrix
	sokol_gfx.apply_uniforms(
		shaders.UB_ShaderData,
		{ptr = &drawFrame.reset.shaderData, size = size_of(shaders.Shaderdata)},
	)

	// draw
	sokol_gfx.draw(0, 6 * i32(quadIndex), 1)

	for &quadsInLayer in drawFrame.reset.quads {
		clear(&quadsInLayer)
	}
}

// @ref
// Changes the active **main texture view**.
setTexture :: proc(view: sokol_gfx.View) {
	currentId := _renderState.bindings.views[shaders.VIEW_uTex].id

	if currentId != view.id {
		flushBatch()
		_renderState.bindings.views[shaders.VIEW_uTex] = view
	}
}

// @ref
// Changes the active **font texture view**.
setFontTexture :: proc(view: sokol_gfx.View) {
	currentId := _renderState.bindings.views[shaders.VIEW_uFontTex].id

	if currentId != view.id {
		flushBatch()
		_renderState.bindings.views[shaders.VIEW_uFontTex] = view
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
	_drawFrame.reset.coordSpace = {
		projectionMatrix     = gmath.Matrix4(1),
		cameraMatrix         = gmath.Matrix4(1),
		viewProjectionMatrix = gmath.Matrix4(1),
	}
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
_initDrawFrameLayers :: proc() {
	drawFrame := getDrawFrame()
	allocator := context.allocator

	drawFrame.reset.quads[DrawLayer.background] = make([dynamic]Quad, 0, 512, allocator)
	drawFrame.reset.quads[DrawLayer.shadow] = make([dynamic]Quad, 0, 128, allocator)
	drawFrame.reset.quads[DrawLayer.playspace] = make([dynamic]Quad, 0, 256, allocator)
	drawFrame.reset.quads[DrawLayer.tooltip] = make([dynamic]Quad, 0, 256, allocator)
	drawFrame.reset.quads[DrawLayer.ui] = make([dynamic]Quad, 0, 1024, allocator)
}

// @ref
// Core function for pushing a quad into the **draw list**.
drawQuadProjected :: proc(
	positions: [4]gmath.Vector2,
	colors: [4]gmath.Color,
	uvs: [4]gmath.Vector2,
	textureIndex: u8,
	spriteSize: gmath.Vector2,
	colorOverride: gmath.Color,
	drawLayer: DrawLayer = DrawLayer.nil,
	flags: QuadFlags,
	parameters := gmath.Vector4{},
	drawLayerQueue := -1,
) {
	drawFrame := getDrawFrame()

	mutDrawLayer := drawLayer
	if mutDrawLayer == .nil { 	// default value for drawLayer
		mutDrawLayer = drawFrame.reset.activeDrawLayer
	}

	vertices: [4]Vertex
	defer {
		quadArray := &drawFrame.reset.quads[mutDrawLayer]

		if drawLayerQueue == -1 {
			append(quadArray, vertices)
		} else {
			assert(drawLayerQueue < len(quadArray), "No elements pushed after the drawLayerQueue.")

			resize_dynamic_array(quadArray, len(quadArray) + 1)
			oldRange := quadArray[drawLayerQueue:len(quadArray) - 1]
			newRange := quadArray[drawLayerQueue + 1:len(quadArray)]
			copy(newRange, oldRange)

			quadArray[drawLayerQueue] = vertices
		}
	}

	vertices[0].position = positions[0]; vertices[1].position = positions[1]
	vertices[2].position = positions[2]; vertices[3].position = positions[3]

	vertices[0].color = colors[0]; vertices[1].color = colors[1]
	vertices[2].color = colors[2]; vertices[3].color = colors[3]

	vertices[0].uv = uvs[0]; vertices[1].uv = uvs[1]
	vertices[2].uv = uvs[2]; vertices[3].uv = uvs[3]

	vertices[0].localUv = {0, 0}; vertices[1].localUv = {0, 1}
	vertices[2].localUv = {1, 1}; vertices[3].localUv = {1, 0}

	vertices[0].textureIndex = textureIndex; vertices[1].textureIndex = textureIndex
	vertices[2].textureIndex = textureIndex; vertices[3].textureIndex = textureIndex

	vertices[0].size = spriteSize; vertices[1].size = spriteSize
	vertices[2].size = spriteSize; vertices[3].size = spriteSize

	vertices[0].colorOverride = colorOverride; vertices[1].colorOverride = colorOverride
	vertices[2].colorOverride = colorOverride; vertices[3].colorOverride = colorOverride

	vertices[0].drawLayer = u8(mutDrawLayer); vertices[1].drawLayer = u8(mutDrawLayer)
	vertices[2].drawLayer = u8(mutDrawLayer); vertices[3].drawLayer = u8(mutDrawLayer)

	combinedFlags := flags | drawFrame.reset.activeFlags
	vertices[0].quadFlags = combinedFlags; vertices[1].quadFlags = combinedFlags
	vertices[2].quadFlags = combinedFlags; vertices[3].quadFlags = combinedFlags

	vertices[0].parameters = parameters; vertices[1].parameters = parameters
	vertices[2].parameters = parameters; vertices[3].parameters = parameters
}

// image loading helpers

loadAtlas :: proc(filepath: string) {
	pngData, success := platform.read_entire_file(filepath)
	if !success {
		log.warn("Failed to read atlas file at: %v. Defaulting to blank atlas.", filepath)
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
