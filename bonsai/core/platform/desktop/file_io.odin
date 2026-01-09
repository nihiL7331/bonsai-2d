#+build !wasm32, !wasm64p32
package desktop

// @overview
// This package compiles only on **desktop** builds.
//
// it is a symmetric representation of functions declared in the `bonsai:core/platform/web` package.
//
// If you wish to use these functions, it's recommended to import the `bonsai:core/platform` package.

import "core:log"
import "core:mem"
import "core:os"
import "core:strings"

// directory where persistent data will be stored
@(private = "file")
_SAVE_DIRECTORY :: "saves/"

// extension appended to all save files
@(private = "file")
_SAVE_EXTENSION :: ".bin"

// used to silence compiler when we compile for web
_ :: log
_ :: mem

// @ref
// Reads an entire file into memory.
//
// Wraps `core:os.read_entire_file` to provide a consistent **cross-platform API**.
// The caller owns the returned memory and **must** delete it.
read_entire_file :: proc(
	name: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	data: []byte,
	success: bool,
) {
	return os.read_entire_file(name, allocator, loc)
}

// @ref
// Writes a **byte slice** to a file, creating it if it doesn't exist.
//
// Wraps `core:os.write_entire_file`.
write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return os.write_entire_file(name, data, truncate)
}

//
// functions declared below are used to create data that is meant to be used for storage used longer than one session
//

// @ref
// Saves raw bytes to a persistent file **identified by a key**.
// Automatically handles creating the save directory if missing.
// Returns `false` if `data` is `nil` or [`write_entire_file`](#write_entire_file) fails.
//
// Example:
// ```Odin
// io.saveBytes("player_data", bytes) // writes to "saves/player_data.bin"
// ```
saveBytes :: proc(key: string, data: []byte) -> (success: bool) {
	if data == nil do return false
	if !os.exists(_SAVE_DIRECTORY) {
		log.infof("%v didn't exist. Making missing directory.", _SAVE_DIRECTORY)
		os.make_directory(_SAVE_DIRECTORY)
	}

	path := strings.concatenate({_SAVE_DIRECTORY, key, _SAVE_EXTENSION}, context.temp_allocator)
	success = os.write_entire_file(path, data)

	if !success {
		log.errorf("Failed to save bytes: %v", path)
		return false
	}

	return success
}

// @ref
// Loads raw bytes from a persistent file.
// Returns `nil, false` if [`read_entire_file`](#read_entire_file) fails.
loadBytes :: proc(key: string, allocator := context.allocator) -> (data: []byte, success: bool) {
	path := strings.concatenate({_SAVE_DIRECTORY, key, _SAVE_EXTENSION}, context.temp_allocator)

	data, success = os.read_entire_file(path, allocator)
	return data, success
}

// @ref
// Serializes and saves a struct **to disk**.
// This is a **high-level** helper for easy save states.
//
// **Warning:** This does a direct memory dump of the struct. It is not version-safe
// if the struct layout changes (reordering fields, adding pointers, etc.).
saveStruct :: proc(key: string, data: ^$T) -> (success: bool) {
	if data == nil do return false

	if !os.exists(SAVE_DIRECTORY) {
		os.make_directory(SAVE_DIRECTORY)
	}

	path := strings.concatenate({SAVE_DIRECTORY, key, SAVE_EXTENSION}, context.temp_allocator)

	// creates a byte slice view over the structs memory
	bytes := mem.slice_ptr(cast(^byte)data, size_of(T))

	success = os.write_entire_file(path, bytes)

	if !success {
		log.errorf("Failed to save struct to path: %v", path)
	}

	return success
}

// @ref
// Loads a struct **from disk**.
//
// Includes safety checks for size mismatches:
// - **Debug Mode**: Allows partial loads (padding with zeros) and warns the user.
// - **Release Mode**: Fails strictly if sizes don't match to prevent corruption.
loadStruct :: proc(key: string, data: ^$T) -> (success: bool) {
	if data == nil do return false
	path := strings.concatenate({SAVE_DIRECTORY, key, SAVE_EXTENSION}, context.temp_allocator)

	if !os.exists(path) {
		return false
	}

	bytes, ok := os.read_entire_file(path, context.allocator)
	if !ok {
		log.errorf("Failed to read file: %v", path)
		return false
	}
	defer delete(bytes)

	if len(bytes) != size_of(T) {
		when ODIN_DEBUG {
			// during development its common to edit structs, hence changing their size.
			log.warnf("Save file size mismatch: %v. Partial load.", path)

			copySize := min(len(bytes), size_of(T))
			mem.copy(data, raw_data(bytes), copySize)
			return true
		} else {
			// if it's a release version of the code, it's generally unexpected behavior.
			log.errorf("Save file size mismatch: %v. Wrong save version?", path)
			return false
		}
	}

	// exact match
	mem.copy(data, raw_data(bytes), size_of(T))
	return true
}
