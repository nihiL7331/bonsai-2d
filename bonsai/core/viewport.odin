package core

import "bonsai:core/gmath"

// @ref
// Defines how the game content scales to fit the window aspect ratio.
ScaleMode :: enum {
	// Locks vertical height.
	// Game height is constant, width is matched to fit.
	FixedHeight,
	// Locks horizontal width.
	// Game width is constant, height is matched to fit.
	FixedWidth,
}

// @ref
// The global configuration determining which scaling logic is active.
SCALE_MODE :: ScaleMode.FixedHeight

// @ref
// The internal design resolution width **in pixels**.
GAME_WIDTH :: 480

// @ref
// The internal design resolution height **in pixels**.
GAME_HEIGHT :: 270

// @ref
// Generates the orthographic projection matrix for the world.
// Centered on `(0, 0)`.
getWorldSpaceProjectionMatrix :: proc() -> gmath.Matrix4 {
	coreContext := getCoreContext()

	halfWidth := f32(coreContext.windowWidth) * 0.5
	halfHeight := f32(coreContext.windowHeight) * 0.5

	return gmath.matrixOrtho3d(-halfWidth, halfWidth, -halfHeight, halfHeight, -1, 1)
}

// @ref
// Returns the camera's world transform **(model matrix)**.
getWorldSpaceCameraMatrix :: proc() -> gmath.Matrix4 {
	coreContext := getCoreContext()

	cameraMatrix := gmath.Matrix4(1)
	cameraMatrix *= gmath.matrixTranslate(coreContext.camera.position)
	cameraMatrix *= gmath.matrixScale(getCameraZoom())
	return cameraMatrix
}

// @ref
// Calculates the `zoom` factor required to fit the fixed [`GAME_HEIGHT`](#game_height) into the current window height.
getCameraZoom :: proc() -> f32 {
	coreContext := getCoreContext()

	when SCALE_MODE == ScaleMode.FixedWidth {
		return f32(GAME_WIDTH) / f32(coreContext.windowWidth)
	} else {
		return f32(GAME_HEIGHT) / f32(coreContext.windowHeight)
	}
}
