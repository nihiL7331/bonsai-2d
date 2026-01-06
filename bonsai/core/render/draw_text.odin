package render

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import stb_truetype "bonsai:libs/stb/truetype"
import "bonsai:types/game"

import "core:log"

// texture index for font atlas
@(private = "file")
FONT_TEXTURE_INDEX: u8 : 1

// @ref
// Default text drawing alias **(includes drop shadow)**.
drawText :: drawTextWithDropShadow

drawTextWrapped :: proc(
	position: gmath.Vector2,
	text: string,
	font: ^Font,
	wrapWidth: f32,
	rotation: f32 = 0.0,
	color := colors.WHITE,
	scale := 1.0,
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := game.DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	//TODO: wrapping text
	return drawTextSimple(
		position,
		rotation,
		text,
		font,
		color,
		scale,
		pivot,
		drawLayer,
		colorOverride,
	)
}

// @ref
// Draws text with a **hard-coded** drop shadow for contrast**.
// Retrieves the font using the **automatically** generated font enum name.
drawTextWithDropShadow :: proc(
	position: gmath.Vector2,
	text: string,
	fontName: game.FontName,
	fontSize: uint = 12,
	rotation: f32 = 0.0,
	dropShadowColor := colors.BLACK,
	color := colors.WHITE,
	scale := 1.0,
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := game.DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> gmath.Vector2 {
	shadowOffset := gmath.Vector2{1, -1} * f32(scale)

	// fetch font resource
	font, ok := getFont(fontName, fontSize)
	if !ok {
		log.errorf("Failed to draw font: %v (text: %v)", fontName, text)
		return gmath.Vector2{0, 0}
	}

	// draw shadow
	drawTextSimple(
		position + shadowOffset,
		rotation,
		text,
		font = &font,
		color = dropShadowColor * color, // tint the shadow by the main color
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)

	// draw main text
	textDimensions := drawTextSimple(
		position,
		rotation,
		text,
		font = &font,
		color = color,
		scale = scale,
		pivot = pivot,
		drawLayer = drawLayer,
		colorOverride = colorOverride,
	)

	return textDimensions
}

// @ref
// Internal primitive for drawing a single line of text.
// Calculates layout, pivots, and batches the quads.
drawTextSimple :: proc(
	position: gmath.Vector2,
	rotation: f32,
	text: string,
	font: ^Font,
	color := colors.WHITE,
	scale := 1.0,
	pivot := gmath.Pivot.bottomLeft,
	drawLayer := game.DrawLayer.nil,
	colorOverride := gmath.Color{},
) -> (
	textBounds: gmath.Vector2,
) {
	if drawLayer != game.DrawLayer.nil {
		getDrawFrame().reset.activeDrawLayer = drawLayer
	}

	// find size
	totalTextSize: gmath.Vector2
	for char, i in text {
		advanceX: f32
		advanceY: f32
		quad: stb_truetype.aligned_quad

		stb_truetype.GetBakedQuad(
			&font.characterData[0],
			_BITMAP_WIDTH,
			_BITMAP_HEIGHT,
			i32(char) - 32,
			&advanceX,
			&advanceY,
			&quad,
			false,
		)
		// calculate char dimensions
		// x0, y0 - top-left, x1, y1 - bottom-right in STB

		charSize := gmath.Vector2{abs(quad.x0 - quad.x1), abs(quad.y0 - quad.y1)}

		bottomLeft := gmath.Vector2{quad.x0, -quad.y1}
		topRight := gmath.Vector2{quad.x1, -quad.y0}

		assert(bottomLeft + charSize == topRight, "Font sizing error (find size)")

		if i == len(text) - 1 {
			totalTextSize.x += charSize.x
		} else {
			totalTextSize.x += advanceX
		}

		totalTextSize.y = max(totalTextSize.y, topRight.y)
	}

	pivotOffset := totalTextSize * -gmath.scaleFromPivot(pivot)

	rotationMatrix := gmath.Matrix4(1)
	if rotation != 0 {
		rotationMatrix = gmath.matrixRotate(rotation)
	}

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
			_BITMAP_WIDTH,
			_BITMAP_HEIGHT,
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
		transform *= rotationMatrix
		transform *= gmath.matrixScale(gmath.Vector2{f32(scale), f32(scale)})
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

	return totalTextSize * f32(scale)
}
