package audio

import "core:mem"
import "core:slice"

WavHeader :: struct #packed {
	riffTag:       [4]u8,
	fileSize:      u32le,
	waveTag:       [4]u8,
	fmtTag:        [4]u8,
	fmtSize:       u32le,
	audioFormat:   u16le,
	numChannels:   u16le,
	sampleRate:    u32le,
	byteRate:      u32le,
	blockAlign:    u16le,
	bitsPerSample: u16le,
}

ParseResult :: struct {
	samples:    []f32,
	channels:   int,
	sampleRate: int,
}

//WAV
parseFromBytes :: proc(data: []byte) -> (result: ParseResult, success: bool) {
	if len(data) < size_of(WavHeader) {
		return {}, false
	}

	header := cast(^WavHeader)raw_data(data)
	if header.riffTag != {'R', 'I', 'F', 'F'} || header.waveTag != {'W', 'A', 'V', 'E'} {
		return {}, false
	}

	cursor := uintptr(raw_data(data)) + 12 // RIFF + size + WAVE is 12 bytes

	fmtChunkMarker := cast(^[4]u8)cursor
	if fmtChunkMarker^ != {'f', 'm', 't', ' '} do return {}, false

	fmtSizePointer := cast(^u32le)(cursor + 4)
	fmtSize := int(fmtSizePointer^)

	cursor += 8 + uintptr(fmtSize) // past FMT

	//search for data
	dataFound := false
	dataSize := u32(0)

	for cursor < uintptr(raw_data(data)) + uintptr(len(data)) {
		chunkTag := cast(^[4]u8)cursor
		chunkSizePointer := cast(^u32le)(cursor + 4)
		chunkSize := chunkSizePointer^

		if chunkTag^ == {'d', 'a', 't', 'a'} {
			dataFound = true
			dataSize = u32(chunkSize)
			cursor += 8
			break
		}

		cursor += 8 + uintptr(chunkSize)
	}

	if !dataFound do return {}, false

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
			floatSamples[index] = (f32(sample) - 128.0) / 128.0 // from unsinged 16-bit to -1.0 -> +1.0
		}
	} else if header.bitsPerSample == 32 {
		source := slice.reinterpret([]f32, pcmData)
		copy(floatSamples, source) // here we can directly copy
	}

	result.samples = floatSamples
	result.channels = int(header.numChannels)
	result.sampleRate = int(header.sampleRate)

	return result, true
}
