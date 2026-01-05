package audio

import "core:fmt"
import "core:log"
import "core:sync"

import io "bonsai:core/platform"
import "bonsai:types/game"

@(private = "file") // private helper for registering sounds from pcm data
_registerSound :: proc(pcmData: []f32, channels, rate: int) -> SoundHandle {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	id := _mixer.nextId
	_mixer.nextId += 1

	sound := Sound {
		samples    = pcmData,
		channels   = channels,
		sampleRate = rate,
	}
	_mixer.sounds[id] = sound
	return id
}

// @ref
// Loads an audio asset from the disk based on the provided *AudioName* enum.
//
// This function handles reading the file, parsing the audio data (WAV file format),
// and registering it with the mixer.
//
// Returns 0 if loading or parsing fails.
load :: proc(name: game.AudioName) -> SoundHandle {
	filename := game.audioFilename[name]
	path := fmt.tprintf("assets/audio/%s", filename)
	data, success := io.read_entire_file(path)
	if !success {
		log.errorf("Failed to read audio file at path: %s", path)
		return 0
	}
	defer delete(data)

	info, ok := parseFromBytes(data)
	if !ok {
		log.errorf("Failed to parse audio file: %s (Header invalid).", path)
		return 0
	}

	return _registerSound(info.samples, info.channels, info.sampleRate)
}
