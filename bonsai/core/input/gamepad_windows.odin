#+build windows

package input

import "core:sys/windows"

XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE :: 7849
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689
XINPUT_GAMEPAD_TRIGGER_THRESHOLD :: 30

initGamepad :: proc() {
	windows.XInputEnable(true)
}

getGamepadEvents :: proc(events: ^[dynamic]GamepadEvent) {
	for gamepad in 0 ..< 4 {
		gamepadEvent: windows.XINPUT_KEYSTROKE

		for windows.XInputGetKeystroke(windows.XUSER(gamepad), 0, &gamepadEvent) == .SUCCESS {
			button: Maybe(GamepadButton)

			#partial switch gamepadEvent.VirtualKey {
			case .DPAD_UP:
				button = .LeftFaceUp
			case .DPAD_DOWN:
				button = .LeftFaceDown
			case .DPAD_LEFT:
				button = .LeftFaceLeft
			case .DPAD_RIGHT:
				button = .LeftFaceRight

			case .Y:
				button = .RightFaceUp
			case .A:
				button = .RightFaceDown
			case .X:
				button = .RightFaceLeft
			case .B:
				button = .RightFaceRight

			case .LSHOULDER:
				button = .LeftShoulder
			case .LTRIGGER:
				button = .LeftTrigger

			case .RSHOULDER:
				button = .RightShoulder
			case .RTRIGGER:
				button = .RightTrigger

			case .BACK:
				button = .MiddleFaceLeft
			case .START:
				button = .MiddleFaceRight
			case .LTHUMB_PRESS:
				button = .LeftStickPress
			case .RTHUMB_PRESS:
				button = .RightStickPress
			}

			buttonValue := button.? or_continue

			if .KEYDOWN in gamepadEvent.Flags {
				append(events, ButtonPressed{index = gamepad, button = buttonValue})
			} else if .KEYUP in gamepadEvent.Flags {
				append(events, ButtonReleased{index = gamepad, button = buttonValue})
			}
		}
	}
}

isGamepadActive :: proc(gamepadIndex: int) -> bool {
	if gamepadIndex < 0 || gamepadIndex >= 4 do return false

	gamepadState: windows.XINPUT_STATE
	return windows.XInputGetState(windows.XUSER(gamepadIndex), &gamepadState) == .SUCCESS
}

getGamepadAxis :: proc(gamepadIndex: int, axis: GamepadAxis) -> f32 {
	if gamepadIndex < 0 || gamepadIndex >= 4 do return 0

	gamepadState: windows.XINPUT_STATE
	if windows.XInputGetState(windows.XUSER(gamepadIndex), &gamepadState) == .SUCCESS {
		gamepad := gamepadState.Gamepad

		STICK_MAX :: 32767
		TRIGGER_MAX :: 255

		applyDeadzone :: proc(val: i16, deadzone: i16) -> f32 {
			if abs(val) < deadzone do return 0
			return f32(val) / STICK_MAX
		}

		switch axis {
		case .None:
			return 0
		case .LeftStickX:
			return applyDeadzone(gamepad.sThumbLX, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
		case .LeftStickY:
			return applyDeadzone(gamepad.sThumbLY, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
		case .RightStickX:
			return applyDeadzone(gamepad.sThumbRX, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
		case .RightStickY:
			return applyDeadzone(gamepad.sThumbRY, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
		case .LeftTrigger:
			if gamepad.bLeftTrigger < XINPUT_GAMEPAD_TRIGGER_THRESHOLD do return 0
			return f32(gamepad.bLeftTrigger) / TRIGGER_MAX
		case .RightTrigger:
			if gamepad.bRightTrigger < XINPUT_GAMEPAD_TRIGGER_THRESHOLD do return 0
			return f32(gamepad.bRightTrigger) / TRIGGER_MAX
		}
	}
	return 0
}

setGamepadVibration :: proc(gamepadIndex: int, left: f32, right: f32) {
	if gamepadIndex < 0 || gamepadIndex >= 4 do return

	vibration := windows.XINPUT_VIBRATION {
		wLeftMotorSpeed  = windows.WORD(clamp(left, 0, 1) * 65535),
		wRightMotorSpeed = windows.WORD(clamp(right, 0, 1) * 65535),
	}

	windows.XInputSetState(windows.XUSER(gamepadIndex), &vibration)
}
