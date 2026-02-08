package input

import "bonsai:core/gmath"
import "bonsai:core/render"

MAX_TOUCHES :: 10

// @ref
// Defines the lifecycle of a finger.
TouchPhase :: enum {
	None, // Slot is empty
	Began, // On finger touch
	Moved, // Finger is moving
	Stationary, // Finger is holding still
	Ended, // On finger lift
	Cancelled, // System interrupt
}

Touch :: struct {
	index:    i64, // unique hwid from Sokol
	position: gmath.Vector2,
	phase:    TouchPhase,
}

VirtualButton :: struct {
	target: GamepadButton,
}

VirtualStick :: struct {
	targetAxisX:  GamepadAxis,
	targetAxisY:  GamepadAxis,
	currentValue: gmath.Vector2,
}

VirtualBehavior :: union {
	VirtualButton,
	VirtualStick,
}

VirtualControl :: struct {
	position:    gmath.Vector2,
	radius:      f32,
	touchIndex:  i64,
	playerIndex: uint,
	data:        VirtualBehavior,
}

@(private = "file")
_isTouchDrivingMouse := false

@(private = "file")
_virtualControls: [dynamic]VirtualControl

// @ref
// Adds a virtual joystick to the touch overlay for a specified player.
// Default `playerIndex` is **0**.
// `position` is the middle point of the thumbstick.
// :::note(Example)
// input.addVirtualStick(pos, 20.0, playerIndex = 1) // adds the thumbstick for player 2
// :::
addVirtualStick :: proc(
	position: gmath.Vector2,
	radius: f32,
	axisX: GamepadAxis,
	axisY: GamepadAxis,
	playerIndex: uint = 0,
) {
	append(
		&_virtualControls,
		VirtualControl {
			position = position,
			radius = radius,
			touchIndex = -1,
			playerIndex = playerIndex,
			data = VirtualStick{targetAxisX = axisX, targetAxisY = axisY, currentValue = 0},
		},
	)
}

addVirtualButton :: proc(
	position: gmath.Vector2,
	radius: f32,
	button: GamepadButton,
	playerIndex: uint = 0,
) {
	append(
		&_virtualControls,
		VirtualControl {
			position = position,
			radius = radius,
			touchIndex = -1,
			playerIndex = playerIndex,
			data = VirtualButton{target = button},
		},
	)
}

updateVirtualControls :: proc() {
	for touch in _inputState.touches {
		if touch.phase == .None || touch.phase == .Ended || touch.phase == .Cancelled {
			continue
		}

		for &control in _virtualControls {
			if control.touchIndex == -1 && _isTouchInside(touch.position, control) {
				control.touchIndex = touch.index
				_processControlLogic(&control, touch.position)
			}
		}
	}

	for &control in _virtualControls {
		if control.touchIndex == -1 do continue

		activeTouchIndex := -1
		for touch, index in _inputState.touches {
			if touch.index == control.touchIndex {
				activeTouchIndex = index
				break
			}
		}

		if activeTouchIndex != -1 {
			touch := _inputState.touches[activeTouchIndex]

			if touch.phase == .Ended || touch.phase == .Cancelled {
				_resetControl(&control)
			} else {
				_processControlLogic(&control, touch.position)
			}
		} else {
			_resetControl(&control)
		}
	}

	for &control in _virtualControls {
		if control.touchIndex != -1 {
			switch &data in control.data {
			case VirtualButton:
				_injectButton(control.playerIndex, data.target)
			case VirtualStick:
				_injectAxis(control.playerIndex, data.targetAxisX, data.currentValue.x)
				_injectAxis(control.playerIndex, data.targetAxisY, data.currentValue.y)
			}
		}
	}
}

drawTouchInterface :: proc() {
	for control in _virtualControls {
		switch &data in control.data {
		case VirtualButton:
			render.drawCircleLines(
				control.position,
				control.radius,
				isGamepadDown(int(control.playerIndex), data.target) ? gmath.Color{1, 1, 1, 0.8} : gmath.Color{1, 1, 1, 0.5},
			)
		case VirtualStick:
			render.drawCircleLines(control.position, control.radius, gmath.Color{1, 1, 1, 0.5})
			render.drawCircleLines(
				control.position + data.currentValue * control.radius / 5,
				control.radius * 0.8,
				gmath.Color{1, 1, 1, 0.75},
			)
		}
	}
}

updateTouchMouseEmulation :: proc() {
	if !TOUCH_EMULATE_MOUSE do return

	activeTouchIndex := -1

	for touch, index in _inputState.touches {
		if touch.phase == .None do continue

		isClaimed := false
		for control in _virtualControls {
			if control.touchIndex == touch.index {
				isClaimed = true
				break
			}
		}

		if !isClaimed {
			activeTouchIndex = index
			break
		}
	}

	if activeTouchIndex != -1 {
		_isTouchDrivingMouse = true

		touch := _inputState.touches[activeTouchIndex]
		_inputState.mousePosition = touch.position

		if touch.phase == TouchPhase.Began {
			_inputState.keys[KeyCode.LEFT_MOUSE] += {.down, .pressed}
		} else if touch.phase == TouchPhase.Ended {
			_inputState.keys[KeyCode.LEFT_MOUSE] += {.released}
			_inputState.keys[KeyCode.LEFT_MOUSE] -= {.down}
			_isTouchDrivingMouse = false
		}
	} else if _isTouchDrivingMouse {
		if .down in _inputState.keys[KeyCode.LEFT_MOUSE] {
			_inputState.keys[KeyCode.LEFT_MOUSE] += {.released}
			_inputState.keys[KeyCode.LEFT_MOUSE] -= {.down}
		}

		_isTouchDrivingMouse = false
	}
}

@(private = "file")
_processControlLogic :: proc(control: ^VirtualControl, touchPosition: gmath.Vector2) {
	switch &data in control.data {
	case VirtualButton:
	case VirtualStick:
		difference := touchPosition - control.position
		differenceLengthSquared := gmath.lengthSquared(difference)

		if differenceLengthSquared > control.radius * control.radius {
			difference = gmath.normalize(difference) * control.radius
		}

		data.currentValue = difference / control.radius
	}
}

@(private = "file")
_isTouchInside :: proc(position: gmath.Vector2, control: VirtualControl) -> bool {
	return gmath.distance(position, control.position) < control.radius
}

@(private = "file")
_injectButtonRelease :: proc(playerIndex: uint, targetButton: GamepadButton) {
	gamepadIndex := _players[playerIndex].gamepadIndex
	if gamepadIndex < 0 || gamepadIndex >= MAX_GAMEPADS do return

	keys := &_inputState.gamepadKeys[gamepadIndex][targetButton]

	if .down in keys^ {
		keys^ -= {.down}
		keys^ += {.released}
	}
}

@(private = "file")
_injectButton :: proc(playerIndex: uint, targetButton: GamepadButton) {
	gamepadIndex := _players[playerIndex].gamepadIndex
	if gamepadIndex < 0 || gamepadIndex >= MAX_GAMEPADS do return

	keys := &_inputState.gamepadKeys[gamepadIndex][targetButton]

	if .down not_in keys^ {
		keys^ += {.pressed}
	}

	keys^ += {.down}
}

@(private = "file")
_injectAxis :: proc(playerIndex: uint, targetAxis: GamepadAxis, axisValue: f32) {
	gamepadIndex := _players[playerIndex].gamepadIndex
	if gamepadIndex < 0 || gamepadIndex >= MAX_GAMEPADS do return

	_inputState.virtualAxisValues[gamepadIndex][targetAxis] = axisValue
}

@(private = "file")
_resetControl :: proc(control: ^VirtualControl) {
	control.touchIndex = -1
	switch &data in control.data {
	case VirtualStick:
		data.currentValue = gmath.Vector2{0, 0}
	case VirtualButton:
		_injectButtonRelease(control.playerIndex, data.target)
	}
}
