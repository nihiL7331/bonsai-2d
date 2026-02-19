package desktop

import "base:runtime"
import "core:log"
import "core:mem"
import "core:os"

import "bonsai:core/clock"
import stb_image "bonsai:libs/stb/image"

PendingData :: struct {
	imageData:   [^]byte,
	imageWidth:  i32,
	imageHeight: i32,
	jsonData:    []u8,
	pending:     bool,
}

BINARY_PATH :: ".bonsai/cache/sprites/sprites.bin"
ATLAS_PATH :: "bonsai/core/render/atlas/atlas.png"

@(private = "file")
_lastModificationTime: os.File_Time

@(private = "file")
_hotReloadBuffer: [16 * runtime.Megabyte]u8

@(private = "file")
_hotReloadArena: mem.Arena

@(private = "file")
_changeDetectedTime: f64

@(private = "file")
_isDebouncing: bool

pollHotReload :: proc() -> PendingData {
	modificationTime, error := os.last_write_time_by_name(ATLAS_PATH)

	if error == os.ERROR_NONE && modificationTime != _lastModificationTime {
		_changeDetectedTime = clock.getApplicationTime()
		_isDebouncing = true
		_lastModificationTime = modificationTime
	}

	if _isDebouncing {
		if !clock.hasTimestampPassed(_changeDetectedTime + 0.1) {
			return {nil, 0, 0, nil, false}
		}

		_isDebouncing = false
	} else {
		return {nil, 0, 0, nil, false}
	}

	if _hotReloadArena.data == nil {
		mem.arena_init(&_hotReloadArena, _hotReloadBuffer[:])
	}

	mem.arena_free_all(&_hotReloadArena)

	context.allocator = mem.arena_allocator(&_hotReloadArena)

	binData, jsonSuccess := read_entire_file(BINARY_PATH)
	if !jsonSuccess {
		log.errorf("Failed to load sprite metadata at: %v.", BINARY_PATH)
		return {nil, 0, 0, nil, false}
	}

	pngData, imageSuccess := read_entire_file(ATLAS_PATH, context.temp_allocator)
	if !imageSuccess {
		log.warnf("Failed to read atlas file at: %v.", ATLAS_PATH)
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


	return {imageData, width, height, binData, true}
}
