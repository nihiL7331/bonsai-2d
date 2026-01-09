package gmath

import "core:math/rand"

@(private = "file")
_globalRandom: rand.Generator

@(private = "file")
_stateRandom: rand.Default_Random_State

@(private = "file")
_currentSeed: u64

// @ref
// Initializes the random number generator with a specific `seed`.
setRandomSeed :: proc(seed: u64) {
	_currentSeed = seed
	_stateRandom = rand.create(seed)
	_globalRandom = rand.default_random_generator(&_stateRandom)
}

// @ref
// Returns the **current seed** used by the random number generator.
getRandomSeed :: proc() -> u64 {
	return _currentSeed
}

// @ref
// Returns a random float between `0.0` and `1.0`.
randomFloatNormalized :: proc() -> f32 {
	return rand.float32(_globalRandom)
}

// @ref
// Returns a random float between `min` and `max`.
randomRange :: proc(min: f32, max: f32) -> f32 {
	return min + (rand.float32(_globalRandom) * (max - min))
}

// @ref
// Returns a random integer between `min` **(inclusive)** and `max` **(inclusive)**.
randomRangeInt :: proc(min: int, max: int) -> int {
	if min >= max do return min
	return min + rand.int_max(max - min + 1, _globalRandom)
}

// @ref
// Returns a random [`Vector2`](#vector2) point in a circle of radius 1.
randomCircleNormalized :: proc() -> Vector2 {
	return Vector2{randomFloatNormalized(), randomFloatNormalized()}
}

// @ref
// Returns a **random** element from a slice.
// Returns `false` if the slice is empty.
randomElement :: proc(list: []$T) -> (T, bool) {
	if len(list) == 0 do return {}, false

	index := rand.int_max(len(list), _globalRandom)
	return list[index], true
}
