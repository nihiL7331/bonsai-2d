#+build wasm32, wasm64p32
package web

//
// Custom allocator implementation for web using Emscripten's libc.
// Credit: Based on Karl Zylinski's odin-sokol-web implementation.
//

import "base:intrinsics"
import "core:c"
import "core:mem"

// c/emscripten bindings
@(default_calling_convention = "c")
foreign _ {
	calloc :: proc(num, size: c.size_t) -> rawptr ---
	free :: proc(ptr: rawptr) ---
	malloc :: proc(size: c.size_t) -> rawptr ---
	realloc :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---
}

// Returns a memory allocator that wraps Emscripten's malloc and free.
//
// This handles manual memory alignment, which is required for certain Odin features
// like maps and SIMD that standard malloc might not guarantee on WASM.
allocator :: proc "contextless" () -> mem.Allocator {
	return mem.Allocator{_allocatorProc, nil}
}

@(private = "file")
_allocatorProc :: proc(
	allocatorData: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	oldMemory: rawptr,
	oldSize: int,
	location := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {

	// internal helper
	// allocates memory with specific alignment requirements
	// allocates extra space to store the original pointer for free called later
	_alignedAlloc :: proc(
		size, alignment: int,
		zeroMemory: bool,
		oldPtr: rawptr = nil,
	) -> (
		[]byte,
		mem.Allocator_Error,
	) {
		alignmentRequirement := max(alignment, align_of(rawptr))
		totalSpace := size + alignmentRequirement - 1

		allocatedMem: rawptr

		if oldPtr != nil {
			// retrieve the original pointer from the slot before the aligned memory
			originalOldPtr := mem.ptr_offset((^rawptr)(oldPtr), -1)^
			allocatedMem = realloc(originalOldPtr, c.size_t(totalSpace + size_of(rawptr)))
		} else if zeroMemory {
			// calloc zeros memory automatically
			allocatedMem = calloc(c.size_t(totalSpace + size_of(rawptr)), 1)
		} else {
			allocatedMem = malloc(c.size_t(totalSpace + size_of(rawptr)))
		}

		if allocatedMem == nil {
			return nil, mem.Allocator_Error.Out_Of_Memory
		}

		// calculate aligned address
		alignedMemStart := rawptr(mem.ptr_offset((^u8)(allocatedMem), size_of(rawptr)))
		ptrAddr := uintptr(alignedMemStart)
		alignedAddr :=
			(ptrAddr - 1 + uintptr(alignmentRequirement)) & -uintptr(alignmentRequirement)

		// store the original pointer immediately before the aligned address
		alignedMem := rawptr(alignedAddr)
		mem.ptr_offset((^rawptr)(alignedMem), -1)^ = allocatedMem

		diff := int(alignedAddr - ptrAddr)
		if (size + diff) > totalSpace {
			return nil, mem.Allocator_Error.Out_Of_Memory
		}

		return mem.byte_slice(alignedMem, size), nil
	}

	// internal helper
	// frees memory allocated by _alignedAlloc
	_alignedFree :: proc(ptr: rawptr) {
		if ptr != nil {
			originalPtr := mem.ptr_offset((^rawptr)(ptr), -1)^
			free(originalPtr)
		}
	}

	// internal helper
	// resizes aligned memory
	_alignedResize :: proc(
		ptr: rawptr,
		oldSize: int,
		newSize: int,
		newAlignment: int,
	) -> (
		[]byte,
		mem.Allocator_Error,
	) {
		if ptr == nil {
			return nil, nil
		}
		return _alignedAlloc(newSize, newAlignment, true, ptr)
	}

	// allocator mode switching

	switch mode {
	case mem.Allocator_Mode.Alloc:
		return _alignedAlloc(size, alignment, true)

	case mem.Allocator_Mode.Alloc_Non_Zeroed:
		return _alignedAlloc(size, alignment, false)

	case mem.Allocator_Mode.Free:
		_alignedFree(oldMemory)
		return nil, nil

	case mem.Allocator_Mode.Resize:
		if oldMemory == nil {
			return _alignedAlloc(size, alignment, true)
		}

		bytes := _alignedResize(oldMemory, oldSize, size, alignment) or_return

		// realloc doesn't zero the new bytes, so we do it manually.
		if size > oldSize {
			newRegion := raw_data(bytes[oldSize:])
			intrinsics.mem_zero(newRegion, size - oldSize)
		}

		return bytes, nil

	case mem.Allocator_Mode.Resize_Non_Zeroed:
		if oldMemory == nil {
			return _alignedAlloc(size, alignment, false)
		}

		return _alignedResize(oldMemory, oldSize, size, alignment)

	case mem.Allocator_Mode.Query_Features:
		set := (^mem.Allocator_Mode_Set)(oldMemory)
		if set != nil {
			set^ = {.Alloc, .Free, .Resize, .Query_Features}
		}
		return nil, nil

	case mem.Allocator_Mode.Free_All, mem.Allocator_Mode.Query_Info:
		return nil, mem.Allocator_Error.Mode_Not_Implemented
	}
	return nil, mem.Allocator_Error.Mode_Not_Implemented
}
