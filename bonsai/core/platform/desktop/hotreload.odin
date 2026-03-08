package desktop

import "base:runtime"
import "bonsai:generated"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:reflect"

import "bonsai:core/clock"
import stb_image "bonsai:libs/stb/image"

when !ODIN_DEBUG {
	_ :: stb_image
	_ :: fmt
	_ :: reflect
	_ :: log
	_ :: clock
}

PendingData :: struct {
	imageData:   [^]byte,
	imageWidth:  i32,
	imageHeight: i32,
	binData:     []u8,
	isPending:   bool,
}

// @ref
// Path where the binary data of sprites
// (atlas UVs, animation count etc.) is stored.
//
// Used internally for hot reloading.
SPRITE_BINARY_PATH :: ".bonsai/cache/sprites/sprites.bin"

// @ref
// Path where the atlas image for sprites is stored.
//
// Used internally for hot reloading.
SPRITE_ATLAS_PATH :: "bonsai/core/render/atlas/atlas.png"

// @ref
// Path where the generated font data (atlases and binary) are stored.
//
// Used internally for hot reloading.
FONT_DATA_PATH :: ".bonsai/cache/fonts"

// fonts

@(private = "file")
_lastFontModificationTimes: [generated.FontName]os.File_Time

@(private = "file")
_fontChangeDetectedTimes: [generated.FontName]f64

@(private = "file")
_isDebouncingFonts: [generated.FontName]bool

// sprites

@(private = "file")
_lastSpriteModificationTime: os.File_Time

@(private = "file")
_spriteChangeDetectedTime: f64

@(private = "file")
_isDebouncingSprite: bool

// memory/arena

@(private = "file")
_hotReloadBuffer: [16 * runtime.Megabyte]u8

@(private = "file")
_hotReloadArena: mem.Arena

pollHotReloadSprites :: proc() -> PendingData {
	when ODIN_DEBUG {
		modificationTime, error := os.last_write_time_by_name(SPRITE_ATLAS_PATH)

		if error == os.ERROR_NONE && modificationTime != _lastSpriteModificationTime {
			_spriteChangeDetectedTime = clock.getApplicationTime()
			_isDebouncingSprite = true
			_lastSpriteModificationTime = modificationTime
		}

		if _isDebouncingSprite {
			if !clock.hasTimestampPassed(_spriteChangeDetectedTime + 0.1) {
				return {nil, 0, 0, nil, false}
			}

			_isDebouncingSprite = false
		} else {
			return {nil, 0, 0, nil, false}
		}

		if _hotReloadArena.data == nil {
			mem.arena_init(&_hotReloadArena, _hotReloadBuffer[:])
		}

		mem.arena_free_all(&_hotReloadArena)

		context.allocator = mem.arena_allocator(&_hotReloadArena)

		binData, jsonSuccess := read_entire_file(SPRITE_BINARY_PATH)
		if !jsonSuccess {
			log.errorf("Failed to load sprite metadata at: %v.", SPRITE_BINARY_PATH)
			return {nil, 0, 0, nil, false}
		}

		pngData, imageSuccess := read_entire_file(SPRITE_ATLAS_PATH, context.temp_allocator)
		if !imageSuccess {
			log.warnf("Failed to read atlas file at: %v.", SPRITE_ATLAS_PATH)
			return {nil, 0, 0, nil, false}
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
			log.error("STB failed to decode image data.")
			return {nil, 0, 0, nil, false}
		}


		return PendingData {
			imageData = imageData,
			imageWidth = width,
			imageHeight = height,
			binData = binData,
			isPending = true,
		}
	} else {
		return PendingData{}
	}
}

pollHotReloadFonts :: proc() -> [generated.FontName]PendingData {
	result: [generated.FontName]PendingData
	when ODIN_DEBUG {

		names := reflect.enum_field_names(generated.FontName)
		for nameString, i in names {
			fontEnum := generated.FontName(i)

			if fontEnum == .nil do continue

			pngPath := fmt.tprintf("%s/%s.png", FONT_DATA_PATH, nameString)
			binPath := fmt.tprintf("%s/%s.bin", FONT_DATA_PATH, nameString)

			modificationTime, error := os.last_write_time_by_name(pngPath)
			if error == os.ERROR_NONE && modificationTime != _lastFontModificationTimes[fontEnum] {
				_fontChangeDetectedTimes[fontEnum] = clock.getApplicationTime()
				_isDebouncingFonts[fontEnum] = true
				_lastFontModificationTimes[fontEnum] = modificationTime
			}

			if _isDebouncingFonts[fontEnum] {
				if !clock.hasTimestampPassed(_fontChangeDetectedTimes[fontEnum] + 0.1) {
					continue
				}
				_isDebouncingFonts[fontEnum] = false
			} else {
				continue
			}

			if _hotReloadArena.offset > len(_hotReloadBuffer) - runtime.Megabyte {
				mem.arena_free_all(&_hotReloadArena)
			}

			context.allocator = mem.arena_allocator(&_hotReloadArena)

			binData, binSuccess := read_entire_file(binPath)
			if !binSuccess {
				log.errorf("Failed to load font metadata at: %s", binPath)
				continue
			}

			pngData, imgSuccess := read_entire_file(pngPath, context.temp_allocator)
			if !imgSuccess {
				log.errorf("Failed to read font atlas at: %s", pngPath)
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
				log.errorf("STB failed to decode font image data for: %s", nameString)
				continue
			}

			result[fontEnum] = PendingData {
				imageData   = imageData,
				imageWidth  = width,
				imageHeight = height,
				binData     = binData,
				isPending   = true,
			}

			log.infof("Desktop hot-reloaded font: %s", nameString)
		}
	}
	return result
}
