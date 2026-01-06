package audio

import "bonsai:core/gmath"
import sokol_audio "bonsai:libs/sokol/audio"
import sokol_log "bonsai:libs/sokol/log"
import "bonsai:types/game"

import "core:log"
import "core:math"
import "core:slice"
import "core:sync"

// @ref
// Amount of voices. Describes how many audio clips can play **at once**.
MIXER_VOICE_CAPACITY :: 64
// @ref
// Default distance at which the falloff for spatial audio reaches **1.0** (max volume).
DEFAULT_MIN_DISTANCE :: game.GAME_WIDTH / 4
// @ref
// Default distance at which the falloff for spatial audio reaches **0.0** (muted).
DEFAULT_MAX_DISTANCE :: game.GAME_WIDTH / 2

// @ref
// ID for a **Voice** object.
VoiceHandle :: distinct int
// @ref
// ID for a **Sound** object.
SoundHandle :: distinct u64

// @ref
// Audio bus allows to mix the audio and let users control the volume of each element of audio in the game.
Bus :: enum {
	Master,
	SFX,
	Music,
} // add more if needed

// @ref
// Structure definition for the "sound", being an **audio clip container**.
//
// Holds the raw sample data and format information.
Sound :: struct {
	samples:    []f32,
	channels:   int,
	sampleRate: int,
}

// @ref
// Structure definition for the "voice", which is essentialy the entity equivalent of the audio system.
//
// It defines all active state variables needed to output a specific instance of **Sound.
Voice :: struct {
	id:          SoundHandle,
	cursor:      int,
	position:    gmath.Vector2,
	volume:      f32,
	panning:     f32, // Values range from -1.0 to +1.0
	minDistance: f32,
	maxDistance: f32,
	bus:         Bus,
	isActive:    bool,
	isLooped:    bool,
	isSpatial:   bool,
}

// @ref
// Internal state container for the audio mixer.
//
// Holds the thread lock, the pool of **Voices**, loaded **Sound** data, and listener configuration.
Mixer :: struct {
	lock:             sync.Mutex,
	voices:           [MIXER_VOICE_CAPACITY]Voice,
	sounds:           map[SoundHandle]Sound,
	nextId:           SoundHandle,
	listenerPosition: gmath.Vector2,
	busVolumes:       [Bus]f32,
}

@(private = "package")
_mixer: Mixer

// @ref
// Initializes the audio subsystem, sets up the **Sokol audio** backend, and prepares the mixer state.
//
// This **must** be called before loading or playing any sounds.
init :: proc() {
	_mixer.nextId = 1
	//default volumes to full volume
	_mixer.busVolumes[.Master] = 1.0
	_mixer.busVolumes[.SFX] = 1.0
	_mixer.busVolumes[.Music] = 1.0
	_mixer.sounds = make(map[SoundHandle]Sound)
	description := sokol_audio.Desc {
		num_channels = 2,
		sample_rate = 44100, // might want to go with lower quality for less memory usage
		buffer_frames = 2048,
		stream_cb = _audioCallback,
		logger = {func = sokol_log.func},
	}
	sokol_audio.setup(description)
}

// @ref
// Shuts down the audio subsystem and frees all loaded sound samples and mixer resources.
shutdown :: proc() {
	sokol_audio.shutdown()
	for _, sound in _mixer.sounds {
		delete(sound.samples)
	}
	delete(_mixer.sounds)
}


// @ref
// Main entry point for playing sounds.
//
// Use **playGlobal** for UI/Music and **playSpatial** for in-world sound effects.
play :: proc {
	playGlobal,
	playSpatial,
}


// @ref
// Plays a sound in **global** mode (no spatial positioning).
//
// Ideal for UI sounds, background music, or narration.
playGlobal :: proc(
	id: SoundHandle,
	volume: f32 = 1.0,
	bus: Bus = Bus.Master,
	isLooped: bool = false,
	panning: f32 = 0.0,
) -> VoiceHandle {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	for &voice, index in _mixer.voices {
		if !voice.isActive {
			voice.id = id
			voice.cursor = 0
			voice.isActive = true
			voice.volume = volume
			voice.isLooped = isLooped
			voice.panning = panning
			voice.isSpatial = false
			voice.bus = bus
			return VoiceHandle(index)
		}
	}
	log.warn("No space for a new voice in mixer.")
	return -1
}

// @ref
// Plays a sound at a **specific position in the world**.
//
// Volume and panning are automatically calculated based on the listener's position.
playSpatial :: proc(
	id: SoundHandle,
	volume: f32 = 1.0,
	position: gmath.Vector2,
	bus: Bus = Bus.Master,
	minDistance: f32 = DEFAULT_MIN_DISTANCE,
	maxDistance: f32 = DEFAULT_MAX_DISTANCE,
	isLooped: bool = false,
) -> VoiceHandle {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	for &voice, index in _mixer.voices {
		if !voice.isActive {
			voice.id = id
			voice.cursor = 0
			voice.isActive = true
			voice.volume = volume
			voice.isLooped = isLooped
			voice.isSpatial = true
			voice.position = position
			voice.minDistance = minDistance
			voice.maxDistance = maxDistance
			voice.bus = bus
			return VoiceHandle(index)
		}
	}
	log.warn("No space for a new voice in mixer.")
	return -1
}

// @ref
// Immediately stops a specific voice from playing.
stop :: proc(id: VoiceHandle) {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	if id >= 0 && id < MIXER_VOICE_CAPACITY {
		_mixer.voices[id].isActive = false
	}

	log.infof("Stopped voice (ID: %v)", id)
}

// @ref
// Updates the position of the "listener" (usually the camera or player) for spatial audio calculations.
//
// It **defaults to the camera position**. This should be called every frame to override that default behavior.
setListenerPosition :: proc(position: gmath.Vector2) {
	_mixer.listenerPosition = position
}

// @ref
// Returns the current position of the audio listener.
getListenerPosition :: proc() -> gmath.Vector2 {
	return _mixer.listenerPosition
}

@(private = "file")
_audioCallback :: proc "c" (buffer: ^f32, numFrames: i32, numChannels: i32) {
	context = {}
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	totalSamples := int(numFrames * numChannels)
	output := slice.from_ptr(buffer, totalSamples)

	slice.fill(output, 0.0)

	for &voice in _mixer.voices {
		if !voice.isActive do continue
		sound, ok := _mixer.sounds[voice.id]
		if !ok {
			voice.isActive = false
			continue
		}

		volume := voice.volume * _mixer.busVolumes[voice.bus] * _mixer.busVolumes[.Master]
		panning := voice.panning

		if voice.isSpatial {
			distanceX := voice.position.x - _mixer.listenerPosition.x
			distanceY := voice.position.y - _mixer.listenerPosition.y
			distance := math.sqrt(distanceX * distanceX + distanceY * distanceY)

			if distance > voice.maxDistance {
				volume = 0
			} else if distance > voice.minDistance {
				t := (distance - voice.minDistance) / (voice.maxDistance - voice.minDistance)
				volume *= (1.0 - t)
			}

			// basic panning, based on horizontal distance to voice. might want to move to a proper normal calculation.
			panning = math.clamp(distanceX / game.GAME_WIDTH, -1.0, 1.0)
		}

		if volume < 0.001 {
			// skip if the sound is too quiet for optimization purposes.
			voice.cursor += int(numFrames) * sound.channels
			continue
		}

		gainLeft := math.min(1.0, 1.0 - panning) * volume
		gainRight := math.min(1.0, 1.0 + panning) * volume

		for frameIndex := 0; frameIndex < int(numFrames); frameIndex += 1 {
			if voice.cursor >= len(sound.samples) {
				if voice.isLooped {
					voice.cursor = 0
				} else {
					voice.isActive = false
					break
				}
			}

			leftSample: f32
			rightSample: f32

			if sound.channels == 1 { 	// if sound is mono, distribute it across stereo samples equally
				v := sound.samples[voice.cursor]
				leftSample = v
				rightSample = v
				voice.cursor += 1
			} else { 	// if its stereo, can just get them
				if voice.cursor + 1 >= len(sound.samples) do break
				leftSample = sound.samples[voice.cursor]
				rightSample = sound.samples[voice.cursor + 1]
				voice.cursor += 2
			}

			output[frameIndex * 2 + 0] += leftSample * gainLeft
			output[frameIndex * 2 + 1] += rightSample * gainRight
		}
	}
}
