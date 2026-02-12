package render

import "bonsai:core"
import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import "bonsai:generated"

// standard texture index reserved for a 1x1 white pixel
@(private = "file")
WHITE_TEXTURE_INDEX: u8 : 255

// @ref
// Main function for drawing game entities.
// **Supports rotation, animations, pivoting and camera culling.**
// Accepts either a `f32` or a [`Vector3`](https://bonsai-framework.dev/reference/core/gmath/#vector3)
// as the rotation. If a `f32` is provided, the sprite is rotated on the **Z axis**.
// :::note
// The rotation angle should be provided **in radians**.
// :::
drawSprite :: proc {
	_drawSpriteVector3Rotation,
	_drawSpriteF32Rotation,
}

@(private = "file")
_drawSpriteVector3Rotation :: proc(
	position: gmath.Vector2,
	sprite: generated.SpriteName,
	rotation: gmath.Vector3, // in radians
	pivot := gmath.Pivot.bottomLeft,
	scale := gmath.Vector2{1, 1},
	drawOffset := gmath.Vector2{},
	transform := gmath.Matrix4(1),
	animationIndex := 0,
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := DrawLayer{},
	flags := QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	sortKey: f32 = 0.0,
	isCullingEnabled := false,
) {
	setTexture(_atlas.view)

	rectangleSize := getSpriteSize(sprite)
	frameCount := generated.getFrameCount(sprite)

	// assuming horizontal strip animation layout
	rectangleSize.x /= f32(frameCount)

	// camera culling
	if isCullingEnabled {
		coreContext := core.getCoreContext()
		cameraBounds := coreContext.camera.bounds

		// uses max to handle rotation safely
		maxDimension := max(rectangleSize.x, rectangleSize.y)

		spriteRectangle := gmath.rectangleMake(
			position,
			gmath.Vector2{maxDimension, maxDimension},
			pivot,
		)
		spriteRectangle = gmath.shift(spriteRectangle, -drawOffset)

		if !gmath.rectangleIntersects(spriteRectangle, cameraBounds) do return
	}

	// calculate local transform matrix
	localTransform := gmath.Matrix4(1)
	localTransform *= gmath.matrixTranslate(position - drawOffset)
	if rotation != {} {
		localTransform *= gmath.matrixRotate(rotation)
	}
	localTransform *= gmath.matrixScale(scale)
	localTransform *= transform
	pivotOffset := rectangleSize * -gmath.scaleFromPivot(pivot)
	localTransform *= gmath.matrixTranslate(pivotOffset)


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
		sortKey = sortKey,
	)
}

@(private = "file")
_drawSpriteF32Rotation :: proc(
	position: gmath.Vector2,
	sprite: generated.SpriteName,
	rotation: f32 = 0.0, // in radians
	pivot := gmath.Pivot.bottomLeft,
	scale := gmath.Vector2{1, 1},
	drawOffset := gmath.Vector2{},
	transform := gmath.Matrix4(1),
	animationIndex := 0,
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := DrawLayer{},
	flags := QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	sortKey: f32 = 0.0,
	isCullingEnabled := false,
) {
	setTexture(_atlas.view)

	rectangleSize := getSpriteSize(sprite)
	frameCount := generated.getFrameCount(sprite)

	// assuming horizontal strip animation layout
	rectangleSize.x /= f32(frameCount)

	// camera culling
	if isCullingEnabled {
		coreContext := core.getCoreContext()
		cameraBounds := coreContext.camera.bounds

		// uses max to handle rotation safely
		maxDimension := max(rectangleSize.x, rectangleSize.y)

		spriteRectangle := gmath.rectangleMake(
			position,
			gmath.Vector2{maxDimension, maxDimension},
			pivot,
		)
		spriteRectangle = gmath.shift(spriteRectangle, -drawOffset)

		if !gmath.rectangleIntersects(spriteRectangle, cameraBounds) do return
	}

	// calculate local transform matrix
	localTransform := gmath.Matrix4(1)
	localTransform *= gmath.matrixTranslate(position - drawOffset)
	if rotation != 0 {
		localTransform *= gmath.matrixRotateZ(rotation)
	}
	localTransform *= gmath.matrixScale(scale)
	localTransform *= transform
	pivotOffset := rectangleSize * -gmath.scaleFromPivot(pivot)
	localTransform *= gmath.matrixTranslate(pivotOffset)


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
		sortKey = sortKey,
	)
}

// @ref
// Draws a quadratic bezier curve (`start` -> `control` -> `end`).
drawBezierQuad :: proc(
	start, control, end: gmath.Vector2,
	color: gmath.Color,
	thickness: f32 = 1.0,
	segments: uint = 32,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	previousPosition := start

	for i in 1 ..= segments {
		t := f32(i) / f32(segments)
		inverseT := 1.0 - t

		position := (inverseT * inverseT) * start + (2 * inverseT * t) * control + (t * t) * end

		drawLine(previousPosition, position, color, thickness, drawLayer, sortKey)
		previousPosition = position
	}
}

// @ref
// Draws a line between `start` and `end` with a specified `thickness`.
// :::note
// Uses [`drawRectangleTransform`](#drawrectangletransform) internally to stretch a white pixel.
// :::
drawLine :: proc(
	start: gmath.Vector2,
	end: gmath.Vector2,
	color: gmath.Color,
	thickness: f32 = 1.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	length := gmath.distance(start, end)
	angle := gmath.vectorToAngle(end.y - start.y, end.x - start.x)

	transform := gmath.matrixTranslate(start)
	transform *= gmath.matrixRotateZ(angle)
	transform *= gmath.matrixTranslate(gmath.Vector2{0, -0.5 * thickness})

	drawRectangleTransform(
		transform = transform,
		size = gmath.Vector2{length, thickness},
		color = color,
		drawLayer = drawLayer,
		sortKey = sortKey,
	)
}

// @ref
// Draws a dashed line between `start` and `end`.
// `dashLength` is the length of the solid part, `gapLength` is the empty space.
drawDashedLine :: proc(
	start, end: gmath.Vector2,
	color: gmath.Color,
	thickness: f32 = 1.0,
	dashLength: f32 = 10.0,
	gapLength: f32 = 5.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	difference := end - start
	totalLength := gmath.length(difference)
	direction := gmath.normalize(difference)

	currentDistance: f32 = 0.0

	for currentDistance < totalLength {
		lengthRemaining := totalLength - currentDistance
		currentDashLength := min(dashLength, lengthRemaining)

		point1 := start + (direction * currentDistance)
		point2 := point1 + (direction * currentDashLength)

		drawLine(point1, point2, color, thickness, drawLayer, sortKey)

		currentDistance += dashLength + gapLength
	}
}

// @ref
// Draws an arrow pointing from `start` to `end`.
// `headSize` determines the length of the arrow tip lines.
drawArrow :: proc(
	start, end: gmath.Vector2,
	color: gmath.Color,
	thickness: f32 = 1.0,
	headSize: f32 = 10.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	drawLine(start, end, color, thickness, drawLayer, sortKey)

	angle := gmath.vectorToAngle(end.y - start.y, end.x - start.x)

	point1 := end + gmath.angleToVector(angle + gmath.PI * 0.75) * headSize
	point2 := end + gmath.angleToVector(angle - gmath.PI * 0.75) * headSize

	drawLine(end, point1, color, thickness, drawLayer, sortKey)
	drawLine(end, point2, color, thickness, drawLayer, sortKey)
}

// @ref
// Draws a filled circle.
// :::note
// Internally it's just a wrapper around [`drawRegularPolygon`](#drawregularpolygon) with high segment count.
// :::
drawCircle :: proc(
	center: gmath.Vector2,
	radius: f32,
	color: gmath.Color,
	segments: uint = 32,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	drawRegularPolygon(center, radius, segments, color, 0.0, drawLayer, sortKey)
}

// @ref
// Draws the outline of a circle using line segments.
// Internally it just calls the [`drawRegularPolygonLines`](#drawregularpolygonlines)
// function with a high default count of segments.
drawCircleLines :: proc(
	center: gmath.Vector2,
	radius: f32,
	color: gmath.Color,
	segments: uint = 32,
	thickness: f32 = 1.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	drawRegularPolygonLines(center, radius, segments, color, thickness, 0.0, drawLayer, sortKey)
}

// @ref
// Draws the outline of a [`Rectangle`](https://bonsai-framework.dev/reference/core/gmath/#rectangle).
// The border grows **outwards** from the rectangle edges.
drawRectangleLines :: proc(
	rectangle: gmath.Rectangle,
	color: gmath.Color,
	thickness: f32 = 1.0,
	rotation: f32 = 0.0, // in radians
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
	isCullingEnabled := false,
) {
	if isCullingEnabled {
		coreContext := core.getCoreContext()
		cameraBounds := coreContext.camera.bounds

		if !gmath.rectangleIntersects(cameraBounds, rectangle) do return
	}

	transform := gmath.matrixTranslate(rectangle.xy)

	if rotation != 0 {
		transform *= gmath.matrixRotateZ(rotation)
	}

	size := gmath.getRectangleSize(rectangle)
	fullWidth := size.x + (thickness * 2)

	// top bar
	drawRectangleTransform(
		transform = transform * gmath.matrixTranslate(gmath.Vector2{-thickness, size.y}),
		size = gmath.Vector2{fullWidth, thickness},
		color = color,
		drawLayer = drawLayer,
		sortKey = sortKey,
	)

	// bottom bar
	drawRectangleTransform(
		transform = transform * gmath.matrixTranslate(gmath.Vector2{-thickness, -thickness}),
		size = gmath.Vector2{fullWidth, thickness},
		color = color,
		drawLayer = drawLayer,
		sortKey = sortKey,
	)

	// left bar
	drawRectangleTransform(
		transform = transform * gmath.matrixTranslate(gmath.Vector2{-thickness, 0}),
		size = gmath.Vector2{thickness, size.y},
		color = color,
		drawLayer = drawLayer,
		sortKey = sortKey,
	)

	// right bar
	drawRectangleTransform(
		transform = transform * gmath.matrixTranslate(gmath.Vector2{size.x, 0}),
		size = gmath.Vector2{thickness, size.y},
		color = color,
		drawLayer = drawLayer,
		sortKey = sortKey,
	)
}

// @ref
// Draws a triangle outline.
// Expects points to be listed in a **counter-clockwise** order.
drawTriangleLines :: proc(
	point1, point2, point3: gmath.Vector2,
	color: gmath.Color,
	thickness: f32 = 1.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	drawLine(point1, point2, color, thickness, drawLayer, sortKey)
	drawLine(point2, point3, color, thickness, drawLayer, sortKey)
	drawLine(point3, point1, color, thickness, drawLayer, sortKey)
}

// @ref
// Draws the outline of a polygon.
// Expects points to be listed in a **counter-clockwise** order.
drawPolygonLines :: proc(
	points: []gmath.Vector2,
	color: gmath.Color,
	thickness: f32 = 1.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	count := len(points)
	if count < 2 do return

	for i in 0 ..< count {
		point1 := points[i]
		point2 := points[(i + 1) % count]

		drawLine(point1, point2, color, thickness, drawLayer, sortKey)
	}
}

// @ref
// Draws the outline of a regular N-gon.
// :::note
// The shape starts rotated at 90 degrees to point up.
// A `rotation` of `0.0` results in the first vertex being at 12 o'clock.
// :::
drawRegularPolygonLines :: proc(
	center: gmath.Vector2,
	radius: f32,
	sides: uint,
	color: gmath.Color,
	thickness: f32 = 1.0,
	rotation: f32 = 0.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	angleStep := gmath.TAU / f32(sides)

	previousAngle: f32 = gmath.PI / 2
	previousPosition := center + gmath.angleToVector(previousAngle) * radius

	for i in 1 ..= sides {
		currentAngle := previousAngle + f32(i) * angleStep
		nextPosition := center + gmath.angleToVector(currentAngle) * radius
		drawLine(previousPosition, nextPosition, color, thickness, drawLayer, sortKey)
		previousPosition = nextPosition
	}
}

// @ref
// Draws a filled triangle.
// Expects points to be listed in a **counter-clockwise** order.
drawTriangle :: proc(
	point1, point2, point3: gmath.Vector2,
	color: gmath.Color,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	_drawTriangleBackend(point1, point2, point3, color, drawLayer, sortKey)
}

// @ref
// Draws a filled generic polygon.
// Expects points to be listed in a **counter-clockwise** order.
// :::note
// The polygon **must be convex**.
// :::
drawPolygon :: proc(
	points: []gmath.Vector2,
	color: gmath.Color,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	if len(points) < 3 do return

	center := points[0]

	for i in 1 ..< len(points) - 1 {
		point2 := points[i]
		point3 := points[i + 1]

		drawTriangle(center, point2, point3, color, drawLayer, sortKey)
	}
}

// @ref
// Draws a filled regular N-gon.
// :::note
// The shape starts rotated at 90 degrees to point up.
// A `rotation` of `0.0` results in the first vertex being at 12 o'clock.
// :::
drawRegularPolygon :: proc(
	center: gmath.Vector2,
	radius: f32,
	sides: uint,
	color: gmath.Color,
	rotation: f32 = 0.0,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	if sides < 3 do return

	points := make([dynamic]gmath.Vector2, 0, context.temp_allocator)

	angleStep := gmath.TAU / f32(sides)
	startingAngle: f32 = gmath.PI / 2.0

	for i in 0 ..< sides {
		angle := startingAngle + (f32(i) * angleStep) + rotation

		x := center.x + gmath.cos(angle) * radius
		y := center.y + gmath.sin(angle) * radius

		append(&points, gmath.Vector2{x, y})
	}

	drawPolygon(points[:], color, drawLayer, sortKey)
}

// @ref
// Draws a simple [`Rectangle`](https://bonsai-framework.dev/reference/core/gmath/rectangle).
// :::tip
// Useful for UI, debug shapes or non-sprite elements.
// :::
drawRectangle :: proc(
	rectangle: gmath.Rectangle,
	rotation: f32 = 0.0, // in radians
	sprite := generated.SpriteName.nil,
	uv := DEFAULT_UV,
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := DrawLayer.nil,
	flags := QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	sortKey: f32 = 0.0,
	isCullingEnabled := false,
) {
	if isCullingEnabled {
		coreContext := core.getCoreContext()
		cameraBounds := coreContext.camera.bounds

		if !gmath.rectangleIntersects(cameraBounds, rectangle) do return
	}

	transform := gmath.matrixTranslate(rectangle.xy)
	if rotation != 0 {
		transform *= gmath.matrixRotateZ(rotation)
	}
	size := gmath.getRectangleSize(rectangle)

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
		sortKey,
	)
}

// @ref
// Helper to draw a sprite scaled to fit inside a target rectangle.
// Maintains aspect ratio (letterboxing).
drawSpriteInRectangle :: proc(
	sprite: generated.SpriteName,
	position: gmath.Vector2,
	size: gmath.Vector2,
	transform := gmath.Matrix4(1),
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := DrawLayer.nil,
	flags := QuadFlags(0),
	paddingPercent: f32 = 0.1,
) {
	imageSize := getSpriteSize(sprite)
	paddedSize := size * (1.0 - paddingPercent)
	targetRectangle := gmath.rectangleMake(position, paddedSize)

	{ 	//shrink rect if sprite is too small
		sizeDifference := gmath.max(gmath.getRectangleSize(targetRectangle) - imageSize, 0)
		targetRectangle = gmath.rectangleExpand(targetRectangle, -0.5 * sizeDifference)
	}

	if imageSize.x > imageSize.y {
		rectangleSize := gmath.getRectangleSize(targetRectangle)
		targetRectangle.w = targetRectangle.y + (rectangleSize.x * (imageSize.y / imageSize.x))

		newHeight := targetRectangle.w - targetRectangle.y
		targetRectangle = gmath.shift(
			targetRectangle,
			gmath.Vector2{0, (rectangleSize.y - newHeight) * 0.5},
		)
	} else if imageSize.y > imageSize.x {
		rectangleSize := gmath.getRectangleSize(targetRectangle)
		targetRectangle.z = targetRectangle.x + (rectangleSize.y * (imageSize.x / imageSize.y))

		newWidth := targetRectangle.z - targetRectangle.x
		targetRectangle = gmath.shift(
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
	sprite := generated.SpriteName.nil,
	uv := DEFAULT_UV,
	textureIndex: u8 = 0,
	animationIndex := 0,
	color := colors.WHITE,
	colorOverride := gmath.Color{},
	drawLayer := DrawLayer.nil,
	flags := QuadFlags{},
	parameters := gmath.Vector4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	sortKey: f32 = 0.0,
) {
	mutSize := size
	mutUv := uv
	mutTextureIndex := textureIndex

	drawFrame := getDrawFrame()

	if mutUv == DEFAULT_UV {
		mutUv = getAtlasUv(sprite)

		frameCount := generated.getFrameCount(sprite)
		frameSize := mutSize
		frameSize.x /= f32(frameCount)
		uvSize := gmath.getRectangleSize(mutUv)
		uvFrameSize := uvSize * gmath.Vector2{frameSize.x / mutSize.x, 1.0}
		mutUv.zw = mutUv.xy + uvFrameSize
		mutUv = gmath.shift(mutUv, gmath.Vector2{f32(animationIndex) * uvFrameSize.x, 0})
	}

	when ODIN_DEBUG {
		assert(drawFrame.reset.coordSpace != {}, "No coordinate space set.")
	}

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
	worldBottomLeft := gmath.transformPoint(worldMatrix, bottomLeft)
	worldTopLeft := gmath.transformPoint(worldMatrix, topLeft)
	worldTopRight := gmath.transformPoint(worldMatrix, topRight)
	worldBottomRight := gmath.transformPoint(worldMatrix, bottomRight)

	if mutTextureIndex == 0 && sprite == .nil {
		mutTextureIndex = WHITE_TEXTURE_INDEX
	}

	drawQuadProjected(
		{worldBottomLeft, worldTopLeft, worldTopRight, worldBottomRight},
		{color, color, color, color},
		{mutUv.xy, mutUv.xw, mutUv.zw, mutUv.zy},
		mutTextureIndex,
		mutSize,
		colorOverride,
		drawLayer,
		flags,
		parameters,
		sortKey,
	)
}

// HACK:
// for now we just draw a quad that has one tri squashed,
// might want to look into making it cleaner/faster later on
@(private = "file")
_drawTriangleBackend :: proc(
	point1, point2, point3: gmath.Vector2,
	color: gmath.Color,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
) {
	drawQuadProjected(
		{point1, point2, point3, point3},
		{color, color, color, color},
		{DEFAULT_UV.xy, DEFAULT_UV.xw, DEFAULT_UV.zw, DEFAULT_UV.zw},
		WHITE_TEXTURE_INDEX,
		{1, 1},
		{},
		drawLayer,
		{},
		{},
		sortKey,
	)
}
