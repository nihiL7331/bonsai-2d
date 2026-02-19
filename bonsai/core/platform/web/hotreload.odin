#+build wasm32, wasm64p32
package web

import stb_image "bonsai:libs/stb/image"

import "base:runtime"
import "core:fmt"
import "core:mem"

when !ODIN_DEBUG {
	_ :: stb_image
	_ :: fmt
}

PendingData :: struct {
	imageData:   [^]byte,
	imageWidth:  i32,
	imageHeight: i32,
	jsonData:    []u8,
	pending:     bool,
}

@(private = "file")
_pendingData: PendingData

@(private = "file")
_hotReloadBuffer: [8 * runtime.Megabyte]u8

@(private = "file")
_hotReloadArena: mem.Arena

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
hotReloadPushData :: proc "contextless" (
	jsonPointer: ^u8,
	jsonLength: int,
	pngPointer: ^u8,
	pngLength: int,
) {
	when ODIN_DEBUG {
		context = runtime.default_context()
		context.allocator = mem.arena_allocator(&_hotReloadArena)

		jsonData := mem.slice_ptr(jsonPointer, jsonLength)
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
		_pendingData.jsonData = jsonData
		_pendingData.imageWidth = width
		_pendingData.imageHeight = height
		_pendingData.pending = true
	}
}

pollHotReload :: proc() -> PendingData {
	if !_pendingData.pending do return {nil, 0, 0, nil, false}

	toReturn := _pendingData
	_pendingData.pending = false

	return toReturn
}
