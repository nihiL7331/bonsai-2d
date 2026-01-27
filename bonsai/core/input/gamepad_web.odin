#+build wasm32, wasm64p32

package input

GamepadState :: struct {
	previousButtonState: [4][GamepadButton]bool,
}

@(private = "file")
_gamepadState: GamepadState

foreign import "js"
foreign js {
	js_is_gamepad_connected :: proc "contextless" (gamepad_index: i32) -> b32 ---
	js_get_gamepad_button :: proc "contextless" (gamepad_index: i32, button_index: i32) -> b32 ---
	js_get_gamepad_axis :: proc "contextless" (gamepad_index: i32, axis_index: i32) -> f32 ---
	js_set_gamepad_vibration :: proc "contextless" (gamepad_index: i32, duration: f32, weak: f32, strong: f32) ---
}

initGamepad :: proc() {

}

getGamepadEvents :: proc(events: ^[dynamic]GamepadEvent) {
	for gamepadIndex in 0 ..< 4 {
		if !js_is_gamepad_connected(i32(gamepadIndex)) do continue

		for button in GamepadButton {
			if button == .None || button == .Count do continue

			w3cIndex := getW3CButtonIndex(button)
			if w3cIndex == -1 do continue

			isPressed := bool(js_get_gamepad_button(i32(gamepadIndex), i32(w3cIndex)))
			wasPressed := _gamepadState.previousButtonState[gamepadIndex][button]

			if isPressed && !wasPressed {
				append(events, ButtonPressed{index = gamepadIndex, button = button})
			} else if !isPressed && wasPressed {
				append(events, ButtonReleased{index = gamepadIndex, button = button})
			}

			_gamepadState.previousButtonState[gamepadIndex][button] = isPressed
		}
	}
}

isGamepadActive :: proc(gamepadIndex: int) -> bool {
	if gamepadIndex < 0 || gamepadIndex >= 4 do return false
	return bool(js_is_gamepad_connected(i32(gamepadIndex)))
}

getGamepadAxis :: proc(gamepadIndex: int, axis: GamepadAxis) -> f32 {
	if gamepadIndex < 0 || gamepadIndex >= 4 do return 0

	index := i32(gamepadIndex)

	switch axis {
	case .None:
		return 0
	case .LeftStickX:
		return js_get_gamepad_axis(index, 0)
	case .LeftStickY:
		return js_get_gamepad_axis(index, 1)
	case .RightStickX:
		return js_get_gamepad_axis(index, 2)
	case .RightStickY:
		return js_get_gamepad_axis(index, 3)
	case .LeftTrigger:
		return js_get_gamepad_axis(index, 6) // see JS implementation below
	case .RightTrigger:
		return js_get_gamepad_axis(index, 7)
	}
	return 0
}

setGamepadVibration :: proc(gamepadIndex: int, left: f32, right: f32) {
	if gamepadIndex < 0 || gamepadIndex >= 4 do return

	js_set_gamepad_vibration(i32(gamepadIndex), 1000.0, left, right)
}

getW3CButtonIndex :: proc(button: GamepadButton) -> int {
	switch button {
	case .None:
		return -1
	case .RightFaceDown:
		return 0
	case .RightFaceRight:
		return 1
	case .RightFaceLeft:
		return 2
	case .RightFaceUp:
		return 3
	case .LeftShoulder:
		return 4
	case .RightShoulder:
		return 5
	case .LeftTrigger:
		return 6
	case .RightTrigger:
		return 7
	case .MiddleFaceLeft:
		return 8
	case .MiddleFaceRight:
		return 9
	case .LeftStickPress:
		return 10
	case .RightStickPress:
		return 11
	case .LeftFaceUp:
		return 12
	case .LeftFaceDown:
		return 13
	case .LeftFaceLeft:
		return 14
	case .LeftFaceRight:
		return 15
	case .MiddleFaceMiddle:
		return 16
	case .Count:
		return -1
	}
	return -1
}
