package render

import "bonsai:core"
import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import "bonsai:types/game"

// standard texture index reserved for a 1x1 white pixel
@(private = "file")
WHITE_TEXTURE_INDEX: u8 : 255

// @ref
// Main function for drawing game entities.
// **Supports rotation, animations, pivoting and camera culling.**
drawSprite :: proc(
	position: gmath.Vector2,
	sprite: game.SpriteName,
	rotation: f32 = 0.0, // in radians
	pivot := gmath.Pivot.centerCenter,
	isFlippedX := false,
	drawOffset := gmath.Vector2{},
	transform := gmath.Matrix4(1),
	animationIndex := 0,
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := game.DrawLayer{},
	flags := game.QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	drawLayerQueue := -1,
	isCullingEnabled := false,
) {
	rectangleSize := getSpriteSize(sprite)
	frameCount := game.getFrameCount(sprite)

	// assuming horizontal strip animation layout
	rectangleSize.x /= f32(frameCount)

	// camera culling
	if isCullingEnabled {
		coreContext := core.getCoreContext()
		cameraRectangle := coreContext.gameState.world.cameraRectangle

		// uses max to handle rotation safely
		maxDimension := max(rectangleSize.x, rectangleSize.y)

		spriteRectangle := gmath.rectangleMake(
			position,
			gmath.Vector2{maxDimension, maxDimension},
			pivot,
		)
		spriteRectangle = gmath.rectangleShift(spriteRectangle, -drawOffset)

		if !gmath.rectangleIntersects(spriteRectangle, cameraRectangle) do return
	}

	// calculate local transform matrix
	localTransform := gmath.Matrix4(1)
	localTransform *= gmath.matrixTranslate(position)

	if rotation != 0 {
		localTransform *= gmath.matrixRotate(rotation)
	}
	localTransform *= gmath.matrixScale(gmath.Vector2{isFlippedX ? -1.0 : 1.0, 1.0})
	localTransform *= transform

	// pivot adjustment
	pivotOffset := rectangleSize * -gmath.scaleFromPivot(pivot)
	localTransform *= gmath.matrixTranslate(pivotOffset)
	localTransform *= gmath.matrixTranslate(-drawOffset)

	drawRectangleTransform(
		localTransform,
		rectangleSize,
		sprite,
		animationIndex = animationIndex,
		color = color,
		colorOverride = colorOverride,
		drawLayer = drawLayer,
		flags = flags,
		parameters = parameters,
		cropTop = cropTop,
		cropLeft = cropLeft,
		cropBottom = cropBottom,
		cropRight = cropRight,
		drawLayerQueue = drawLayerQueue,
	)
}

// @ref
// Draws a simple **rectangle**. Useful for UI, debug shapes or non-sprite elements.
// **Supports an optional 1px outline**.
drawRectangle :: proc(
	rectangle: gmath.Rectangle,
	rotation: f32 = 0.0, // in radians
	sprite := game.SpriteName.nil,
	uv := DEFAULT_UV,
	outlineColor := gmath.Vector4{},
	color := colors.WHITE,
	colorOverride := gmath.Vector4{},
	drawLayer := game.DrawLayer{},
	flags := game.QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	drawLayerQueue := -1,
	isCullingEnabled := false,
) {
	if isCullingEnabled {
		coreContext := core.getCoreContext()
		cameraRectangle := coreContext.gameState.world.cameraRectangle

		if !gmath.rectangleIntersects(cameraRectangle, rectangle) do return
	}

	transform := gmath.matrixTranslate(rectangle.xy)
	if rotation != 0 {
		transform *= gmath.matrixRotate(rotation)
	}
	size := gmath.getRectangleSize(rectangle)

	if outlineColor != {} {
		outlineSize := size + gmath.Vector2(2)
		outlineTransform := transform * gmath.matrixTranslate(gmath.Vector2(-1))

		drawRectangleTransform(
			outlineTransform,
			outlineSize,
			color = outlineColor,
			uv = uv,
			colorOverride = colorOverride,
			drawLayer = drawLayer,
			flags = flags,
			parameters = parameters,
		)
	}

	drawRectangleTransform(
		transform,
		size,
		sprite,
		uv,
		0,
		0,
		color,
		colorOverride,
		drawLayer,
		flags,
		parameters,
		cropTop,
		cropLeft,
		cropBottom,
		cropRight,
		drawLayerQueue,
	)
}

// @ref
// Helper to draw a sprite scaled to fit inside a target rectangle.
// Maintains aspect ratio (letterboxing).
drawSpriteInRectangle :: proc(
	sprite: game.SpriteName,
	position: gmath.Vector2,
	size: gmath.Vector2,
	transform := gmath.Matrix4(1),
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := game.DrawLayer.nil,
	flags := game.QuadFlags(0),
	paddingPercent: f32 = 0.1,
) {
	imageSize := getSpriteSize(sprite)
	paddedSize := size * (1.0 - paddingPercent)
	targetRectangle := gmath.rectangleMake(position, paddedSize)

	{ 	//shrink rect if sprite is too small
		rectangleSize := gmath.getRectangleSize(targetRectangle)
		sizeDifferenceX := max(0.0, rectangleSize.x - imageSize.x)
		sizeDifferenceY := max(0.0, rectangleSize.y - imageSize.y)

		sizeDifference := gmath.Vector2{sizeDifferenceX, sizeDifferenceY}

		offset := targetRectangle.xy
		targetRectangle = gmath.rectangleShift(targetRectangle, -targetRectangle.xy)
		targetRectangle.xy += sizeDifference * 0.5
		targetRectangle.zw -= sizeDifference * 0.5
		targetRectangle = gmath.rectangleShift(targetRectangle, offset)
	}

	if imageSize.x > imageSize.y {
		rectangleSize := gmath.getRectangleSize(targetRectangle)
		targetRectangle.w = targetRectangle.y + (rectangleSize.x * (imageSize.y / imageSize.x))

		newHeight := targetRectangle.w - targetRectangle.y
		targetRectangle = gmath.rectangleShift(
			targetRectangle,
			gmath.Vector2{0, (rectangleSize.y - newHeight) * 0.5},
		)
	} else if imageSize.y > imageSize.x {
		rectangleSize := gmath.getRectangleSize(targetRectangle)
		targetRectangle.z = targetRectangle.x + (rectangleSize.y * (imageSize.x / imageSize.y))

		newWidth := targetRectangle.z - targetRectangle.x
		targetRectangle = gmath.rectangleShift(
			targetRectangle,
			gmath.Vector2{0, (rectangleSize.x - newWidth) * 0.5},
		)
	}

	drawRectangle(
		targetRectangle,
		color = color,
		sprite = sprite,
		colorOverride = colorOverride,
		drawLayer = drawLayer,
		flags = flags,
	)
}

// @ref
// Low-level function that pushes the final quad vertex data to the batcher.
drawRectangleTransform :: proc(
	transform: gmath.Matrix4,
	size: gmath.Vector2,
	sprite := game.SpriteName.nil,
	uv := DEFAULT_UV,
	textureIndex: u8 = 0,
	animationIndex := 0,
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := game.DrawLayer.nil,
	flags := game.QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	drawLayerQueue := -1,
) {
	mutSize := size
	mutUv := uv
	mutTextureIndex := textureIndex

	drawFrame := getDrawFrame()

	if mutUv == DEFAULT_UV {
		mutUv = atlasUvFromSprite(sprite)

		frameCount := game.getFrameCount(sprite)
		frameSize := mutSize
		frameSize.x /= f32(frameCount)
		uvSize := gmath.getRectangleSize(mutUv)
		uvFrameSize := uvSize * gmath.Vector2{frameSize.x / mutSize.x, 1.0}
		mutUv.zw = mutUv.xy + uvFrameSize
		mutUv = gmath.rectangleShift(mutUv, gmath.Vector2{f32(animationIndex) * uvFrameSize.x, 0})
	}

	assert(drawFrame.reset.coordSpace != {}, "No coordinate space set.")

	worldMatrix := transform

	{ 	// cropping
		if cropTop != 0.0 {
			newHeight := mutSize.y * (1.0 - cropTop)
			uvSize := gmath.getRectangleSize(mutUv)

			mutUv.w -= uvSize.y * cropTop
			mutSize.y = newHeight
		}
		if cropLeft != 0.0 {
			crop := mutSize.x * cropLeft
			mutSize.x -= crop

			uvSize := gmath.getRectangleSize(mutUv)
			mutUv.x += uvSize.x * cropLeft

			worldMatrix *= gmath.matrixTranslate(gmath.Vector2{crop, 0})
		}
		if cropBottom != 0.0 {
			crop := mutSize.y * (1.0 - cropBottom)
			difference: f32 = crop - mutSize.y
			mutSize.y = crop
			uvSize := gmath.getRectangleSize(mutUv)

			mutUv.y += uvSize.y * cropBottom

			worldMatrix *= gmath.matrixTranslate(gmath.Vector2{0, -difference})
		}
		if cropRight != 0.0 {
			mutSize.x *= 1.0 - cropRight
			uvSize := gmath.getRectangleSize(mutUv)
			mutUv.z -= uvSize.x * cropRight
		}
	}

	bottomLeft := gmath.Vector2{0, 0}
	topLeft := gmath.Vector2{0, mutSize.y}
	topRight := gmath.Vector2{mutSize.x, mutSize.y}
	bottomRight := gmath.Vector2{mutSize.x, 0}

	//transform local -> world
	p0 := (worldMatrix * gmath.Vector4{bottomLeft.x, bottomLeft.y, 0, 1}).xy
	p1 := (worldMatrix * gmath.Vector4{topLeft.x, topLeft.y, 0, 1}).xy
	p2 := (worldMatrix * gmath.Vector4{topRight.x, topRight.y, 0, 1}).xy
	p3 := (worldMatrix * gmath.Vector4{bottomRight.x, bottomRight.y, 0, 1}).xy

	if mutTextureIndex == 0 && sprite == .nil {
		mutTextureIndex = WHITE_TEXTURE_INDEX
	}

	drawQuadProjected(
		{p0, p1, p2, p3},
		{color, color, color, color},
		{mutUv.xy, mutUv.xw, mutUv.zw, mutUv.zy},
		mutTextureIndex,
		mutSize,
		colorOverride,
		drawLayer,
		flags,
		parameters,
		drawLayerQueue,
	)
}
