package render

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import "bonsai:generated"
import stb_truetype "bonsai:libs/stb/truetype"

import "core:log"

// @ref
// Default text drawing alias **(includes drop shadow)**.
drawText :: drawTextWithDropShadow

// @ref
// Draws text with a **hard-coded** drop shadow for contrast**.
// Retrieves the font using the **automatically** generated [`FontName`](https://bonsai-framework.dev/reference/generated/#fontname) enum.
// Accepts either a `f32` or a [`Vector3`](https://bonsai-framework.dev/reference/core/gmath/#vector3)
// as the rotation. If a `f32` is provided, the text is rotated on the **Z axis**.
// :::caution
// Fonts are currently rendered as bitmaps. For the sharpest results, you may want to find a native font size (e.g. 12 for `PixelCode`)
// and use the `scale` argument to control the size of the text. When fonts will be rendered via SDF, this issue will be fixed.
// :::
drawTextWithDropShadow :: proc {
	_drawTextWithDropShadowVector3Angle,
	_drawTextWithDropShadowF32Angle,
}

@(private = "file")
_drawTextWithDropShadowVector3Angle :: proc(
	position: gmath.Vector2,
	text: string,
	fontName: generated.FontName = generated.FontName.PixelCode,
	fontSize: uint = 12,
	rotation: gmath.Vector3, // in radians
	dropShadowColor := colors.BLACK,
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	shadowOffset := gmath.Vector2{1, -1} * scale

	// fetch font resource
	font, ok := getFont(fontName, fontSize)
	if !ok {
		log.errorf("Failed to draw font: %v (text: %v)", fontName, text)
		return gmath.Vector2{0, 0}
	}

	// draw shadow
	_drawTextSimpleFontVector3Angle(
		position + shadowOffset,
		text,
		font = &font,
		rotation = rotation,
		color = dropShadowColor * color, // tint the shadow by the main color
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)

	// draw main text
	textDimensions := _drawTextSimpleFontVector3Angle(
		position,
		text,
		font = &font,
		rotation = rotation,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)

	return textDimensions
}

@(private = "file")
_drawTextWithDropShadowF32Angle :: proc(
	position: gmath.Vector2,
	text: string,
	fontName: generated.FontName = generated.FontName.PixelCode,
	fontSize: uint = 12,
	rotation: f32 = 0.0, // in radians
	dropShadowColor := colors.BLACK,
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	shadowOffset := gmath.Vector2{1, -1} * scale

	// fetch font resource
	font, ok := getFont(fontName, fontSize)
	if !ok {
		log.errorf("Failed to draw font: %v (text: %v)", fontName, text)
		return gmath.Vector2{0, 0}
	}

	// draw shadow
	_drawTextSimpleFontF32Angle(
		position + shadowOffset,
		text,
		font = &font,
		rotation = rotation,
		color = dropShadowColor * color, // tint the shadow by the main color
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)

	// draw main text
	textDimensions := _drawTextSimpleFontF32Angle(
		position,
		text,
		font = &font,
		rotation = rotation,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)

	return textDimensions
}

// @ref
// Draws text without a drop shadow.
// Retrieves the font using the **automatically** generated [`FontName`](https://bonsai-framework.dev/reference/generated/#fontname) enum.
// Accepts either a `f32` or a [`Vector3`](https://bonsai-framework.dev/reference/core/gmath/#vector3)
// as the rotation. If a `f32` is provided, the text is rotated on the **Z axis**.
// :::caution
// Fonts are currently rendered as bitmaps. For the sharpest results, you may want to find a native font size (e.g. 12 for `PixelCode`)
// and use the `scale` argument to control the size of the text. When fonts will be rendered via SDF, this issue will be fixed.
// :::
drawTextSimple :: proc {
	_drawTextSimpleVector3Angle,
	_drawTextSimpleF32Angle,
}

@(private = "file")
_drawTextSimpleVector3Angle :: proc(
	position: gmath.Vector2,
	text: string,
	fontName: generated.FontName = generated.FontName.PixelCode,
	fontSize: uint = 12,
	rotation: gmath.Vector3, // in radians
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	font, ok := getFont(fontName, fontSize)
	if !ok {
		log.errorf("Failed to draw font: %v (text: %v)", fontName, text)
		return gmath.Vector2{0, 0}
	}

	return _drawTextSimpleFontVector3Angle(
		position,
		text,
		&font,
		rotation,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)
}

@(private = "file")
_drawTextSimpleF32Angle :: proc(
	position: gmath.Vector2,
	text: string,
	fontName: generated.FontName = generated.FontName.PixelCode,
	fontSize: uint = 12,
	rotation: f32 = 0.0, // in radians
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	font, ok := getFont(fontName, fontSize)
	if !ok {
		log.errorf("Failed to draw font: %v (text: %v)", fontName, text)
		return gmath.Vector2{0, 0}
	}

	return _drawTextSimpleFontF32Angle(
		position,
		text,
		&font,
		rotation,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)
}

// @ref
// Internal primitive for drawing a single line of text.
// Calculates layout, pivots, and batches the quads.
// Accepts either a `f32` or a [`Vector3`](https://bonsai-framework.dev/reference/core/gmath/#vector3)
// as the rotation. If a `f32` is provided, the text is rotated on the **Z axis**.
drawTextSimpleFont :: proc {
	_drawTextSimpleFontVector3Angle,
	_drawTextSimpleFontF32Angle,
}

@(private = "file")
_drawTextSimpleFontVector3Angle :: proc(
	position: gmath.Vector2,
	text: string,
	font: ^Font,
	rotation: gmath.Vector3, // in radians
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> (
	textBounds: gmath.Vector2,
) {
	// find size
	totalTextSize: gmath.Vector2
	for char, i in text {
		advanceX: f32
		advanceY: f32
		quad: stb_truetype.aligned_quad

		stb_truetype.GetBakedQuad(
			&font.characterData[0],
			BITMAP_WIDTH,
			BITMAP_HEIGHT,
			i32(char) - 32,
			&advanceX,
			&advanceY,
			&quad,
			false,
		)
		// calculate char dimensions
		// x0, y0 - top-left, x1, y1 - bottom-right in STB

		charSize := gmath.abs(gmath.Vector2{quad.x0 - quad.x1, quad.y0 - quad.y1})

		bottomLeft := gmath.Vector2{quad.x0, -quad.y1}
		topRight := gmath.Vector2{quad.x1, -quad.y0}

		when ODIN_DEBUG {
			assert(bottomLeft + charSize == topRight, "Font sizing error (find size)")
		}

		if i == len(text) - 1 {
			totalTextSize.x += charSize.x
		} else {
			totalTextSize.x += advanceX
		}

		totalTextSize.y = max(totalTextSize.y, topRight.y)
	}

	pivotOffset := totalTextSize * -gmath.scaleFromPivot(pivot)

	// draw characters
	cursorX: f32
	cursorY: f32

	//draw
	for char in text {
		advanceX: f32
		advanceY: f32
		quad: stb_truetype.aligned_quad
		stb_truetype.GetBakedQuad(
			&font.characterData[0],
			BITMAP_WIDTH,
			BITMAP_HEIGHT,
			i32(char) - 32,
			&advanceX,
			&advanceY,
			&quad,
			false,
		)
		// x0, y0,  s0, t0 <=> top-left
		// x1, y1,  s1, t1 <=> bottom-right

		size := gmath.Vector2{abs(quad.x0 - quad.x1), abs(quad.y0 - quad.y1)}
		bottomLeft := gmath.Vector2{quad.x0, -quad.y1}

		offsetToRenderAt := gmath.Vector2{cursorX, cursorY} + bottomLeft
		offsetToRenderAt += pivotOffset

		uv := gmath.Vector4{quad.s0, quad.t1, quad.s1, quad.t0}

		transform := gmath.Matrix4(1)
		transform *= gmath.matrixTranslate(position)
		if rotation != {} {
			transform *= gmath.matrixRotate(rotation)
		}
		transform *= gmath.matrixScale(scale)
		transform *= gmath.matrixTranslate(offsetToRenderAt)

		drawRectangleTransform(
			transform,
			size,
			uv = uv,
			textureIndex = 1,
			colorOverride = colorOverride,
			color = color,
		)

		cursorX += advanceX
		cursorY += -advanceY
	}

	return gmath.abs(totalTextSize * scale)
}

@(private = "file")
_drawTextSimpleFontF32Angle :: proc(
	position: gmath.Vector2,
	text: string,
	font: ^Font,
	rotation: f32, // in radians
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> (
	textBounds: gmath.Vector2,
) {
	// find size
	totalTextSize: gmath.Vector2
	for char, i in text {
		advanceX: f32
		advanceY: f32
		quad: stb_truetype.aligned_quad

		stb_truetype.GetBakedQuad(
			&font.characterData[0],
			BITMAP_WIDTH,
			BITMAP_HEIGHT,
			i32(char) - 32,
			&advanceX,
			&advanceY,
			&quad,
			false,
		)
		// calculate char dimensions
		// x0, y0 - top-left, x1, y1 - bottom-right in STB

		charSize := gmath.abs(gmath.Vector2{quad.x0 - quad.x1, quad.y0 - quad.y1})

		bottomLeft := gmath.Vector2{quad.x0, -quad.y1}
		topRight := gmath.Vector2{quad.x1, -quad.y0}

		when ODIN_DEBUG {
			assert(bottomLeft + charSize == topRight, "Font sizing error (find size)")
		}

		if i == len(text) - 1 {
			totalTextSize.x += charSize.x
		} else {
			totalTextSize.x += advanceX
		}

		totalTextSize.y = max(totalTextSize.y, topRight.y)
	}

	pivotOffset := totalTextSize * -gmath.scaleFromPivot(pivot)

	// draw characters
	cursorX: f32
	cursorY: f32

	//draw
	for char in text {
		advanceX: f32
		advanceY: f32
		quad: stb_truetype.aligned_quad
		stb_truetype.GetBakedQuad(
			&font.characterData[0],
			BITMAP_WIDTH,
			BITMAP_HEIGHT,
			i32(char) - 32,
			&advanceX,
			&advanceY,
			&quad,
			false,
		)
		// x0, y0,  s0, t0 <=> top-left
		// x1, y1,  s1, t1 <=> bottom-right

		size := gmath.Vector2{abs(quad.x0 - quad.x1), abs(quad.y0 - quad.y1)}
		bottomLeft := gmath.Vector2{quad.x0, -quad.y1}

		offsetToRenderAt := gmath.Vector2{cursorX, cursorY} + bottomLeft
		offsetToRenderAt += pivotOffset

		uv := gmath.Vector4{quad.s0, quad.t1, quad.s1, quad.t0}

		transform := gmath.Matrix4(1)
		transform *= gmath.matrixTranslate(position)
		if rotation != 0 {
			transform *= gmath.matrixRotateZ(rotation)
		}
		transform *= gmath.matrixScale(scale)
		transform *= gmath.matrixTranslate(offsetToRenderAt)

		drawRectangleTransform(
			transform,
			size,
			uv = uv,
			textureIndex = 1,
			colorOverride = colorOverride,
			color = color,
		)

		cursorX += advanceX
		cursorY += -advanceY
	}

	return gmath.abs(totalTextSize * scale)
}
