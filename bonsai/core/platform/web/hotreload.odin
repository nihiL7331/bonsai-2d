#+build wasm32, wasm64p32
package web

import "bonsai:generated"
import stb_image "bonsai:libs/stb/image"

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:reflect"

when !ODIN_DEBUG {
	_ :: stb_image
	_ :: fmt
	_ :: reflect
}

PendingData :: struct {
	imageData:   [^]byte,
	imageWidth:  i32,
	imageHeight: i32,
	binData:     []u8,
	isPending:   bool,
}

@(private = "file")
_pendingFonts: [generated.FontName]PendingData

@(private = "file")
_pendingData: PendingData

@(private = "file")
_hotReloadBuffer: [8 * runtime.Megabyte]u8

@(private = "file")
_hotReloadArena: mem.Arena

// JS functions

@(export)
hotReloadReset :: proc "contextless" () {
	when ODIN_DEBUG {
		context = runtime.default_context()

		if _hotReloadArena.data != nil {
			mem.arena_free_all(&_hotReloadArena)
		}
	}
}

@(export)
hotReloadAlloc :: proc "contextless" (size: int) -> rawptr {
	when ODIN_DEBUG {
		context = runtime.default_context()

		if _hotReloadArena.data == nil {
			mem.arena_init(&_hotReloadArena, _hotReloadBuffer[:])
		}

		if _hotReloadArena.offset + size > len(_hotReloadBuffer) {
			mem.arena_free_all(&_hotReloadArena)
		}

		context.allocator = mem.arena_allocator(&_hotReloadArena)
		slice, error := mem.alloc_bytes(size, 16)

		if error != .None {
			return nil
		}

		return raw_data(slice)
	} else {
		return nil
	}
}

@(export)
hotReloadPushSpriteData :: proc "contextless" (
	binPointer: ^u8,
	binLength: int,
	pngPointer: ^u8,
	pngLength: int,
) {
	when ODIN_DEBUG {
		context = runtime.default_context()
		context.allocator = mem.arena_allocator(&_hotReloadArena)

		binData := mem.slice_ptr(binPointer, binLength)
		pngData := mem.slice_ptr(pngPointer, pngLength)

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
			fmt.eprintln("STB failed to decode image data.")
			return
		}

		_pendingData.imageData = imageData
		_pendingData.imageWidth = width
		_pendingData.imageHeight = height
		_pendingData.binData = binData
		_pendingData.isPending = true
	}
}

@(export)
hotReloadPushFontData :: proc "contextless" (
	namePointer: [^]byte,
	nameLength: int,
	binPointer: ^u8,
	binLength: int,
	pngPointer: ^u8,
	pngLength: int,
) {
	when ODIN_DEBUG {
		context = runtime.default_context()
		context.allocator = mem.arena_allocator(&_hotReloadArena)

		fontNameString := string(namePointer[:nameLength])
		fontEnum, enumOk := reflect.enum_from_name(generated.FontName, fontNameString)
		if !enumOk {
			fmt.eprintln("Unknown font name received.")
			return
		}

		binData := mem.slice_ptr(binPointer, binLength)
		pngData := mem.slice_ptr(pngPointer, pngLength)

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
			fmt.eprintln("STB failed to decode font image data for:", fontNameString)
			return
		}

		_pendingFonts[fontEnum] = PendingData {
			imageData   = imageData,
			imageWidth  = width,
			imageHeight = height,
			binData     = binData,
			isPending   = true,
		}
	}
}

pollHotReloadSprites :: proc() -> PendingData {
	if !_pendingData.isPending || ODIN_DEBUG do return {nil, 0, 0, nil, false}

	toReturn := _pendingData
	_pendingData.isPending = false

	return toReturn
}

pollHotReloadFonts :: proc() -> [generated.FontName]PendingData {
	when ODIN_DEBUG do return {}

	toReturn := _pendingFonts

	for fontName in generated.FontName {
		_pendingFonts[fontName].isPending = false
	}

	return toReturn
}
