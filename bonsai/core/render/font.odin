package render

import "core:fmt"
import "core:log"
import "core:reflect"

import "bonsai:core/gmath"
import "bonsai:core/platform"
import "bonsai:generated"
import sokol_gfx "bonsai:libs/sokol/gfx"
import stb_image "bonsai:libs/stb/image"

FONT_BINARY_PATH :: ".bonsai/cache/fonts"
FONT_PNG_PATH :: ".bonsai/cache/fonts"

loadFonts :: proc() {
	for fontName in generated.FontName {
		if fontName == .nil do continue

		nameString, ok := reflect.enum_name_from_value(fontName)
		if !ok do continue

		binPath := fmt.tprintf("%s/%s.bin", FONT_BINARY_PATH, nameString)
		pngPath := fmt.tprintf("%s/%s.png", FONT_PNG_PATH, nameString)

		binData, binSuccess := platform.read_entire_file(binPath)
		if !binSuccess {
			log.errorf("Failed to load font metadata at: %s", binPath)
			continue
		}

		pngData, pngSuccess := platform.read_entire_file(pngPath)
		if !pngSuccess {
			log.errorf("Failed to load font atlas at: %s", pngData)
			continue
		}
		defer delete(pngData, context.temp_allocator)

		width, height, channels: i32
		imageData := stb_image.load_from_memory(
			raw_data(pngData),
			i32(len(pngData)),
			&width,
			&height,
			&channels,
			4,
		)
		if imageData == nil {
			log.errorf("STB failed to decode image data for: %s", nameString)
			continue
		}

		pending := platform.PendingData {
			imageData   = imageData,
			imageWidth  = width,
			imageHeight = height,
			binData     = binData,
			isPending   = true,
		}

		updateFontData(pending, fontName)
	}
}

// @ref
// Calculates the total dimension **(width, height)** of a string if it were rendered.
// :::tip
// Useful for centering text.
// :::
getTextSize :: proc(fontName: generated.FontName, fontSize: uint, text: string) -> gmath.Vector2 {
	font := &fontData[fontName]
	if !font.isLoaded do return gmath.Vector2{0, 0}

	fontScale: f32
	finalFontSize: f32
	if font.isPixel {
		nativeSize := f32(font.nativeSize)
		if nativeSize == 0 do nativeSize = 1
		fontScale = f32(fontSize) / nativeSize
		finalFontSize = nativeSize
	} else {
		fontScale = f32(fontSize) / 64.0
		finalFontSize = f32(fontSize)
	}

	currentLineWidth: f32 = 0.0
	maxLineWidth: f32 = 0.0
	lineCount: int = 1

	for char in text {
		if char == '\n' {
			maxLineWidth = max(currentLineWidth, maxLineWidth)
			currentLineWidth = 0.0
			lineCount += 1
			continue
		}

		glyph, ok := font.glyphs[char]
		if !ok do continue

		currentLineWidth += glyph.advance
	}

	if currentLineWidth > maxLineWidth {
		maxLineWidth = currentLineWidth
	}

	totalHeight := f32(lineCount) * f32(finalFontSize)

	return gmath.Vector2{maxLineWidth, totalHeight} * fontScale
}

// Cleans up all GPU resources associated with loaded fonts.
//
// Is called on application shutdown from main.odin.
destroyFonts :: proc() {
	for fontName in generated.FontName {
		if fontName == .nil do continue

		font := &fontData[fontName]
		if font.isLoaded {
			sokol_gfx.destroy_image(font.image)
			sokol_gfx.destroy_view(font.view)
			delete(font.glyphs)
			font.isLoaded = false
		}
	}
}
