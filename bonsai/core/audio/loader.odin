package audio

import "core:fmt"
import "core:log"
import "core:sync"

import io "bonsai:core/platform"
import "bonsai:types/game"

@(private) // private helper for registering sounds from pcm data
_registerSound :: proc(pcmData: []f32, channels, rate: int) -> SoundHandle {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	id := _mixer.next
	_mixer.next += 1

	sound := Sound {
		samples    = pcmData,
		channels   = channels,
		sampleRate = rate,
	}
	_mixer.sounds[id] = sound
	return id
}

// function for reading the audio file. uses the automatically generated enums based off sound name.
// hence need to glue the path together
load :: proc(name: game.AudioName) -> SoundHandle {
	filename := game.audioFilename[name]
	path := fmt.tprintf("assets/audio/%s", filename)
	data, success := io.read_entire_file(path)
	if !success {
		log.error("Failed to read audio file.")
		return 0
	}
	defer delete(data)

	info, ok := parseFromBytes(data)
	if !ok {
		log.error("Failed to parse audio file (Header invalid).")
		return 0
	}

	return _registerSound(info.samples, info.channels, info.sampleRate)
}
