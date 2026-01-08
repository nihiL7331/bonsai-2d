package render

import "bonsai:core"
import "bonsai:core/gmath"

// @ref
// Calculates the coordinate space for the main gameplay world.
// Creates a **View-Projection matrix** based on the **camera's position** and **zoom**.
getWorldSpace :: proc() -> CoordSpace {
	projectionMatrix := getWorldSpaceProjectionMatrix()
	// model matrix
	cameraMatrix := getWorldSpaceCameraMatrix()
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
// Generates the orthographic projection matrix for the world.
// Centered on **(0, 0).**
getWorldSpaceProjectionMatrix :: proc() -> gmath.Matrix4 {
	coreContext := core.getCoreContext()

	halfWidth := f32(coreContext.windowWidth) * 0.5
	halfHeight := f32(coreContext.windowHeight) * 0.5

	return gmath.matrixOrtho3d(-halfWidth, halfWidth, -halfHeight, halfHeight, -1, 1)
}

// @ref
// Returns the camera's world transform **(model matrix)**.
getWorldSpaceCameraMatrix :: proc() -> gmath.Matrix4 {
	coreContext := core.getCoreContext()

	cameraMatrix := gmath.Matrix4(1)
	cameraMatrix *= gmath.matrixTranslate(coreContext.camera.position)
	cameraMatrix *= gmath.matrixScale(getCameraZoom())
	return cameraMatrix
}

// @ref
// Maps a **screen-space** rectangle to a screen-space scissor rectangle.
// Used for clipping rendering to specific regions (masking).
setScissorRectangle :: proc(rectangle: gmath.Rectangle) {
	drawFrame := getDrawFrame()
	coreContext := core.getCoreContext()

	projection := drawFrame.reset.coordSpace.projectionMatrix

	bottomLeftWorld := gmath.Vector4{rectangle.x, rectangle.y, 0, 1}
	topRightWorld := gmath.Vector4{rectangle.z, rectangle.w, 0, 1}

	bottomLeftClip := projection * bottomLeftWorld
	topRightClip := projection * topRightWorld

	bottomLeftNdc := bottomLeftClip.xy / bottomLeftClip.w
	topRightNdc := topRightClip.xy / topRightClip.w

	frameBufferWidth := f32(coreContext.windowWidth)
	frameBufferHeight := f32(coreContext.windowHeight)

	scissorX := (bottomLeftNdc.x + 1.0) * 0.5 * frameBufferWidth
	scissorY := (bottomLeftNdc.y + 1.0) * 0.5 * frameBufferHeight

	scissorWidth := (topRightNdc.x + 1.0) * 0.5 * frameBufferWidth - scissorX
	scissorHeight := (topRightNdc.y + 1.0) * 0.5 * frameBufferHeight - scissorY

	setScissorCoordinates(gmath.Vector4{scissorX, scissorY, scissorWidth, scissorHeight})
}

// @ref
// Calculates the `zoom` factor required to fit the fixed `GAME_HEIGHT` into the current window height.
getCameraZoom :: proc() -> f32 {
	coreContext := core.getCoreContext()

	when core.SCALE_MODE == core.ScaleMode.FixedWidth {
		return f32(core.GAME_WIDTH) / f32(coreContext.windowWidth)
	} else {
		return f32(core.GAME_HEIGHT) / f32(coreContext.windowHeight)
	}
}

// @ref
// Generates the projection matrix for the **UI**.
// Handles aspect ratio scaling to ensure the UI fits within the design resolution (`GAME_WIDTH/HEIGHT`).
getScreenSpaceProjectionMatrix :: proc() -> gmath.Matrix4 {
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

	// viewLeft := (f32(core.GAME_WIDTH) * 0.5) - (viewWidth * 0.5)
	// viewRight := viewLeft + viewWidth
	left: f32 = 0.0
	right := viewWidth
	bottom: f32 = 0.0
	top := viewHeight


	return gmath.matrixOrtho3d(left, right, bottom, top, -1, 1)
}

// @ref
// Helper to get specific screen coordinates based on a `Pivot` (anchoring).
// Useful for positioning UI elements relative to screen edges.
getScreenSpacePivot :: proc(pivot: gmath.Pivot) -> gmath.Vector2 {
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

	left: f32 = 0.0
	right := viewWidth
	bottom: f32 = 0.0
	top := viewHeight

	centerX: f32 = (left + right) * 0.5
	centerY: f32 = (top + bottom) * 0.5

	switch pivot {
	case gmath.Pivot.topLeft:
		return gmath.Vector2{left, top}
	case gmath.Pivot.topCenter:
		return gmath.Vector2{centerX, top}
	case gmath.Pivot.topRight:
		return gmath.Vector2{right, top}
	case gmath.Pivot.centerLeft:
		return gmath.Vector2{left, centerY}
	case gmath.Pivot.centerCenter:
		return gmath.Vector2{centerX, centerY}
	case gmath.Pivot.centerRight:
		return gmath.Vector2{right, centerY}
	case gmath.Pivot.bottomLeft:
		return gmath.Vector2{left, bottom}
	case gmath.Pivot.bottomCenter:
		return gmath.Vector2{centerX, bottom}
	case gmath.Pivot.bottomRight:
		return gmath.Vector2{right, bottom}
	}
	return gmath.Vector2{0.0, 0.0}
}
