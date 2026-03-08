package render

import "core:log"
import "core:mem"

import "bonsai:core"
import "bonsai:core/gmath"
import sokol_gfx "bonsai:libs/sokol/gfx"

@(private = "file")
_scissorState: ScissorState

@(private = "file")
_scissorStack: [dynamic]gmath.Rectangle

// @ref
// Sets the background clear color.
setClearColor :: proc(col: gmath.Vector4) {
	_renderContext.passAction = {
		colors = {0 = {load_action = .CLEAR, clear_value = transmute(sokol_gfx.Color)(col)}},
	}
}

// @ref
// Pushes a new scissor rectangle onto the stack.
// Automatically intersects with the previous scissor to ensure nested clipping works.
pushScissor :: proc(rectangle: gmath.Rectangle) {
	targetRectangle := rectangle

	if len(_scissorStack) > 0 {
		parentRectangle := _scissorStack[len(_scissorStack) - 1]

		targetRectangle.x = max(parentRectangle.x, rectangle.x)
		targetRectangle.y = max(parentRectangle.y, rectangle.y)
		targetRectangle.z = min(parentRectangle.z, rectangle.z)
		targetRectangle.w = min(parentRectangle.w, rectangle.w)

		if targetRectangle.x > targetRectangle.z {
			targetRectangle.x = parentRectangle.x
			targetRectangle.z = parentRectangle.x
		}
		if targetRectangle.y > targetRectangle.w {
			targetRectangle.y = parentRectangle.y
			targetRectangle.w = parentRectangle.y
		}
	}

	append(&_scissorStack, targetRectangle)

	setScissorCoordinates(_getScissorRectangle(targetRectangle))
}

// @ref
// Pops the current scissor, restoring the previous state.
// If the stack becomes empty, scissoring is disabled.
popScissor :: proc() {
	if len(_scissorStack) == 0 {
		log.warn("Attempted to pop an empty scissor stack.")
		return
	}

	pop(&_scissorStack)

	if len(_scissorStack) > 0 {
		parentRectangle := _scissorStack[len(_scissorStack) - 1]
		setScissorCoordinates(_getScissorRectangle(parentRectangle))
	} else {
		clearScissor()
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
// Disables the scissor test.
clearScissor :: proc() {
	if !_scissorState.enabled do return

	flushBatch()

	_scissorState.enabled = false
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

@(private = "file")
_getScissorRectangle :: proc(rectangle: gmath.Rectangle) -> gmath.Rectangle {
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

	return gmath.Rectangle{scissorX, scissorY, scissorWidth, scissorHeight}
}

@(private = "package")
_applyScissor :: proc() {
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
}

@(private = "package")
_initScissorStack :: proc() {
	_scissorStack = make([dynamic]gmath.Rectangle, 0, 10) // max 10 nested scissors
}

@(private = "package")
_resetScissorStack :: proc() {
	clear(&_scissorStack)
	_scissorState.enabled = false
}

@(private = "package")
_destroyScissorStack :: proc() {
	delete(_scissorStack)
}
