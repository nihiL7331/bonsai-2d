package clock

//
// This file contains helper functions related to game and app time.
//

import "bonsai:core"

import "core:log"
import "core:time"

// internal tracking for when the app actually started (real time)
@(private = "file")
_applicationStartTime: time.Time

// for safe fallback durations
@(private = "file")
_SAFE_MAX_DURATION :: 99999999.0

// @ref
// Returns the total real-world seconds elapsed since the application initialized.
// This time is unaffected by game pauses or time scaling.
getApplicationTime :: proc() -> f64 {
	if _applicationStartTime._nsec == 0 {
		_applicationStartTime = time.now()
		return 0
	}
	return time.duration_seconds(time.since(_applicationStartTime))
}

// @ref
// Returns the total game time elapsed in seconds.
// This time may stop if the game is paused or slow down if the time scale is changed.
getGameTime :: proc() -> f64 {
	return core.getCoreContext().gameState.time.gameTimeElapsed
}

// @ref
// Checks if the current game time has passed a specific target timestamp.
//
// Useful for cooldowns or timers.
// Returns false if the target timestamp is -1 (unset).
hasTimestampPassed :: proc(targetTimestamp: f64) -> bool {
	if targetTimestamp == -1 {
		return false
	}
	return getGameTime() >= targetTimestamp
}

// @ref
// Calculates the duration (in seconds) that has passed since a specific timestamp.
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
