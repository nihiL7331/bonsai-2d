package render

import "core:log"

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import sokol_gfx "bonsai:libs/sokol/gfx"
import sokol_glue "bonsai:libs/sokol/glue"

// @ref
// Sets the current render target (Canvas).
// Flushes the batch and switches to the specified Canvas or falls back to the default screen buffer.
//
// **Arguments:**
// - `id`: [`CanvasId`](#canvasid) to render to (default = screen).
// - `clear`: If `true`, clears the Canvas with `clearColor` (default = `true`).
// - `clearColor`: Background fill color (defaults to [`CLEAR_COLOR`](#clear_color)).
//
// :::note[Usage]
// - Use [`loadCanvas`](#loadcanvas) to create a new Canvas.
// - Rendering to a Canvas requires calling `drawCanvas` afterward to display it.
//
// ```Odin
// // Render shadows to an offscreen buffer
// render.setCanvas(shadowCanvas)
// render.drawSprite(.shadow, position)
//
// // Resume rendering to screen
// render.setCanvas()
// render.drawCanvas(shadowCanvas, drawLayer = .shadow)
// ```
// :::
//
// :::caution[Performance]
// Switching Canvases forces a [`flushBatch`](#flushbatch). Minimize calls to avoid performance overhead.
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
	_renderContext.canvases[id] = {}
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

// @ref
// Creates a new [`Canvas`](#canvas) with the specified dimensions and returns its [`CanvasId`](#canvasid).
//
// **Arguments:**
// - `width`: Width of the Canvas in pixels.
// - `height`: Height of the Canvas in pixels.
//
// **Returns:**
// - [`CanvasId`](#canvasid): A unique identifier for the created Canvas.
//
// :::note[Usage]
// Canvases are used as offscreen render targets. After creating a Canvas, use [`setCanvas`](#setcanvas) to render to it
// and [`drawCanvas`](#drawcanvas) to display its contents on the screen.
//
// ```Odin
// // Create a Canvas for rendering shadows
// shadowCanvas := render.loadCanvas(512, 512)
//
// // Render to the Canvas
// render.setCanvas(shadowCanvas)
// render.drawSprite(.shadow, position)
//
// // Resume rendering to screen and draw the Canvas
// render.setCanvas()
// render.drawCanvas(shadowCanvas, drawLayer = .shadow)
// ```
// :::
//
// :::caution[Performance]
// Canvases consume GPU resources. Use [`destroyCanvas`](#destroycanvas) to free them when no longer needed.
// :::
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
			id = id,
			size = gmath.Vector2{f32(width), f32(height)},
		},
	)

	return id
}
