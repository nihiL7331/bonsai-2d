#+build linux

package input

import "bonsai:core/gmath"
import "bonsai:libs/evdev"
import "bonsai:libs/udev"

import "core:log"
import "core:os"
import "core:strings"
import "core:sys/linux"

Gamepad :: struct {
	fileDescriptor:         os.Handle,
	active:                 bool,
	name:                   string,
	axes:                   [GamepadAxis]GamepadAxisInfo,
	type:                   GamepadType,
	previousDpadHorizontal: i32,
	previousDpadVertical:   i32,
	hasRumbleSupport:       bool,
	rumbleEffectId:         u32,
}

GamepadType :: enum {
	Microsoft,
	Sony,
	Other,
}

GamepadState :: struct {
	gamepads:    [MAX_GAMEPADS]Gamepad,
	udevContext: udev.Context,
	udevMonitor: udev.Monitor,
}

GamepadAxisInfo :: struct {
	value:        f32,
	eventMinimum: i32,
	eventMaximum: i32,
}

@(private = "file")
_gamepadState: GamepadState

initGamepad :: proc() {
	createConnectedGamepads()

	_gamepadState.udevContext = udev.new()
	_gamepadState.udevMonitor = udev.createMonitor(_gamepadState.udevContext, "udev")


	if udev.addMonitorFilterMatch(_gamepadState.udevMonitor, "input", nil) < 0 {
		log.errorf("Failed to add match for monitor: %v", _gamepadState.udevMonitor)
		return
	}
	if udev.enableMonitorReceiving(_gamepadState.udevMonitor) < 0 {
		log.errorf("Failed to enable receiving for monitor: %v", _gamepadState.udevMonitor)
		return
	}
}

createGamepad :: proc(devicePath: string) -> (Gamepad, bool) {
	fileDescriptor, error := os.open(devicePath, os.O_RDWR | os.O_NONBLOCK)
	if error != os.ERROR_NONE {
		log.errorf("Failed creating gamepad for device: %v", devicePath)
		return {}, false
	}

	nameBuffer: [256]u8
	nameLength := linux.ioctl(
		linux.Fd(fileDescriptor),
		evdev.ioctlGetName(size_of(nameBuffer)),
		cast(uintptr)&nameBuffer,
	)
	name := "Unknown"
	if nameLength > 0 {
		length := int(nameLength)
		for i in 0 ..< length {
			if nameBuffer[i] == 0 {
				length = i
				break
			}
		}
		name = string(nameBuffer[:length])
	}

	type := GamepadType.Other
	if strings.contains(name, "Microsoft") || strings.contains(name, "Xbox") {
		type = GamepadType.Microsoft
	} else if strings.contains(name, "Sony") || strings.contains(name, "PlayStation") {
		type = GamepadType.Sony
	}

	gamepad := Gamepad {
		fileDescriptor = fileDescriptor,
		type           = type,
		name           = strings.clone(name),
		active         = true,
	}

	eventBits: [evdev.EV_MAX / (8 * size_of(u64)) + 1]u64
	linux.ioctl(
		linux.Fd(fileDescriptor),
		evdev.ioctlGetBit(0, size_of(eventBits)),
		cast(uintptr)&eventBits,
	)

	hasAnalogAxis := evdev.testBit(eventBits[:], evdev.EV_ABS)
	hasVibration := evdev.testBit(eventBits[:], evdev.EV_FF)

	log.debugf("New gamepad: %s", name)
	log.debugf("devicePath: '%s'", devicePath)
	log.debugf("hasButtons: '%t'", evdev.testBit(eventBits[:], evdev.EV_KEY))
	log.debugf("hasAnalogAxis: '%t'", hasAnalogAxis)
	log.debugf("hasVibration: '%t'", hasVibration)

	if hasAnalogAxis {
		absoluteBits: [evdev.EV_ABS / (8 * size_of(u64)) + 1]u64
		linux.ioctl(
			linux.Fd(fileDescriptor),
			evdev.ioctlGetBit(evdev.EV_ABS, size_of(absoluteBits)),
			cast(uintptr)&absoluteBits,
		)

		for i := u32(evdev.Axis.X); i <= u32(evdev.Axis.TOOL_WIDTH); i += 1 {
			if !evdev.testBit(absoluteBits[:], u64(i)) do continue

			axis := gamepadAxisFromEvdevAxis(evdev.Axis(i))

			if axis != GamepadAxis.None {
				absoluteInfo: evdev.InputAbsInfo
				linux.ioctl(
					linux.Fd(fileDescriptor),
					evdev.ioctlGetAbsInfo(u32(i)),
					cast(uintptr)&absoluteInfo,
				)
				gamepad.axes[axis] = {
					eventMinimum = absoluteInfo.minimum,
					eventMaximum = absoluteInfo.maximum,
				}
			}
		}
	}

	if hasVibration {
		ffBits: [evdev.FF_MAX / (8 * size_of(u64)) + 1]u64
		linux.ioctl(
			linux.Fd(fileDescriptor),
			evdev.ioctlGetBit(evdev.EV_FF, size_of(ffBits)),
			cast(uintptr)&ffBits,
		)

		hasRumbleEffect := evdev.testBit(ffBits[:], u64(evdev.FfEffectType.RUMBLE))
		if hasRumbleEffect {
			effect := evdev.FfEffect {
				type = evdev.FfEffectType.RUMBLE,
				id = -1,
				u = {rumble = {strongMagnitude = 0, weakMagnitude = 0}},
			}

			linux.ioctl(
				linux.Fd(fileDescriptor),
				evdev.ioctlSendForceFeedback(),
				cast(uintptr)&effect,
			)

			gamepad.rumbleEffectId = u32(effect.id)
			gamepad.hasRumbleSupport = true
		}
	}

	return gamepad, true
}

gamepadAxisFromEvdevAxis :: proc(evdevAxis: evdev.Axis) -> GamepadAxis {
	#partial switch evdevAxis {
	case .X:
		return .LeftStickX
	case .Y:
		return .LeftStickY
	case .RX:
		return .RightStickX
	case .RY:
		return .RightStickY
	case .Z:
		return .LeftTrigger
	case .RZ:
		return .RightTrigger
	}

	return .None
}

destroyGamepad :: proc(gamepad: ^Gamepad) {
	os.close(gamepad.fileDescriptor)
	delete(gamepad.name)
	gamepad.active = false
}

isGamepadActive :: proc(gamepad: int) -> bool {
	if gamepad < 0 || gamepad > len(_gamepadState.gamepads) - 1 || gamepad > MAX_GAMEPADS do return false

	return _gamepadState.gamepads[gamepad].active
}

microsoftButtonFromEvdevButton :: proc(button: evdev.Button) -> GamepadButton {
	#partial switch button {
	case .DPAD_UP:
		return .LeftFaceRight
	case .DPAD_DOWN:
		return .LeftFaceDown
	case .DPAD_LEFT:
		return .LeftFaceLeft
	case .DPAD_RIGHT:
		return .LeftFaceUp

	case .A:
		return .RightFaceDown
	case .B:
		return .RightFaceRight
	case .X:
		return .RightFaceLeft
	case .Y:
		return .RightFaceUp

	case .TL:
		return .LeftShoulder
	case .TL2:
		return .LeftTrigger
	case .TR:
		return .RightShoulder
	case .TR2:
		return .RightTrigger

	case .SELECT:
		return .MiddleFaceLeft
	case .MODE:
		return .MiddleFaceMiddle
	case .START:
		return .MiddleFaceRight
	case .THUMBL:
		return .LeftStickPress
	case .THUMBR:
		return .RightStickPress
	}

	return .None
}
sonyButtonFromEvdevButton :: proc(button: evdev.Button) -> GamepadButton {
	#partial switch button {
	case .DPAD_UP:
		return .LeftFaceRight
	case .DPAD_DOWN:
		return .LeftFaceDown
	case .DPAD_LEFT:
		return .LeftFaceLeft
	case .DPAD_RIGHT:
		return .LeftFaceUp

	case .A:
		return .RightFaceDown
	case .B:
		return .RightFaceRight
	case .X:
		return .RightFaceUp
	case .Y:
		return .RightFaceLeft

	case .TL:
		return .LeftShoulder
	case .TL2:
		return .LeftTrigger
	case .TR:
		return .RightShoulder
	case .TR2:
		return .RightTrigger

	case .SELECT:
		return .MiddleFaceLeft
	case .MODE:
		return .MiddleFaceMiddle
	case .START:
		return .MiddleFaceRight
	case .THUMBL:
		return .LeftStickPress
	case .THUMBR:
		return .RightStickPress
	}

	return .None
}

createConnectedGamepads :: proc() {
	fileDescriptor, error := os.open("/dev/input")
	if error != os.ERROR_NONE do return
	defer os.close(fileDescriptor)

	filesInformation, readError := os.read_dir(fileDescriptor, -1, context.temp_allocator)
	if readError != os.ERROR_NONE do return

	gamepadIndex := 0

	for fileInformation in filesInformation {
		if !strings.starts_with(fileInformation.name, "event") do continue
		if !evdev.isDeviceGamepad(fileInformation.fullpath) do continue
		if gamepadIndex >= MAX_GAMEPADS do break

		if gamepad, ok := createGamepad(fileInformation.fullpath); ok {
			log.infof("Created gamepad ID: %v", gamepadIndex)
			_gamepadState.gamepads[gamepadIndex] = gamepad
			gamepadIndex += 1
		}
	}
}

getGamepadEvents :: proc(events: ^[dynamic]GamepadEvent) {
	event: evdev.InputEvent
	eventBytes := ([^]u8)(&event)[:size_of(evdev.InputEvent)]

	for &gamepad, index in _gamepadState.gamepads {
		if !gamepad.active do continue

		for {
			readBytes, error := os.read(gamepad.fileDescriptor, eventBytes)

			if error == os.EAGAIN {
				break
			}

			if error != os.ERROR_NONE || (error == os.ERROR_NONE && readBytes == 0) {
				log.debugf("Gamepad disconnected (error: %v): %v", error, index)
				destroyGamepad(&gamepad)
				break
			}

			if readBytes != size_of(evdev.InputEvent) do break

			switch event.type {
			case evdev.EV_KEY:
				evdevButton := evdev.Button(event.code)
				button: GamepadButton

				switch gamepad.type {
				case .Microsoft:
					button = microsoftButtonFromEvdevButton(evdevButton)
				case .Sony:
					button = sonyButtonFromEvdevButton(evdevButton)
				case .Other:
					button = microsoftButtonFromEvdevButton(evdevButton)
				}

				if button != .None {
					#partial switch evdev.ButtonState(event.value) {
					case .Pressed:
						append(events, ButtonPressed{index = index, button = button})
					case .Released:
						append(events, ButtonReleased{index = index, button = button})
					}
				}
			case evdev.EV_ABS:
				evdevAxis := evdev.Axis(event.code)

				if evdevAxis == evdev.Axis.Z || evdevAxis == evdev.Axis.RZ {
					axis := gamepadAxisFromEvdevAxis(evdevAxis)

					minimum := f32(gamepad.axes[axis].eventMinimum)
					maximum := f32(gamepad.axes[axis].eventMaximum)
					value := gmath.remap(f32(event.value), minimum, maximum, 0.0, 1.0)

					if gamepad.type == GamepadType.Microsoft {
						previousValue := gamepad.axes[axis].value
						TRIGGER_THRESHOLD :: 0.001
						button: GamepadButton = evdevAxis == .Z ? .LeftTrigger : .RightTrigger

						if previousValue > TRIGGER_THRESHOLD && value <= TRIGGER_THRESHOLD {
							append(events, ButtonReleased{index = index, button = button})
						} else if previousValue <= TRIGGER_THRESHOLD && value > TRIGGER_THRESHOLD {
							append(events, ButtonPressed{index = index, button = button})
						}
					}

					gamepad.axes[axis].value = value
				} else if evdevAxis == evdev.Axis.HAT0X {
					if gamepad.previousDpadHorizontal != 0 &&
					   gamepad.previousDpadHorizontal != event.value {
						append(
							events,
							ButtonReleased {
								index = index,
								button = gamepad.previousDpadHorizontal == -1 ? .LeftFaceLeft : .LeftFaceRight,
							},
						)
					} else if event.value != 0 {
						append(
							events,
							ButtonPressed {
								index = index,
								button = event.value == -1 ? .LeftFaceLeft : .LeftFaceRight,
							},
						)
					}

					gamepad.previousDpadHorizontal = event.value
				} else if evdevAxis == .HAT0Y {
					if gamepad.previousDpadVertical != 0 &&
					   gamepad.previousDpadVertical != event.value {
						append(
							events,
							ButtonReleased {
								index = index,
								button = gamepad.previousDpadVertical == -1 ? .LeftFaceUp : .LeftFaceDown,
							},
						)
					} else if event.value != 0 {
						append(
							events,
							ButtonPressed {
								index = index,
								button = event.value == -1 ? .LeftFaceUp : .LeftFaceDown,
							},
						)
					}

					gamepad.previousDpadVertical = event.value
				} else {
					axis := gamepadAxisFromEvdevAxis(evdevAxis)

					if axis != .None {
						minimum := f32(gamepad.axes[axis].eventMinimum)
						maximum := f32(gamepad.axes[axis].eventMaximum)
						value := f32(event.value)
						gamepad.axes[axis].value = gmath.remap(
							value,
							minimum,
							maximum,
							f32(-1.0),
							f32(1.0),
						)
					}
				}
			}
		}
	}
}

getGamepadAxis :: proc(gamepadIndex: GamepadIndex, axis: GamepadAxis) -> f32 {
	if axis < min(GamepadAxis) || axis > max(GamepadAxis) do return 0
	if gamepadIndex < 0 || gamepadIndex >= MAX_GAMEPADS do return 0
	if !_gamepadState.gamepads[gamepadIndex].active do return 0

	return _gamepadState.gamepads[gamepadIndex].axes[axis].value
}

setGamepadVibration :: proc(gamepadIndex: GamepadIndex, left: f32, right: f32) {
	if gamepadIndex < 0 || gamepadIndex >= MAX_GAMEPADS do return

	gamepad := &_gamepadState.gamepads[gamepadIndex]

	if !gamepad.active || !gamepad.hasRumbleSupport do return

	effect := evdev.FfEffect {
		type = .RUMBLE,
		id = i16(gamepad.rumbleEffectId),
		direction = 0,
		trigger = {button = 0, interval = 0},
		replay = {length = 1000, delay = 0},
	}

	leftStrength := u16(gmath.clamp(left, 0, 1) * 0xFFFF)
	rightStrength := u16(gmath.clamp(right, 0, 1) * 0xFFFF)

	effect.rumble = evdev.FfRumbleEffect {
		strongMagnitude = leftStrength,
		weakMagnitude   = rightStrength,
	}

	linux.ioctl(
		linux.Fd(gamepad.fileDescriptor),
		evdev.ioctlSendForceFeedback(),
		cast(uintptr)&effect,
	)

	playEvent := evdev.InputEvent {
		type  = evdev.EV_FF,
		code  = u16(gamepad.rumbleEffectId),
		value = 1,
	}

	playBytes := ([^]u8)(&playEvent)[:size_of(evdev.InputEvent)]
	os.write(gamepad.fileDescriptor, playBytes)
}
