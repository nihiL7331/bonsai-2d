#+build darwin

package corehaptics

import "base:intrinsics"
import foundation "core:sys/darwin/Foundation"

foreign import CoreHaptics "system:CoreHaptics.framework"

messageSend :: intrinsics.objc_send

TimeImmediate: f64 : 0.0

EventType :: ^foundation.String
EventParameterId :: ^foundation.String

@(link_prefix = "CHHapticEventType")
foreign CoreHaptics {
	HapticTransient: EventType
	HapticContinuous: EventType
	AudioContinuous: EventType
	AudioCustom: EventType
}

@(link_prefix = "CHHapticEventParameterID")
foreign CoreHaptics {
	HapticIntensity: EventParameterId
	HapticSharpness: EventParameterId
	AttackTime: EventParameterId
	DecayTime: EventParameterId
	ReleaseTime: EventParameterId
	Sustained: EventParameterId
	AudioVolume: EventParameterId
	AudioPitch: EventParameterId
	AudioPan: EventParameterId
	AudioBrightness: EventParameterId
}

EngineStoppedReason :: enum foundation.Integer {
	AudioSessionInterrupt    = 1,
	ApplicationSuspended     = 2,
	IdleTimeout              = 3,
	NotifyWhenFinished       = 4,
	EngineDestroyed          = 5,
	GameControllerDisconnect = 6,
	SystemError              = -1,
}

@(objc_class = "GCHaptics")
Haptics :: struct {
	using _: foundation.Object,
}

@(objc_type = Haptics, objc_name = "createEngineWithLocality")
HapticsCreateEngineWithLocality :: proc "c" (
	self: ^Haptics,
	locality: HapticsLocality,
) -> ^HapticEngine {
	return messageSend(^HapticEngine, self, "createEngineWithLocality:", locality)
}

@(objc_class = "CHHapticEngine")
HapticEngine :: struct {
	using _: foundation.Object,
}

@(objc_type = HapticEngine, objc_name = "alloc", objc_is_class_method = true)
HapticEngineAlloc :: proc "c" () -> ^HapticEngine {
	return messageSend(^HapticEngine, HapticEngine, "alloc")
}

@(objc_type = HapticEngine, objc_name = "init")
HapticEngineInit :: proc "c" (self: ^HapticEngine) -> ^HapticEngine {
	return messageSend(^HapticEngine, self, "init")
}

@(objc_type = HapticEngine, objc_name = "startAndReturnError")
HapticEngineStartAndReturnError :: proc "c" (
	self: ^HapticEngine,
	error: ^^foundation.Error,
) -> bool {
	return messageSend(foundation.BOOL, self, "startAndReturnError:", error)
}

@(objc_type = HapticEngine, objc_name = "startWithCompletionHandler")
HapticEngineStartWithCompletionHandler :: proc "c" (self: ^HapticEngine, handler: rawptr) {
	messageSend(nil, self, "startWithCompletionHandler:", handler)
}

@(objc_type = HapticEngine, objc_name = "stopWithCompletionHandler")
HapticEngineStopWithCompletionHandler :: proc "c" (self: ^HapticEngine, handler: rawptr) {
	messageSend(nil, self, "stopWithCompletionHandler:", handler)
}

@(objc_type = HapticEngine, objc_name = "createPlayerWithPattern")
HapticEngineCreatePlayerWithPattern :: proc "c" (
	self: ^HapticEngine,
	pattern: ^HapticPattern,
	error: ^^foundation.Error,
) -> ^HapticPatternPlayer {
	return messageSend(
		^HapticPatternPlayer,
		self,
		"createPlayerWithPattern:error:",
		pattern,
		error,
	)
}

@(objc_type = HapticEngine, objc_name = "setStoppedHandler")
HapticEngineSetStoppedHandler :: proc "c" (self: ^HapticEngine, handler: rawptr) {
	messageSend(nil, self, "setStoppedHandler:", handler)
}

@(objc_type = HapticEngine, objc_name = "setResetHandler")
HapticEngineSetResetHandler :: proc "c" (self: ^HapticEngine, handler: rawptr) {
	messageSend(nil, self, "setResetHandler:", handler)
}

@(objc_class = "CHHapticPattern")
HapticPattern :: struct {
	using _: foundation.Object,
}

@(objc_type = HapticPattern, objc_name = "alloc", objc_is_class_method = true)
HapticPatternAlloc :: proc "c" () -> ^HapticPattern {
	return messageSend(^HapticPattern, HapticPattern, "alloc")
}

@(objc_type = HapticPattern, objc_name = "initWithEvents")
HapticPatternInitWithEvents :: proc "c" (
	self: ^HapticPattern,
	events: ^foundation.Array,
	parameters: ^foundation.Array,
	error: ^^foundation.Error,
) -> ^HapticPattern {
	return messageSend(
		^HapticPattern,
		self,
		"initWithEvents:parameters:error:",
		events,
		parameters,
		error,
	)
}

@(objc_class = "CHHapticEvent")
HapticEvent :: struct {
	using _: foundation.Object,
}

@(objc_type = HapticEvent, objc_name = "alloc", objc_is_class_method = true)
HapticEventAlloc :: proc "c" () -> ^HapticEvent {
	return messageSend(^HapticEvent, HapticEvent, "alloc")
}

@(objc_type = HapticEvent, objc_name = "initWithEventType")
HapticEvent_initWithEventType :: proc "c" (
	self: ^HapticEvent,
	eventType: EventType,
	parameters: ^foundation.Array,
	relativeTime: f64,
	duration: f64,
) -> ^HapticEvent {
	return messageSend(
		^HapticEvent,
		self,
		"initWithEventType:parameters:relativeTime:duration:",
		eventType,
		parameters,
		relativeTime,
		duration,
	)
}

@(objc_class = "CHHapticEventParameter")
HapticEventParameter :: struct {
	using _: foundation.Object,
}

@(objc_type = HapticEventParameter, objc_name = "alloc", objc_is_class_method = true)
HapticEventParameterAlloc :: proc "c" () -> ^HapticEventParameter {
	return messageSend(^HapticEventParameter, HapticEventParameter, "alloc")
}

@(objc_type = HapticEventParameter, objc_name = "initWithParameterID")
HapticEventParameterInitWithParameterId :: proc "c" (
	self: ^HapticEventParameter,
	parameterId: EventParameterId,
	value: f32,
) -> ^HapticEventParameter {
	return messageSend(
		^HapticEventParameter,
		self,
		"initWithParameterID:value:",
		parameterId,
		value,
	)
}

@(objc_class = "NSObject")
HapticPatternPlayer :: struct {
	using _: foundation.Object,
}

@(objc_type = HapticPatternPlayer, objc_name = "startAtTime")
HapticPatternPlayerStartAtTime :: proc "c" (
	self: ^HapticPatternPlayer,
	time: f64,
	error: ^^foundation.Error,
) -> bool {
	return messageSend(foundation.BOOL, self, "startAtTime:error:", time, error)
}

@(objc_type = HapticPatternPlayer, objc_name = "stopAtTime")
HapticPatternPlayerStopAtTime :: proc "c" (
	self: ^HapticPatternPlayer,
	time: f64,
	error: ^^foundation.Error,
) -> bool {
	return messageSend(foundation.BOOL, self, "stopAtTime:error:", time, error)
}

@(objc_type = HapticPatternPlayer, objc_name = "cancelAndReturnError")
HapticPatternPlayerCancelAndReturnError :: proc "c" (
	self: ^HapticPatternPlayer,
	error: ^^foundation.Error,
) -> bool {
	return messageSend(foundation.BOOL, self, "cancelAndReturnError:", error)
}
