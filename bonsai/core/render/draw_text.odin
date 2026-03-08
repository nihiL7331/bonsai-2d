package render

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import "bonsai:generated"

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
	sortKey: f32 = 0.0,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	shadowOffset := gmath.Vector2{1, -1} * scale

	// draw shadow
	_drawTextSimpleVector3Angle(
		position + shadowOffset,
		text,
		fontName = fontName,
		fontSize = fontSize,
		rotation = rotation,
		color = dropShadowColor * color, // tint the shadow by the main color
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		sortKey = sortKey,
		colorOverride = colorOverride,
	)

	// draw main text
	textDimensions := _drawTextSimpleVector3Angle(
		position,
		text,
		fontName = fontName,
		fontSize = fontSize,
		rotation = rotation,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		sortKey = sortKey,
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
	sortKey: f32 = 0.0,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	shadowOffset := gmath.Vector2{1, -1} * scale

	// draw shadow
	_drawTextSimpleF32Angle(
		position + shadowOffset,
		text,
		fontName = fontName,
		fontSize = fontSize,
		rotation = rotation,
		color = dropShadowColor * color, // tint the shadow by the main color
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		sortKey = sortKey,
		colorOverride = colorOverride,
	)

	// draw main text
	textDimensions := _drawTextSimpleF32Angle(
		position,
		text,
		fontName = fontName,
		fontSize = fontSize,
		rotation = rotation,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		sortKey = sortKey,
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
	fontName: generated.FontName = .PixelCode,
	fontSize: uint = 12,
	rotation: gmath.Vector3, // in radians
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
	colorOverride := gmath.Color{},
) -> (
	textBounds: gmath.Vector2,
) {
	font := &fontData[fontName]
	if !font.isLoaded do return {}

	setFontTexture(font)

	fontScale: f32
	finalFontSize: f32
	if font.isPixel {
		nativeSize := f32(font.nativeSize)
		if nativeSize == 0 do nativeSize = 1
		fontScale = f32(fontSize) / nativeSize
		finalFontSize = nativeSize
	} else {
		fontScale = f32(fontSize) / 64.0 // fonts are packed at 64.0px scale in rust
		finalFontSize = f32(fontSize)
	}

	totalTextSize: gmath.Vector2
	currentLineWidth: f32 = 0.0
	maxLineWidth: f32 = 0.0
	lineCount: int = 1

	for char in text {
		if char == '\n' {
			maxLineWidth = max(maxLineWidth, currentLineWidth)
			currentLineWidth = 0
			lineCount += 1
			continue
		}

		if char == ' ' {
			advance: f32 = f32(finalFontSize) * 0.35
			if glyph, ok := font.glyphs[' ']; ok {
				advance = glyph.advance
			}
			currentLineWidth += advance
			continue
		}

		glyph, ok := font.glyphs[char]
		if !ok do continue

		currentLineWidth += glyph.advance
	}

	maxLineWidth = max(maxLineWidth, currentLineWidth)
	totalTextSize.x = maxLineWidth
	totalTextSize.y = f32(lineCount) * f32(finalFontSize)

	minGlyphY: f32 = 0.0
	maxGlyphY: f32 = f32(finalFontSize)

	if glyphM, ok := font.glyphs['M']; ok {
		maxGlyphY = glyphM.yOffset + glyphM.height
	}
	if glyphP, ok := font.glyphs['p']; ok {
		minGlyphY = glyphP.yOffset
	}

	glyphHeight := maxGlyphY - minGlyphY
	centeringOffset := (f32(finalFontSize) - glyphHeight) * 0.5 - minGlyphY

	pivotOffset := totalTextSize * -gmath.scaleFromPivot(pivot)

	cursorX: f32
	cursorY := f32(lineCount - 1) * f32(finalFontSize)

	for char in text {
		if char == '\n' {
			cursorX = 0
			cursorY -= f32(finalFontSize)
			continue
		}

		if char == ' ' {
			advance: f32 = f32(finalFontSize) * 0.35
			if glyph, ok := font.glyphs[' ']; ok {
				advance = glyph.advance
			}
			cursorX += advance
			continue
		}

		glyph, ok := font.glyphs[char]
		if !ok do continue

		size := gmath.Vector2{glyph.width, glyph.height}
		bottomLeft := gmath.Vector2{glyph.xOffset, glyph.yOffset}

		offsetToRenderAt := gmath.Vector2{cursorX, cursorY + centeringOffset} + bottomLeft
		offsetToRenderAt += pivotOffset

		uv := gmath.Vector4{glyph.u0, glyph.v0, glyph.u1, glyph.v1}

		transform := gmath.Matrix4(1)
		transform *= gmath.matrixTranslate(position)
		if rotation != {} {
			transform *= gmath.matrixRotate(rotation)
		}
		transform *= gmath.matrixScale(scale * fontScale)
		transform *= gmath.matrixTranslate(offsetToRenderAt)

		drawRectangleTransform(
			transform,
			size,
			uv = uv,
			textureIndex = font.isPixel ? 1 : 2,
			colorOverride = colorOverride,
			color = color,
			drawLayer = drawLayer,
			sortKey = sortKey,
		)

		cursorX += glyph.advance
	}

	return gmath.abs(totalTextSize * scale * fontScale)
}

@(private = "file")
_drawTextSimpleF32Angle :: proc(
	position: gmath.Vector2,
	text: string,
	fontName: generated.FontName = .PixelCode,
	fontSize: uint = 12,
	rotation: f32 = 0.0, // in radians
	color := colors.WHITE,
	scale := gmath.Vector2{1, 1},
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := DrawLayer.nil,
	sortKey: f32 = 0.0,
	colorOverride := gmath.Color{},
) -> (
	textBounds: gmath.Vector2,
) {
	return _drawTextSimpleVector3Angle(
		position,
		text,
		fontName,
		fontSize,
		gmath.Vector3{0, 0, rotation},
		color,
		scale,
		pivot,
		drawLayer,
		sortKey,
		colorOverride,
	)
}
