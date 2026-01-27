#+build linux

package evdev

import "core:c"
import "core:os"
import "core:sys/linux"

@(private = "file")
_IOC_WRITE :: 1
@(private = "file")
_IOC_READ :: 2
@(private = "file")
_IOC_NRSHIFT :: 0
@(private = "file")
_IOC_TYPESHIFT :: (_IOC_NRSHIFT + _IOC_NRBITS)
@(private = "file")
_IOC_SIZESHIFT :: (_IOC_TYPESHIFT + _IOC_TYPEBITS)
@(private = "file")
_IOC_DIRSHIFT :: (_IOC_SIZESHIFT + _IOC_SIZEBITS)

@(private = "file")
_IOC_NRBITS :: 8
@(private = "file")
_IOC_TYPEBITS :: 8
@(private = "file")
_IOC_SIZEBITS :: 14

@(private = "file")
_iocEncode :: proc(dir: u32, type: u32, nr: u32, size: u32) -> u32 {
	return(
		((dir) << _IOC_DIRSHIFT) |
		((type) << _IOC_TYPESHIFT) |
		((nr) << _IOC_NRSHIFT) |
		((size) << _IOC_SIZESHIFT) \
	)
}

ioctlGetName :: proc(length: u32) -> u32 {
	return _iocEncode(_IOC_READ, u32('E'), 0x06, length)
}

ioctlGetBit :: proc(event: u32, length: u32) -> u32 {
	return _iocEncode(_IOC_READ, u32('E'), 0x20 + event, length)
}

ioctlGetAbsInfo :: proc(absoluteAxis: u32) -> u32 {
	return _iocEncode(_IOC_READ, u32('E'), 0x40 + absoluteAxis, size_of(InputAbsInfo))
}

ioctlSendForceFeedback :: proc() -> u32 {
	return _iocEncode(_IOC_WRITE, u32('E'), 0x80, size_of(FfEffect))
}

ioctlRemoveForceFeedback :: proc(id: u32) -> u32 {
	return _iocEncode(_IOC_WRITE, u32('E'), 0x81, size_of(c.int))
}

EV_SYN :: 0x00
EV_KEY :: 0x01
EV_ABS :: 0x03
EV_REL :: 0x02
EV_MSC :: 0x04
EV_SW :: 0x05
EV_LED :: 0x11
EV_SND :: 0x12
EV_REP :: 0x14
EV_FF :: 0x15
EV_PWR :: 0x16
EV_FF_STATUS :: 0x17
EV_MAX :: 0x1f
EV_CNT :: (EV_MAX + 1)

KEY_MAX :: 0x2ff
ABS_MAX :: 0x3f
FF_MAX :: 0x7f

BTN_GAMEPAD :: 0x130

Button :: enum u32 {
	A          = BTN_GAMEPAD,
	B          = BTN_GAMEPAD + 1,
	C          = BTN_GAMEPAD + 2,
	X          = BTN_GAMEPAD + 3,
	Y          = BTN_GAMEPAD + 4,
	Z          = BTN_GAMEPAD + 5,
	TL         = BTN_GAMEPAD + 6,
	TR         = BTN_GAMEPAD + 7,
	TL2        = BTN_GAMEPAD + 8,
	TR2        = BTN_GAMEPAD + 9,
	SELECT     = BTN_GAMEPAD + 10,
	START      = BTN_GAMEPAD + 11,
	MODE       = BTN_GAMEPAD + 12,
	THUMBL     = BTN_GAMEPAD + 13,
	THUMBR     = BTN_GAMEPAD + 14,
	DPAD_UP    = 0x220,
	DPAD_DOWN  = 0x221,
	DPAD_LEFT  = 0x222,
	DPAD_RIGHT = 0x223,
}

FfEffectType :: enum u16 {
	RUMBLE   = 0x50,
	PERIODIC = 0x51,
	CONSTANT = 0x52,
	SPRING   = 0x53,
	FRICTION = 0x54,
	DAMPER   = 0x55,
	INERTIA  = 0x56,
	RAMP     = 0x57,
}

InputEvent :: struct {
	time:  linux.Time_Val,
	type:  u16,
	code:  u16,
	value: c.int,
}


InputAbsInfo :: struct {
	value:      i32,
	minimum:    i32,
	maximum:    i32,
	fuzz:       i32,
	flat:       i32,
	resolution: i32,
}

FfEffect :: struct {
	type:      FfEffectType,
	id:        i16,
	direction: u16,
	trigger:   FfTrigger,
	replay:    FfReplay,
	using u:   struct #raw_union {
		rumble:   FfRumbleEffect,
		periodic: FfPeriodicEffect,
	},
}

FfReplay :: struct {
	length: u16,
	delay:  u16,
}

FfTrigger :: struct {
	button:   u16,
	interval: u16,
}

FfRumbleEffect :: struct {
	strongMagnitude: u16,
	weakMagnitude:   u16,
}

FfPeriodicEffect :: struct {
	waveform:     u16,
	period:       u16,
	magnitude:    i16,
	offset:       i16,
	phase:        u16,
	envelope:     [4]u16,
	customLength: u32,
	customData:   ^i16,
}

ButtonState :: enum u32 {
	Released,
	Pressed,
	Repeated,
}

Axis :: enum u32 {
	X          = 0x00,
	Y          = 0x01,
	Z          = 0x02,
	RX         = 0x03,
	RY         = 0x04,
	RZ         = 0x05,
	THROTTLE   = 0x06,
	RUDDER     = 0x07,
	WHEEL      = 0x08,
	GAS        = 0x09,
	BRAKE      = 0x0a,
	HAT0X      = 0x10,
	HAT0Y      = 0x11,
	HAT1X      = 0x12,
	HAT1Y      = 0x13,
	HAT2X      = 0x14,
	HAT2Y      = 0x15,
	HAT3X      = 0x16,
	HAT3Y      = 0x17,
	PRESSURE   = 0x18,
	DISTANCE   = 0x19,
	TILT_X     = 0x1a,
	TILT_Y     = 0x1b,
	TOOL_WIDTH = 0x1c,
}

testBit :: proc(bits: []u64, bit: u64) -> bool {
	wordBits: u64 = size_of(u64) * 8
	index := bit / wordBits
	position := bit % wordBits

	return (bits[index] & (1 << position)) != 0
}

isDeviceGamepad :: proc(path: string) -> bool {
	fileDescriptor, err := os.open(path, os.O_RDONLY | os.O_NONBLOCK)
	if err != nil {
		return false
	}
	defer os.close(fileDescriptor)

	keyBits: [KEY_MAX / (8 * size_of(u64)) + 1]u64
	linux.ioctl(
		linux.Fd(fileDescriptor),
		ioctlGetBit(EV_KEY, size_of(keyBits)),
		cast(uintptr)&keyBits,
	)
	return testBit(keyBits[:], u64(BTN_GAMEPAD))
}
