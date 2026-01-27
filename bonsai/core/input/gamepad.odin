package input

MAX_GAMEPADS :: 4

GamepadIndex :: int

GamepadAxis :: enum {
	None,
	LeftStickX,
	LeftStickY,
	RightStickX,
	RightStickY,
	LeftTrigger,
	RightTrigger,
}

GamepadButton :: enum {
	None,
	LeftFaceUp,
	LeftFaceDown,
	LeftFaceLeft,
	LeftFaceRight,
	RightFaceUp,
	RightFaceDown,
	RightFaceLeft,
	RightFaceRight,
	LeftShoulder,
	LeftTrigger,
	RightShoulder,
	RightTrigger,
	LeftStickPress,
	RightStickPress,
	MiddleFaceLeft,
	MiddleFaceMiddle,
	MiddleFaceRight,
	Count,
}

GamepadEvent :: union {
	ButtonPressed,
	ButtonReleased,
}

ButtonPressed :: struct {
	index:  GamepadIndex,
	button: GamepadButton,
}

ButtonReleased :: struct {
	index:  GamepadIndex,
	button: GamepadButton,
}

updateGamepads :: proc() {
	when ODIN_OS == .Darwin {
		pollForNewControllers()
	}

	for &gamepad in _inputState.gamepadKeys {
		for &buttonState in gamepad {
			buttonState -= {.pressed, .released}
		}
	}

	@(static) events: [dynamic]GamepadEvent
	clear(&events)
	getGamepadEvents(&events)

	for event in events {
		switch e in event {
		case ButtonPressed:
			_inputState.gamepadKeys[e.index][e.button] += {.down, .pressed}
		case ButtonReleased:
			_inputState.gamepadKeys[e.index][e.button] -= {.down}
			_inputState.gamepadKeys[e.index][e.button] += {.released}
		}
	}
}

isGamepadPressed :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false
	return .pressed in _inputState.gamepadKeys[index][button]
}

isGamepadDown :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false
	return .down in _inputState.gamepadKeys[index][button]
}

isGamepadReleased :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false
	return .released in _inputState.gamepadKeys[index][button]
}

consumeGamepadPressed :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	if .pressed in _inputState.gamepadKeys[index][button] {
		_inputState.gamepadKeys[index][button] -= {.pressed}
		return true
	}
	return false
}

consumeAnyGamepadPress :: proc(index: GamepadIndex = -1) -> bool {
	if index != -1 {
		if index < 0 || index >= MAX_GAMEPADS do return false

		for &flag in _inputState.gamepadKeys[index] {
			if .pressed in flag {
				flag -= {.pressed}
				return true
			}
		}

		return false
	} else {
		for i in 0 ..< MAX_GAMEPADS {
			if consumeAnyGamepadPress(i) do return true
		}
	}

	return false
}
