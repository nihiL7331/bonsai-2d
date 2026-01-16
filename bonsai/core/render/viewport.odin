package render

import sokol_gfx "bonsai:libs/sokol/gfx"

import "bonsai:core"
import "bonsai:core/gmath"

// @ref
// Helper to get specific screen/viewport coordinates based on a [`Pivot`](https://bonsai-framework.dev/reference/core/gmath/#pivot) (anchoring).
//
// Returns a [`Vector2`](https://bonsai-framework.dev/reference/core/gmath/#vector2) position.
// :::tip
// Useful for positioning UI elements relative to screen edges.
// :::
getViewportPivot :: proc(pivot: gmath.Pivot) -> gmath.Vector2 {
	rectangle := getViewportRectangle()

	return gmath.getRectanglePivot(rectangle, pivot)
}

// @ref
// Helper that calculates and creates a [`Rectangle`](https://bonsai-framework.dev/reference/core/gmath/#rectangle) containing the
// current viewport in **Screen Space**. Uses [`ScaleMode`](https://bonsai-framework.dev/reference/core/#scalemode) internally in its calculations.
getViewportRectangle :: proc() -> gmath.Rectangle {
	renderContext := getRenderContext()

	if renderContext.activeCanvasId != renderContext.defaultCanvasId {
		canvas := renderContext.canvases[renderContext.activeCanvasId]

		if canvas.image.id == sokol_gfx.INVALID_ID {
			return gmath.Color{0, 0, 0, 0}
		}

		width := f32(sokol_gfx.query_image_width(canvas.image))
		height := f32(sokol_gfx.query_image_height(canvas.image))

		return gmath.Rectangle{0.0, 0.0, width, height}
	}

	coreContext := core.getCoreContext()
	aspect := f32(coreContext.windowWidth) / f32(coreContext.windowHeight)

	viewWidth, viewHeight: f32

	when core.SCALE_MODE == core.ScaleMode.FixedWidth {
		viewWidth = f32(core.GAME_WIDTH)
		viewHeight = viewWidth / aspect
	} else {
		viewHeight = f32(core.GAME_HEIGHT)
		viewWidth = viewHeight * aspect
	}

	return gmath.Rectangle{0.0, 0.0, viewWidth, viewHeight}
}

// @ref
// Generates the projection matrix for the **UI**.
// Handles aspect ratio scaling to ensure the UI fits within the design resolution ([`GAME_WIDTH`](https://bonsai-framework.dev/reference/core/#game_width)/[`GAME_HEIGHT`](https://bonsai-framework.dev/reference/core/#game_height)).
getScreenSpaceProjectionMatrix :: proc() -> gmath.Matrix4 {
	rectangle := getViewportRectangle()

	return gmath.matrixOrtho3d(
		0.0,
		f64(rectangle.z - rectangle.x),
		0.0,
		f64(rectangle.w - rectangle.y),
		-1,
		1,
	)
}
