package render

import "core:log"
import "core:mem"

import "bonsai:core/gmath"
import "bonsai:core/platform"
import "bonsai:generated"
import sokol_gfx "bonsai:libs/sokol/gfx"
import stb_image "bonsai:libs/stb/image"
import "bonsai:shaders"

// @ref
// Changes the active **main texture view**.
setTexture :: proc(view: sokol_gfx.View) {
	currentId := _renderContext.bindings.views[shaders.VIEW_uTex].id

	if currentId != view.id {
		flushBatch()
		_renderContext.bindings.views[shaders.VIEW_uTex] = view
	}
}

// @ref
// Changes the active **font texture view**.
setFontTexture :: proc(font: ^Font) {
	currentId := _renderContext.bindings.views[shaders.VIEW_uFontTex].id

	if currentId != font.view.id {
		flushBatch()
		_renderContext.bindings.views[shaders.VIEW_uFontTex] = font.view
	}
}

// @ref
// Loads/reloads the sprite data from a binary file
// with the structure matching the [`RawSpriteData`](#rawspritedata)
// struct.
loadSpriteMetadata :: proc(filepath: string = BINARY_PATH) {
	binData, success := platform.read_entire_file(filepath)
	if !success {
		log.errorf("Failed to load sprite metadata at: %v.", filepath)
		return
	}
	defer delete(binData)

	rawSprites := mem.slice_data_cast([]RawSpriteData, binData)

	if len(rawSprites) != len(generated.SpriteName) {
		log.warnf(
			"Binary sprite data length (%d) does not match Enum size (%d).",
			len(rawSprites),
			len(generated.SpriteName),
		)
	}

	maxItems := min(len(rawSprites), len(generated.SpriteName))

	for index in 0 ..< maxItems {
		rawSprite := rawSprites[index]
		spriteEnum := generated.SpriteName(index)

		spriteData[spriteEnum] = generated.SpriteData {
			uv     = {rawSprite.u0, rawSprite.v0, rawSprite.u1, rawSprite.v1},
			size   = {rawSprite.sizeX, rawSprite.sizeY},
			frames = int(rawSprite.frames),
		}
	}
}

loadAtlas :: proc(filepath: string = ATLAS_PATH) {
	atlas := &_renderContext.atlas

	if atlas.view.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_view(atlas.view)
	}

	if atlas.image.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_image(atlas.image)
	}

	pngData, success := platform.read_entire_file(filepath)
	if !success {
		if filepath != BLANK_ATLAS_PATH {
			log.warnf("Failed to read atlas file at: %v. Defaulting to blank atlas.", filepath)
			loadAtlas(BLANK_ATLAS_PATH)
		} else {
			log.error("Blank fallback is also missing.")
		}
		return
	}
	defer delete(pngData)

	width, height, channels: i32
	imageData := getImageData(raw_data(pngData), i32(len(pngData)), &width, &height, &channels)
	if imageData == nil do return // error already handled in getImageData
	defer stb_image.image_free(imageData)

	description: sokol_gfx.Image_Desc
	description.width = width
	description.height = height
	description.pixel_format = .RGBA8
	description.data.subimage[0][0] = {
		ptr  = imageData,
		size = uint(width * height * 4),
	}

	sgImage := sokol_gfx.make_image(description)
	if sgImage.id == sokol_gfx.INVALID_ID {
		log.error("Failed to make an image.")
		return
	}

	atlas.image = sgImage
	atlas.view = sokol_gfx.make_view({texture = sokol_gfx.Texture_View_Desc({image = sgImage})})
	_renderContext.bindings.views[0] = atlas.view
}

updateAtlas :: proc(data: [^]byte, width: i32, height: i32) {
	atlas := &_renderContext.atlas

	if atlas.image.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_image(atlas.image)
	}
	if atlas.view.id != sokol_gfx.INVALID_ID {
		sokol_gfx.destroy_view(atlas.view)
	}

	description: sokol_gfx.Image_Desc
	description.width = width
	description.height = height
	description.pixel_format = .RGBA8
	description.data.subimage[0][0] = {
		ptr  = data,
		size = uint(width * height * 4),
	}

	sgImage := sokol_gfx.make_image(description)
	if sgImage.id == sokol_gfx.INVALID_ID {
		log.error("Failed to make an image.")
		return
	}

	atlas.image = sgImage
	atlas.view = sokol_gfx.make_view({texture = sokol_gfx.Texture_View_Desc({image = sgImage})})
	_renderContext.bindings.views[0] = atlas.view
}

updateSpriteData :: proc(data: []u8) {
	rawSprites := mem.slice_data_cast([]RawSpriteData, data)

	if len(rawSprites) != len(generated.SpriteName) {
		log.warnf(
			"Binary sprite data length (%d) does not match Enum size (%d).",
			len(rawSprites),
			len(generated.SpriteName),
		)
	}

	maxItems := min(len(rawSprites), len(generated.SpriteName))

	for index in 0 ..< maxItems {
		rawSprite := rawSprites[index]
		spriteEnum := generated.SpriteName(index)

		spriteData[spriteEnum] = generated.SpriteData {
			uv     = {rawSprite.u0, rawSprite.v0, rawSprite.u1, rawSprite.v1},
			size   = {rawSprite.sizeX, rawSprite.sizeY},
			frames = int(rawSprite.frames),
		}
	}
}

updateFontData :: proc(data: platform.PendingData, fontEnum: generated.FontName) {
	isPixel := data.binData[0] == 1
	nativeSize := data.binData[1]

	glyphBytes := data.binData[2:]
	glyphArray := mem.slice_data_cast([]GlyphData, glyphBytes)

	if fontData[fontEnum].glyphs == nil {
		fontData[fontEnum].glyphs = make(map[rune]GlyphData)
	} else {
		clear(&fontData[fontEnum].glyphs)
	}

	for glyph in glyphArray {
		fontData[fontEnum].glyphs[rune(glyph.id)] = glyph
	}

	if fontData[fontEnum].isLoaded {
		sokol_gfx.destroy_image(fontData[fontEnum].image)
		sokol_gfx.destroy_view(fontData[fontEnum].view)
	}

	description: sokol_gfx.Image_Desc
	description.width = data.imageWidth
	description.height = data.imageHeight
	description.pixel_format = .RGBA8
	description.data.subimage[0][0] = {
		ptr  = data.imageData,
		size = uint(data.imageWidth * data.imageHeight * 4),
	}

	sgImage := sokol_gfx.make_image(description)
	if sgImage.id == sokol_gfx.INVALID_ID {
		log.error("Failed to make an image.")
		return
	}

	fontData[fontEnum].image = sgImage
	if isPixel {
		fontData[fontEnum].sampler = _renderContext.nearestSampler
	} else {
		fontData[fontEnum].sampler = _renderContext.linearSampler
	}
	fontData[fontEnum].view = sokol_gfx.make_view(
		{texture = sokol_gfx.Texture_View_Desc({image = sgImage})},
	)
	fontData[fontEnum].isPixel = isPixel
	fontData[fontEnum].nativeSize = nativeSize
	fontData[fontEnum].isLoaded = true

	stb_image.image_free(data.imageData)
}

getImageData :: proc(
	buffer: [^]byte,
	bufferLength: i32,
	width, height, channels: ^i32,
) -> [^]byte {
	imageData := stb_image.load_from_memory(buffer, bufferLength, width, height, channels, 4)
	if imageData == nil {
		log.error("STB failed to decode image data.")
		return nil
	}
	return imageData
}

// @ref
// Helper to retrieve **texture info** from `SpriteName`.
getAtlasUv :: proc(sprite: generated.SpriteName) -> gmath.Vector4 {
	return spriteData[sprite].uv
}

// @ref
// Helper to retrieve **size** from [`SpriteName`](https://bonsai-framework.dev/reference/generated/#spritename).
getSpriteSize :: proc(sprite: generated.SpriteName) -> gmath.Vector2 {
	return spriteData[sprite].size
}

// @ref
// Helper to retrieve **frame count** from [`SpriteName`](https://bonsai-framework.dev/reference/generated/#spritename).
getFrameCount :: proc(sprite: generated.SpriteName) -> int {
	return spriteData[sprite].frames
}
