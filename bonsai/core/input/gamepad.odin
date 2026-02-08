package input

// @ref
// The maximum number of supported concurrent gamepads.
// Default is 4, being in line with the maximum limit for
// **Windows** and **Web**.
MAX_GAMEPADS :: 4

// @ref
// Unique identifier for a connected gamepad.
GamepadIndex :: int

// @ref
// Standard analog axes for a dual-stick controller.
GamepadAxis :: enum {
	None,
	LeftStickX,
	LeftStickY,
	RightStickX,
	RightStickY,
	LeftTrigger,
	RightTrigger,
}

// @ref
// Standard physical buttons for a modern controller.
//
// :::note
// Aliases are provided for common "Face" directions.
// :::
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
}

// @ref
// Alias for [`RightFaceDown`](#gamepadbutton) gamepad button (equivalent of "A" on XBOX controllers and "X" on PS controllers).
FACE_DOWN :: GamepadButton.RightFaceDown
// @ref
// Alias for [`RightFaceRight`](#gamepadbutton) gamepad button (equivalent of "B" on XBOX controllers and "○" on PS controllers).
FACE_RIGHT :: GamepadButton.RightFaceRight
// @ref
// Alias for [`RightFaceLeft`](#gamepadbutton) gamepad button (equivalent of "X" on XBOX controllers and "□" on PS controllers).
FACE_LEFT :: GamepadButton.RightFaceLeft
// @ref
// Alias for [`RightFaceUp`](#gamepadbutton) gamepad button (equivalent of "Y" on XBOX controllers and "∆" on PS controllers).
FACE_UP :: GamepadButton.RightFaceUp
// @ref
// Alias for [`LeftFaceDown`](#gamepadbutton) gamepad button.
DPAD_DOWN :: GamepadButton.LeftFaceDown
// @ref
// Alias for [`LeftFaceRight`](#gamepadbutton) gamepad button.
DPAD_RIGHT :: GamepadButton.LeftFaceRight
// @ref
// Alias for [`LeftFaceLeft`](#gamepadbutton) gamepad button.
DPAD_LEFT :: GamepadButton.LeftFaceLeft
// @ref
// Alias for [`LeftFaceUp`](#gamepadbutton) gamepad button.
DPAD_UP :: GamepadButton.LeftFaceUp
// @ref
// Alias for [`MiddleFaceRight`](#gamepadbutton) gamepad button.
START :: GamepadButton.MiddleFaceRight
// @ref
// Alias for [`MiddleFaceLeft`](#gamepadbutton) gamepad button.
SELECT :: GamepadButton.MiddleFaceLeft

// @ref
// Union representing a state change event for a gamepad.
GamepadEvent :: union {
	ButtonPressed,
	ButtonReleased,
}

// @ref
// Event payload when a button is pressed down.
ButtonPressed :: struct {
	index:  GamepadIndex,
	button: GamepadButton,
}

// @ref
// Event payload when a button is released.
ButtonReleased :: struct {
	index:  GamepadIndex,
	button: GamepadButton,
}

// Polls the hardware for new events and updates the internal state.
// Called internally by main.odin
updateGamepads :: proc() {
	when ODIN_OS == .Darwin {
		platformUpdateGamepads()
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

	updateVirtualControls()
	updateTouchMouseEmulation()
}

// @ref
// Checks if a [`GamepadButton`](#gamepadbutton) was **pressed** this frame.
isGamepadPressed :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false
	return .pressed in _inputState.gamepadKeys[index][button]
}

// @ref
// Checks if a [`GamepadButton`](#gamepadbutton) is currently **held down**.
isGamepadDown :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false
	return .down in _inputState.gamepadKeys[index][button]
}

// @ref
// Checks if a [`GamepadButton`](#gamepadbutton) was **released** this frame.
isGamepadReleased :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false
	return .released in _inputState.gamepadKeys[index][button]
}

// @ref
// Manually consumes a **pressed** event.
// Returns `true` if the state was successfully changed.
consumeGamepadPressed :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	if .pressed in _inputState.gamepadKeys[index][button] {
		_inputState.gamepadKeys[index][button] -= {.pressed}
		return true
	}
	return false
}

// @ref
// Manually consumes a **released** event.
// Returns `true` if the state was successfully changed.
consumeGamepadReleased :: proc(index: GamepadIndex, button: GamepadButton) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	if .released in _inputState.gamepadKeys[index][button] {
		_inputState.gamepadKeys[index][button] -= {.released}
		return true
	}
	return false
}

// @ref
// Checks if **any** button on a specific gamepad (or all gamepads if the argument isn't provided) was pressed.
// :::tip
// Useful for "Press X to Join" logic.
// :::
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
