#+build darwin

package input

import "base:intrinsics"
import "core:log"
import foundation "core:sys/darwin/Foundation"

import "bonsai:libs/corehaptics"
import "bonsai:libs/gccontroller"

HAPTICS_SHARPNESS_LEFT :: 0.1
HAPTICS_SHARPNESS_RIGHT :: 0.9

@(private = "file")
_pendingDisconnects: [MAX_GAMEPADS]rawptr

@(private = "file")
_pendingDisconnectCount: int

@(private = "file")
_inputNeedsResync: bool

@(objc_class = "GCController")
GCController :: struct {
	using _: intrinsics.objc_object,
}

@(objc_class = "GCExtendedGamepad")
GCExtendedGamepad :: struct {
	using _: intrinsics.objc_object,
}

@(objc_class = "GCControllerButtonInput")
GCTrigger :: struct {
	using _: intrinsics.objc_object,
}

@(objc_class = "NSArray")
NSArray :: struct {
	using _: intrinsics.objc_object,
}

GamepadState :: struct {
	gamepads:              [MAX_GAMEPADS]Gamepad,
	cachedControllerCount: foundation.UInteger,
	connectBlock:          foundation.Block,
	disconnectBlock:       foundation.Block,
}

Gamepad :: struct {
	controller:            ^gccontroller.Controller,
	extendedGamepad:       ^gccontroller.ExtendedGamepad,
	buttonInputs:          [GamepadButton]^gccontroller.ControllerButtonInput,
	buttonWasPressed:      [GamepadButton]bool,
	hapticEngineLeftRight: [2]^corehaptics.HapticEngine,
	hapticPlayerLeftRight: [2]^corehaptics.HapticPatternPlayer,
	oldIntensityLeftRight: [2]f32,
	lastTriggerValues:     [2]f32,
	needsRemoval:          bool,
}

@(private = "file")
_gamepadState: GamepadState

initGamepad :: proc() {
	gccontroller.ControllerStartWirelessControllerDiscovery(nil)

	foundation.scoped_autoreleasepool()

	syncControllers()

	notificationCenter := foundation.NotificationCenter_defaultCenter()

	disconnectHandler := foundation.Block_createGlobalWithParam(
		nil,
		proc "c" (s: rawptr, n: ^foundation.Notification) {
			if _pendingDisconnectCount < MAX_GAMEPADS {
				_pendingDisconnects[_pendingDisconnectCount] = n->object()
				_pendingDisconnectCount += 1
			}
			_inputNeedsResync = true
		},
	)

	connectHandler := foundation.Block_createGlobalWithParam(
		nil,
		proc "c" (s: rawptr, n: ^foundation.Notification) {
			_inputNeedsResync = true
		},
	)

	notificationCenter->addObserverForName(
		gccontroller.DidDisconnectNotification,
		nil,
		nil,
		disconnectHandler,
	)
	notificationCenter->addObserverForName(
		gccontroller.DidConnectNotification,
		nil,
		nil,
		connectHandler,
	)

}

platformUpdateGamepads :: proc() {
	if _inputNeedsResync {
		syncControllers()
		_inputNeedsResync = false
	}
}

syncControllers :: proc() {
	osControllers := gccontroller.ControllerControllers()
	controllerCount := osControllers != nil ? int(osControllers->count()) : 0

	foundInOsList: [MAX_GAMEPADS]bool

	for i in 0 ..< controllerCount {
		osController := osControllers->object(foundation.UInteger(i))
		if osController == nil do continue

		for &gamepad, index in _gamepadState.gamepads {
			if gamepad.controller == osController {
				foundInOsList[index] = true
				break
			}
		}
	}

	for &gamepad, index in _gamepadState.gamepads {
		if gamepad.controller != nil && !foundInOsList[index] {
			gamepad.needsRemoval = true
		}
	}

	removeDisconnectedControllers()

	for i in 0 ..< controllerCount {
		osController := osControllers->object(foundation.UInteger(i))
		if osController == nil do continue

		if isControllerRegistered(osController) do continue

		addController(osController)
	}
}

addController :: proc(controller: ^gccontroller.Controller) {
	extendedGamepad := controller->extendedGamepad()
	if extendedGamepad == nil do return

	slot := -1
	for gamepad, index in _gamepadState.gamepads {
		if gamepad.controller == nil {
			slot = index
			break
		}
	}
	if slot == -1 do return

	log.infof("Connected gamepad ID: %v", slot)
	_gamepadState.gamepads[slot].controller = controller
	_gamepadState.gamepads[slot].extendedGamepad = extendedGamepad
	_gamepadState.gamepads[slot].buttonInputs = makeButtonInputs(extendedGamepad)
	_gamepadState.gamepads[slot].needsRemoval = false
}

getGamepadEvents :: proc(events: ^[dynamic]GamepadEvent) {
	if _inputNeedsResync do return

	for &gamepad, gamepadIndex in _gamepadState.gamepads {
		if gamepad.controller == nil || gamepad.needsRemoval do continue

		for button in GamepadButton {
			buttonInput := gamepad.buttonInputs[button]
			if buttonInput == nil do continue

			isPressed := gamepad.buttonInputs[button]->isPressed()
			wasPressed := gamepad.buttonWasPressed[button]

			if isPressed && !wasPressed {
				append(events, ButtonPressed{index = gamepadIndex, button = button})
			} else if !isPressed && wasPressed {
				append(events, ButtonReleased{index = gamepadIndex, button = button})
			}

			gamepad.buttonWasPressed[button] = isPressed
		}
	}
}

removeDisconnectedControllers :: proc() {
	for &gamepad in _gamepadState.gamepads {
		if !gamepad.needsRemoval do continue
		when ODIN_MINIMUM_OS_VERSION >= 11_00_00 {
			for &engine in gamepad.hapticEngineLeftRight {
				if engine != nil {
					engine->release()
					engine = nil
				}
			}
			for &player in gamepad.hapticPlayerLeftRight {
				if player != nil {
					player->release()
					player = nil
				}
			}
		}

		gamepad = {}
	}
}

isControllerRegistered :: proc(controller: ^gccontroller.Controller) -> bool {
	for gamepad in _gamepadState.gamepads {
		if gamepad.controller == controller do return true
	}

	return false
}

isGamepadActive :: proc(index: GamepadIndex) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	if _inputNeedsResync do return false

	return(
		_gamepadState.gamepads[index].controller != nil &&
		!_gamepadState.gamepads[index].needsRemoval \
	)
}

getControllerPointer :: proc(gamepadIndex: GamepadIndex) -> rawptr {
	classPointer := foundation.objc_lookUpClass("GCController")
	if classPointer == nil do return nil

	class := cast(^GCController)classPointer

	array := intrinsics.objc_send(^NSArray, class, "controllers")

	count := intrinsics.objc_send(uint, array, "count")
	if uint(gamepadIndex) >= count do return nil

	controller := intrinsics.objc_send(
		^intrinsics.objc_object,
		array,
		"objectAtIndex:",
		uint(gamepadIndex),
	)
	return rawptr(controller)
}

removeController :: proc(controller: ^gccontroller.Controller) {
	for &gamepad in _gamepadState.gamepads {
		if gamepad.controller == controller {
			gamepad.needsRemoval = true
			return
		}
	}
}

makeButtonInputs :: proc(
	extendedGamepad: ^gccontroller.ExtendedGamepad,
) -> [GamepadButton]^gccontroller.ControllerButtonInput {
	return {
		.None = nil,
		.RightFaceDown = extendedGamepad->buttonA(),
		.RightFaceRight = extendedGamepad->buttonB(),
		.RightFaceLeft = extendedGamepad->buttonX(),
		.RightFaceUp = extendedGamepad->buttonY(),
		.LeftShoulder = extendedGamepad->leftShoulder(),
		.RightShoulder = extendedGamepad->rightShoulder(),
		.LeftTrigger = extendedGamepad->leftTrigger(),
		.RightTrigger = extendedGamepad->rightTrigger(),
		.MiddleFaceRight = extendedGamepad->buttonMenu(),
		.MiddleFaceMiddle = nil,
		.MiddleFaceLeft = extendedGamepad->buttonOptions(),
		.LeftStickPress = extendedGamepad->leftThumbstickButton(),
		.RightStickPress = extendedGamepad->rightThumbstickButton(),
		.LeftFaceUp = extendedGamepad->dpad()->up(),
		.LeftFaceDown = extendedGamepad->dpad()->down(),
		.LeftFaceLeft = extendedGamepad->dpad()->left(),
		.LeftFaceRight = extendedGamepad->dpad()->right(),
	}
}

getGamepadAxis :: proc(index: GamepadIndex, axis: GamepadAxis) -> f32 {
	if !isGamepadActive(index) do return 0

	extendedGamepad := _gamepadState.gamepads[index].extendedGamepad

	switch axis {
	case .None:
		return 0
	case .LeftStickX:
		return extendedGamepad->leftThumbstick()->xAxis()->value()
	case .LeftStickY:
		return extendedGamepad->leftThumbstick()->yAxis()->value()
	case .RightStickX:
		return extendedGamepad->rightThumbstick()->xAxis()->value()
	case .RightStickY:
		return extendedGamepad->rightThumbstick()->yAxis()->value()
	case .LeftTrigger:
		return extendedGamepad->leftTrigger()->value()
	case .RightTrigger:
		return extendedGamepad->rightTrigger()->value()
	}

	return 0
}

setGamepadVibration :: proc(index: GamepadIndex, left: f32, right: f32) {
	when ODIN_MINIMUM_OS_VERSION >= 11_00_00 {
		if !isGamepadActive(index) do return
		gamepad := &_gamepadState.gamepads[index]

		if left < 0.01 {
			stopHapticPlayer(&gamepad.hapticPlayerLeftRight[0])
		}
		if right < 0.01 {
			stopHapticPlayer(&gamepad.hapticPlayerLeftRight[1])
		}

		leftIntensityDifference := abs(gamepad.oldIntensityLeftRight[0] - left)
		rightIntensityDifference := abs(gamepad.oldIntensityLeftRight[1] - right)
		if leftIntensityDifference < 0.1 && rightIntensityDifference < 0.1 do return

		gamepad.oldIntensityLeftRight = {left, right}

		for &player in gamepad.hapticPlayerLeftRight {
			stopHapticPlayer(&player)
		}

		leftInitialized := initializeHapticEngine(
			&gamepad.hapticEngineLeftRight[0],
			gccontroller.LeftHandle,
			gamepad,
		)
		rightInitialized := initializeHapticEngine(
			&gamepad.hapticEngineLeftRight[1],
			gccontroller.RightHandle,
			gamepad,
		)

		if !leftInitialized && !rightInitialized do return

		createHapticPlayer(0, left, gamepad)
		createHapticPlayer(1, right, gamepad)
	}
}

when ODIN_MINIMUM_OS_VERSION >= 11_00_00 {
	stopHapticPlayer :: proc(player: ^^corehaptics.HapticPatternPlayer) {
		if player^ == nil do return

		player^->stopAtTime(corehaptics.TimeImmediate, nil)
		player^->release()
		player^ = nil
	}

	initializeHapticEngine :: proc(
		engine: ^^corehaptics.HapticEngine,
		locality: gccontroller.HapticsLocality,
		gamepad: ^Gamepad,
	) -> bool {
		if engine^ != nil do return true

		haptics := gamepad.controller->haptics()
		if haptics == nil do return false

		engine^ = (cast(^corehaptics.Haptics)haptics)->createEngineWithLocality(locality)
		success := engine^ != nil && engine^->startAndReturnError(nil)

		return success
	}

	createHapticPlayer :: proc(leftRight: int, intensity: f32, gamepad: ^Gamepad) {
		pattern: ^corehaptics.HapticPattern

		foundation.scoped_autoreleasepool()

		sharpness: f32 = leftRight == 0 ? HAPTICS_SHARPNESS_LEFT : HAPTICS_SHARPNESS_RIGHT

		sharpnessParameter := corehaptics.HapticEventParameterAlloc()->initWithParameterID(
			corehaptics.HapticSharpness,
			sharpness,
		)
		intensityParameter := corehaptics.HapticEventParameterAlloc()->initWithParameterID(
			corehaptics.HapticIntensity,
			intensity,
		)

		parameters := [2]^foundation.Object{intensityParameter, sharpnessParameter}
		parametersArray := foundation.Array_alloc()->initWithObjects(raw_data(&parameters), 2)

		event := corehaptics.HapticEventAlloc()->initWithEventType(
			corehaptics.HapticContinuous,
			parametersArray,
			0,
			gccontroller.HapticDurationInfinite,
		)
		events := [1]^foundation.Object{event}
		eventsArray := foundation.Array_alloc()->initWithObjects(raw_data(&events), 1)

		pattern = corehaptics.HapticPatternAlloc()->initWithEvents(eventsArray, nil, nil)
		if pattern == nil do return

		gamepad.hapticPlayerLeftRight[leftRight] = gamepad.hapticEngineLeftRight[leftRight]->createPlayerWithPattern(
			pattern,
			nil,
		)
		if gamepad.hapticPlayerLeftRight[leftRight] != nil {
			gamepad.hapticPlayerLeftRight[leftRight]->startAtTime(corehaptics.TimeImmediate, nil)
		}
	}
}
