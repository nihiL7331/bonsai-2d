package audio

import saudio "bonsai:libs/sokol/audio"
import slog "bonsai:libs/sokol/log"
import "bonsai:types/game"
import "bonsai:types/gmath"

import "core:log"
import "core:math"
import "core:slice"
import "core:sync"

// "configurables" TODO: move to a "config" file
MIXER_VOICES_SIZE :: 64
DEFAULT_MIN_DISTANCE :: game.GAME_WIDTH / 4
DEFAULT_MAX_DISTANCE :: game.GAME_WIDTH / 2

// IDs for voices and sounds
VoiceHandle :: distinct int
SoundHandle :: distinct u64

// audio groups/layer, good for modifying voices
Bus :: enum {
	Master,
	SFX,
	Music,
} // add more if needed

Sound :: struct {
	samples:    []f32,
	channels:   int,
	sampleRate: int,
}

// this is essentialy the "entity" of sound, that outputs sound
Voice :: struct {
	id:          SoundHandle,
	cursor:      int,
	active:      bool,
	volume:      f32,
	loop:        bool,
	panning:     f32, // -1.0 -> +1.0
	spatial:     bool,
	position:    gmath.Vec2,
	minDistance: f32, // distance where falloff starts (volume is 1.0)
	maxDistance: f32, // distance where falloff ends (volume is 0.0)
	bus:         Bus,
}

Mixer :: struct {
	lock:       sync.Mutex,
	voices:     [MIXER_VOICES_SIZE]Voice,
	sounds:     map[SoundHandle]Sound,
	next:       SoundHandle,
	position:   gmath.Vec2, // listener position
	busVolumes: [Bus]f32,
}

@(private)
_mixer: Mixer

init :: proc() {
	_mixer.next = 1
	//default volumes to full volume
	_mixer.busVolumes[.Master] = 1.0
	_mixer.busVolumes[.SFX] = 1.0
	_mixer.busVolumes[.Music] = 1.0
	_mixer.sounds = make(map[SoundHandle]Sound)
	description := saudio.Desc {
		num_channels = 2,
		sample_rate = 44100, // might want to go with lower quality for less memory usage
		buffer_frames = 2048,
		stream_cb = _audioCallback,
		logger = {func = slog.func},
	}
	saudio.setup(description)
}

//generic cleanup
shutdown :: proc() {
	saudio.shutdown()
	for _, sound in _mixer.sounds {
		delete(sound.samples)
	}
	delete(_mixer.sounds)
}

play :: proc {
	playGlobal,
	playSpatial,
}

playGlobal :: proc(
	id: SoundHandle,
	volume: f32 = 1.0,
	bus: Bus = Bus.Master,
	loop: bool = false,
	panning: f32 = 0.0,
) -> VoiceHandle {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	for &voice, index in _mixer.voices {
		if !voice.active {
			voice.id = id
			voice.cursor = 0
			voice.active = true
			voice.volume = volume
			voice.loop = loop
			voice.panning = panning
			voice.spatial = false
			voice.bus = bus
			return VoiceHandle(index)
		}
	}
	log.warn("No space for a new voice in mixer.")
	return -1
}

playSpatial :: proc(
	id: SoundHandle,
	volume: f32 = 1.0,
	position: gmath.Vec2,
	bus: Bus = Bus.Master,
	minDistance: f32 = DEFAULT_MIN_DISTANCE,
	maxDistance: f32 = DEFAULT_MAX_DISTANCE,
	loop: bool = false,
) -> VoiceHandle {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	for &voice, index in _mixer.voices {
		if !voice.active {
			voice.id = id
			voice.cursor = 0
			voice.active = true
			voice.volume = volume
			voice.loop = loop
			voice.spatial = true
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

stop :: proc(id: VoiceHandle) {
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	if id >= 0 && id < MIXER_VOICES_SIZE {
		_mixer.voices[id].active = false
	}

	log.infof("Stopped voice (ID: %v)", id)
}

// default listener position is the cameraPosition. if want to override that,
// this function has to be called every frame.
setListenerPosition :: proc(position: gmath.Vec2) {
	_mixer.position = position
}

@(private)
_audioCallback :: proc "c" (buffer: ^f32, numFrames: i32, numChannels: i32) {
	context = {}
	sync.lock(&_mixer.lock)
	defer sync.unlock(&_mixer.lock)

	totalSamples := int(numFrames * numChannels)
	output := slice.from_ptr(buffer, totalSamples)

	slice.fill(output, 0.0)

	for &voice in _mixer.voices {
		if !voice.active do continue
		sound, ok := _mixer.sounds[voice.id]
		if !ok {
			voice.active = false
			continue
		}

		volume := voice.volume * _mixer.busVolumes[voice.bus] * _mixer.busVolumes[.Master]
		panning := voice.panning

		if voice.spatial {
			distanceX := voice.position.x - _mixer.position.x
			distanceY := voice.position.y - _mixer.position.y
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
				if voice.loop {
					voice.cursor = 0
				} else {
					voice.active = false
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
