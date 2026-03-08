package render

import "bonsai:core"
import "bonsai:core/gmath"

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

@(private = "file")
_setCoordSpaceDefault :: proc() {
	_drawFrame.reset.coordSpace = getScreenSpace()
}

@(private = "file")
_setCoordSpaceValue :: proc(coordSpace: CoordSpace) {
	_drawFrame.reset.coordSpace = coordSpace
}
