package audio

//
// This file is responsible for parsing WAV files to actual readable data. WAV files are not that complex,
// in the future might also add OGG support (useful for web).
//

import "core:log"
import "core:mem"
import "core:slice"

// this header follows the structure of an actual WAV file. use #packed to ensure the memory is placed
// exactly as expected.
@(private = "file")
_WavHeader :: struct #packed {
	riffTag:       [4]u8, // expecting 'RIFF'
	fileSize:      u32le,
	waveTag:       [4]u8, // expecting 'WAVE'
	fmtTag:        [4]u8, // expecting 'fmt '
	fmtSize:       u32le,
	audioFormat:   u16le, // 1 = PCM, 3 = IEEE float
	numChannels:   u16le,
	sampleRate:    u32le,
	byteRate:      u32le,
	blockAlign:    u16le,
	bitsPerSample: u16le,
}

// @ref
// Container for decoded PCM audio data.
//
// Contains the raw samples converted to `f32` (ranging from -1.0 to +1.0) and format metadata.
// The caller is responsible for freeing the `samples` slice.
ParseResult :: struct {
	samples:    []f32,
	channels:   int,
	sampleRate: int,
}

// @ref
// Decodes raw WAV file bytes into a usable audio buffer.
//
// Supports 8-bit (unsigned), 16-bit (signed), and 32-bit (float) WAV formats.
//
// Returns:
// - `result`: The parsed sample data and metadata.
// - `success`: False if the header is invalid or the format is unsupported.
parseFromBytes :: proc(data: []byte) -> (result: ParseResult, success: bool) {
	// data is too small to even be a proper WAV file
	if len(data) < size_of(_WavHeader) {
		log.error("Failed to parse WAV file. Data is too small.")
		return {}, false
	}

	header := cast(^_WavHeader)raw_data(data)
	// checking assumptions about the WAV file structure
	if header.riffTag != {'R', 'I', 'F', 'F'} || header.waveTag != {'W', 'A', 'V', 'E'} {
		return {}, false
	}

	if header.audioFormat != 1 && header.audioFormat != 3 {
		log.errorf(
			"Unsupported WAV audio format: %v (Only PCM or IEEE Float supported)",
			header.audioFormat,
		)
		return {}, false
	}

	if header.bitsPerSample != 8 && header.bitsPerSample != 16 && header.bitsPerSample != 32 {
		log.errorf(
			"Unsupported WAV bit depth: %v (Only 8, 16, or 32 supported)",
			header.bitsPerSample,
		)
		return {}, false
	}

	cursor := uintptr(raw_data(data)) + 12 // RIFF + size + WAVE is 12 bytes
	endOfFile := uintptr(raw_data(data)) + uintptr(len(data))

	fmtChunkMarker := cast(^[4]u8)cursor
	if fmtChunkMarker^ != {'f', 'm', 't', ' '} do return {}, false

	fmtSizePointer := cast(^u32le)(cursor + 4)
	fmtSize := int(fmtSizePointer^)

	cursor += 8 + uintptr(fmtSize) // past FMT

	//search for data
	dataFound := false
	dataSize := u32(0)

	// search until the tag for the data section of file is found
	for cursor < endOfFile {
		if cursor + 8 > endOfFile do break

		chunkTag := cast(^[4]u8)cursor
		chunkSizePointer := cast(^u32le)(cursor + 4)
		chunkSize := chunkSizePointer^

		if chunkTag^ == {'d', 'a', 't', 'a'} {
			dataFound = true
			dataSize = u32(chunkSize)
			cursor += 8
			break
		}

		// RIFF SPEC: chunks must be word-aligned, so if the size is odd, there's a padding byte.
		padding := chunkSize % 2
		cursor += 8 + uintptr(chunkSize) + uintptr(padding)
	}

	// if haven't found it, return
	if !dataFound {
		log.error("Couldn't find data tag in the WAV file.")
		return {}, false
	}

	if cursor + uintptr(dataSize) > endOfFile {
		log.error("WAV data chunk size exceeds file size.")
		return {}, false
	}

	pcmData := mem.byte_slice(rawptr(cursor), int(dataSize))
	totalSamples := int(dataSize) / (int(header.bitsPerSample) / 8)
	floatSamples := make([]f32, totalSamples)

	if header.bitsPerSample == 16 {
		source := slice.reinterpret([]i16le, pcmData)
		for sample, index in source {
			floatSamples[index] = f32(sample) / 32768.0 // from 16-bit to -1.0 -> +1.0
		}
	} else if header.bitsPerSample == 8 {
		source := pcmData
		for sample, index in source {
			floatSamples[index] = (f32(sample) - 128.0) / 128.0 // from unsinged 8-bit to -1.0 -> +1.0
		}
	} else if header.bitsPerSample == 32 {
		source := slice.reinterpret([]f32, pcmData)
		copy(floatSamples, source) // here can directly copy
	}

	// fill the ParseResult
	result.samples = floatSamples
	result.channels = int(header.numChannels)
	result.sampleRate = int(header.sampleRate)

	return result, true
}
