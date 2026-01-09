package clock

// @overview
// This package manages the application's timing.
// It provides all essential utilities for frame-rate independent movement,
// time manipulation and global pause states.
//
// **Features:**
// - **Frame independence:** Access to `getDeltaTime` for consistent movement,
//   regardless of framerate.
// - **Time scaling:** Global control over game speed via `setTimeScale`.
// - **Pause system:** Built-in `setPaused` functionality useful for pause screens.
// - **Timers:** Functions like `hasTimestampPassed` and `getSecondsSince` to easily
//   handle cooldowns, delays and timers without ugly timer variables.
//
// **Usage:**
// ```Odin
// update :: proc() {
//   // Standard movement, stops when paused
//   pot.position += velocity * clock.getDeltaTime()
//
//   // Continues when paused
//   ui.rotation += speed * clock.getUnscaledDeltaTime()
//
//   // Simple cooldown check
//   if clock.hasTimestampPassed(nextAttackTime) {
//     potAttack()
//     nextAttackTime = clock.getGameTime() + 0.5
//   }
// }
// ```

import "core:log"
import "core:time"

// METRICS
@(private = "file")
_frameTimes: [60]f32
@(private = "file")
_frameIndex: int

// FRAME STATE
@(private = "file")
_deltaTime: f32 // affected by time scale
@(private = "file")
_unscaledDeltaTime: f32 // unaffected by time scale

// TIME STATE
@(private = "file")
_lastTickTime: f64
@(private = "file")
_applicationStartTime: time.Time

// GAME STATE
@(private = "file")
_gameTime: f64
@(private = "file")
_gameTicks: u64
@(private = "file")
_paused: bool
@(private = "file")
_timeScale: f32 = 1.0

// CONSTANTS
@(private = "file")
_SAFE_MAX_DURATION :: 99999999.0
@(private = "file")
_MAX_FRAME_DELTA_TIME :: 1.0 / 20.0

// Called at the start of each frame in main.odin.
// Updates the time data stored in the clock package.
tick :: proc() {
	currentTime := getApplicationTime()

	if _lastTickTime == 0 {
		_lastTickTime = currentTime
	}

	rawDeltaTime := f32(currentTime - _lastTickTime)
	_lastTickTime = currentTime

	if rawDeltaTime > _MAX_FRAME_DELTA_TIME {
		rawDeltaTime = _MAX_FRAME_DELTA_TIME
	}

	_unscaledDeltaTime = rawDeltaTime

	if _paused {
		_deltaTime = 0
	} else {
		_deltaTime = rawDeltaTime * _timeScale
		_gameTime += f64(_deltaTime)
	}

	_gameTicks += 1
	_updateMetrics(rawDeltaTime)
}

// @ref
// Returns the scaled time since the last frame in **seconds**.
// Returns `0.0` if the game is paused.
// Use this for game logic (movement, physics).
getDeltaTime :: proc() -> f32 {
	return _deltaTime
}

// @ref
// Returns the actual time since the last frame in **seconds**.
// Unaffected by pause or time scaling.
// Use this for UI animations or camera movement.
getUnscaledDeltaTime :: proc() -> f32 {
	return _unscaledDeltaTime
}

// @ref
// Returns total accumulated game time in **seconds**.
// This value stops increasing when paused.
getGameTime :: proc() -> f64 {
	return _gameTime
}

// @ref
// Returns the total number of **frames** (ticks) processed since app start.
getTicks :: proc() -> u64 {
	return _gameTicks
}

// @ref
// Setter for pausing the game (equivalent to `_timeScale = 0.0`).
setPaused :: proc(paused: bool) {
	_paused = paused
}

// @ref
// Returns `true`, if game is paused.
isPaused :: proc() -> bool {
	return _paused
}

// @ref
// Sets the speed multiplier of game time.
// **Default = 1.0**.
setTimeScale :: proc(scale: f32) {
	if scale < 0 {
		log.warn("Negative time scale is not supported. Clamping to 0.")
		_timeScale = 0
		return
	}
	_timeScale = scale
}

// @ref
// Returns the current time scale multiplier.
getTimeScale :: proc() -> f32 {
	return _timeScale
}

// @ref
// Returns average frame time (delta time) in seconds **over last 60 frames**.
// Useful for smoothing out jitter when displaying performance.
getAverageFrameTime :: proc() -> f32 {
	sum: f32 = 0
	for t in _frameTimes do sum += t
	return sum / 60.0
}

// @ref
// Returns **estimated** frames per seconds the application is running at.
// Calculated using the average frame time over last 60 frames.
getFps :: proc() -> int {
	average := getAverageFrameTime()
	if average == 0 do return 0
	return int(1.0 / average)
}

// @ref
// Returns the total **real-world seconds** elapsed since the application initialized.
// This time is unaffected by game pauses or time scaling.
getApplicationTime :: proc() -> f64 {
	if _applicationStartTime._nsec == 0 {
		_applicationStartTime = time.now()
		return 0
	}
	return time.duration_seconds(time.since(_applicationStartTime))
}

// @ref
// Returns time when the application was initialized **in UNIX nanoseconds**.
// Useful for setting **seed** for pseudo-random values.
getApplicationInitTime :: proc() -> i64 {
	return _applicationStartTime._nsec
}

// @ref
// Checks if the current game time has passed a specific target timestamp (in **seconds**).
//
// Useful for cooldowns or timers.
// Returns `false` if the target timestamp is `-1` (unset).
hasTimestampPassed :: proc(targetTimestamp: f64) -> bool {
	if targetTimestamp == -1 {
		return false
	}
	return getGameTime() >= targetTimestamp
}

// @ref
// Calculates the duration **in seconds** that has passed since a specific timestamp.
//
// Returns a large safe value if the input time is invalid (0 or negative) to prevent logic errors.
getSecondsSince :: proc(timestamp: f64) -> f32 {
	if timestamp < 0 {
		log.error("Timestamp cannot be negative.")
		return _SAFE_MAX_DURATION
	} else if timestamp == 0 {
		return _SAFE_MAX_DURATION
	}

	return f32(getGameTime() - timestamp)
}

@(private = "file")
_updateMetrics :: proc(deltaTime: f32) {
	_frameTimes[_frameIndex] = deltaTime
	_frameIndex = (_frameIndex + 1) % 60
}
