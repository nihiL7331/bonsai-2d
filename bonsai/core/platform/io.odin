package platform

//
// this file acts as a router to appropriate implementation based off the build target.
//

// determine if we are compiling for the web
IS_WEB :: ODIN_ARCH == .wasm64p32 || ODIN_ARCH == .wasm32

import "desktop"
import "web"

// ghost use of packages, to avoid compiler errors
_ :: desktop
_ :: web

// @ref
// Reads an entire file into memory.
//
// Platform-agnostic wrapper.
// - **Web**: Reads from the **Emscripten Virtual File System**.
// - **Desktop**: Reads directly **from the disk**.
//
// **Note:** Naming follows **core:os** convention rather than camelCase to indicate **standard library behavior**.
@(require_results)
read_entire_file :: proc(
	name: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	data: []byte,
	success: bool,
) {
	when IS_WEB {
		return web.read_entire_file(name, allocator, loc)
	} else {
		return desktop.read_entire_file(name, allocator, loc)
	}
}

// @ref
// Writes a byte slice to a file.
//
// Platform-agnostic wrapper.
// - **Web**: Writes to the **Emscripten Virtual File System** (non-persistent between sessions).
// - **Desktop**: Writes directly **to the disk**.
write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	when IS_WEB {
		return web.write_entire_file(name, data, truncate)
	} else {
		return desktop.write_entire_file(name, data, truncate)
	}
}

// @ref
// Loads a **struct** from persistent storage.
// Returns **false** if the key doesn't exist or data is corrupted.
@(require_results)
loadStruct :: proc(key: string, value: ^$T) -> (success: bool) {
	when IS_WEB {
		return web.loadStruct(key, value)
	} else {
		return desktop.loadStruct(key, value)
	}
}

// @ref
// Serializes and saves a **struct** to persistent storage.
// - **Desktop**: Saves to **"saves/"** directory as a binary file. **(default)**
// - **Web**: Saves to **LocalStorage** (Base64 encoded string).
saveStruct :: proc(key: string, value: ^$T) -> (success: bool) {
	when IS_WEB {
		return web.saveStruct(key, value)
	} else {
		return desktop.saveStruct(key, value)
	}
}

// @ref
// Loads raw bytes **from persistent storage**.
@(require_results)
loadBytes :: proc(key: string, allocator := context.allocator) -> (data: []byte, success: bool) {
	when IS_WEB {
		return web.loadBytes(key, allocator)
	} else {
		return desktop.loadBytes(key, allocator)
	}
}

// @ref
// Saves raw bytes **to persistent storage**.
saveBytes :: proc(key: string, data: []byte) -> (success: bool) {
	when IS_WEB {
		return web.saveBytes(key, data)
	} else {
		return desktop.saveBytes(key, data)
	}
}
