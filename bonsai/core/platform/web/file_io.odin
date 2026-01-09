#+build wasm32, wasm64p32
package web

// @overview
// This package compiles only on **web** builds.
//
// it uses **Emscripten Virtual File System** for [`read_entire_file`](#read_entire_file) and [`write_entire_file`](#write_entire_file).
//
// It uses the browsers **LocalStorage** for [`loadBytes`](#loadbytes), [`loadStruct`](#loadstruct), [`saveBytes`](#savebytes) and [`saveStruct`](#savestruct).
//
// It's a symmetric representation of functions decalred in the `bonsai:core/platform/desktop` package, but it additionally
// contains an Emscripten allocator implementation.
//
// If you wish to use these functions, it's recommended to import the `bonsai:core/platform` package.

import "base:runtime"
import "core:c"
import "core:encoding/base64"
import "core:log"
import "core:mem"
import "core:strings"

_ :: mem

// c/emscripten file system bindings
@(default_calling_convention = "c")
foreign _ {
	fopen :: proc(filename, mode: cstring) -> ^FILE ---
	fseek :: proc(stream: ^FILE, offset: c.long, whence: Whence) -> c.int ---
	ftell :: proc(stream: ^FILE) -> c.long ---
	fclose :: proc(stream: ^FILE) -> c.int ---
	fread :: proc(ptr: rawptr, size: c.size_t, nmemb: c.size_t, stream: ^FILE) -> c.size_t ---
	fwrite :: proc(ptr: rawptr, size: c.size_t, nmemb: c.size_t, stream: ^FILE) -> c.size_t ---
}

FILE :: struct {}

Whence :: enum c.int {
	SET,
	CUR,
	END,
}

// @ref
// Reads a file from **Emscripten's Virtual File System (MEMFS)**.
// **Note:** This does not read from the user's hard drive, but from the sandboxed browser memory.
read_entire_file :: proc(
	name: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	data: []byte,
	success: bool,
) {
	if name == "" {
		log.warn("No file name provided.")
		return nil, false
	}

	mode: cstring = "rb"
	file := fopen(strings.clone_to_cstring(name, context.temp_allocator), mode)

	if file == nil {
		log.warnf("Failed to open file %v.", name)
		return nil, false
	}
	defer fclose(file)

	// calculate the size
	fseek(file, 0, .END)
	size := ftell(file)
	fseek(file, 0, .SET)

	if size <= 0 {
		log.warnf("Failed to read file %v (empty or invalid)", name)
		return nil, false
	}

	data_err: runtime.Allocator_Error
	data, data_err = make([]byte, size, allocator, loc)

	if data_err != nil {
		log.warnf("Failed to allocate memory for file %v: %v.", name, data_err)
		return nil, false
	}

	read_size := fread(raw_data(data), 1, c.size_t(size), file)

	if read_size != c.size_t(size) {
		log.warnf("Incomplete read for file %v. Expected %d, got %d.", name, size, read_size)
		return nil, false
	}

	return data, true
}

// @ref
// Writes to **Emscripten's Virtual File System**.
write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	if name == "" {
		log.error("No file name provided.")
		return
	}

	mode: cstring
	if truncate {
		mode = "wb"
	} else {
		mode = "ab"
	}
	file := fopen(strings.clone_to_cstring(name, context.temp_allocator), mode)
	if file == nil {
		log.errorf("Failed to open file for writing: %v", name)
		return false
	}
	defer fclose(file)

	bytes_written := fwrite(raw_data(data), 1, c.size_t(len(data)), file)

	if bytes_written == 0 {
		log.errorf("Failed to write file %v.", name)
		return
	} else if bytes_written != len(data) {
		log.errorf(
			"File %v partially written, wrote %v out of %v bytes.",
			name,
			bytes_written,
			len(data),
		)
		return
	}

	return true
}

foreign import "js"
foreign js {
	js_save :: proc "contextless" (key_ptr: rawptr, key_len: int, data_ptr: rawptr, data_len: int) ---
	js_load_size :: proc "contextless" (key_ptr: rawptr, key_len: int) -> int ---
	js_load :: proc "contextless" (key_ptr: rawptr, key_len: int, dest_ptr: rawptr, dest_len: int) ---
}

// @ref
// Saves raw bytes to the browser's **LocalStorage**.
// Data is **Base64 encoded** to ensure safe storage as a string.
saveBytes :: proc(key: string, data: []byte) -> (success: bool) {
	if data == nil {
		log.errorf("Attempted to save nil data for key: %v.", key)
		return false
	}

	encoded := base64.encode(data, allocator = context.temp_allocator)

	js_save(raw_data(key), len(key), raw_data(encoded), len(encoded))
	return true
}

// @ref
// Loads raw bytes from the browser's **LocalStorage**.
loadBytes :: proc(key: string, allocator := context.allocator) -> (data: []byte, success: bool) {
	size := js_load_size(raw_data(key), len(key))
	if size == 0 {
		log.errorf("Data under key %v is empty.", key)
		return nil, false
	}

	base64Buffer := make([]byte, size, context.temp_allocator)
	js_load(raw_data(key), len(key), raw_data(base64Buffer), size)

	decodedData, error := base64.decode(string(base64Buffer), allocator = allocator)
	if error != .None {
		log.errorf("Failed to decode key: %v.", key)
		return nil, false
	}

	return decodedData, true
}

// @ref
// Serializes and saves a struct to **LocalStorage**.
saveStruct :: proc(key: string, data: ^$T) -> (success: bool) {
	if data == nil {
		log.errorf("Passed a nil struct pointer for key %v.", key)
		return false
	}

	rawBytes := mem.ptr_to_bytes(data)
	encoded, error := base64.encode(rawBytes, context.temp_allocator)

	if error != .None {
		log.errorf("Failed to encode struct for key %v.", key)
		return false
	}

	js_save(raw_data(key), len(key), raw_data(encoded), len(encoded))
	return true
}

// @ref
// Loads a struct from **LocalStorage**.
// Handles size mismatches (debug vs release) similar to the **desktop** implementation.
loadStruct :: proc(key: string, data: ^$T) -> (success: bool) {
	if data == nil {
		log.errorf("Passed a nil pointer for key %v.", key)
		return false
	}

	size := js_load_size(raw_data(key), len(key))
	if size == 0 {
		log.errorf("Struct to load to %v key is empty.", key)
		return false
	}

	base64Buffer := make([]byte, size, context.temp_allocator)
	js_load(raw_data(key), len(key), raw_data(buf), size)

	decodedBytes, error := base64.decode(string(buf), context.temp_allocator)
	if error != .None {
		log.errorf("Failed to decode struct data for key: %v.", key)
		return false
	}

	if len(decodedBytes) != size_of(T) {
		when ODIN_DEBUG {
			// if debug (during development) changing size of saves is common, hence try to load what safely can.
			log.warnf(
				"Save data size mismatch for '%v'. Partial load. Expected size: %vB, Received size: %vB.",
				key,
				size_of(T),
				len(decodedBytes),
			)
			copySize := min(len(decodedBytes), size_of(T))
			mem.copy(data, raw_data(decodedBytes), copySize)
			return true
		} else {
			// if release version, just error
			log.errorf(
				"Save data size mismatch for '%v'. Expected size: %vB, Received size: %vB.",
				key,
				size_of(T),
				len(decodedBytes),
			)
			return false
		}
	}

	mem.copy(data, raw_data(decodedBytes), size_of(T))
	return true
}
