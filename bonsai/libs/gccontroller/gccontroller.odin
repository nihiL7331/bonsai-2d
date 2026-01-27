#+build darwin

package gccontroller

import "base:intrinsics"
import foundation "core:sys/darwin/Foundation"

@(private = "file")
messageSend :: intrinsics.objc_send

foreign import GameController "system:GameController.framework"

@(link_prefix = "GCController")
foreign GameController {
	DidConnectNotification: ^foundation.String
	DidDisconnectNotification: ^foundation.String
}

HapticsLocality :: ^foundation.String

@(link_prefix = "GCHapticsLocality")
foreign GameController {
	Default: HapticsLocality
	All: HapticsLocality
	Handles: HapticsLocality
	LeftHandle: HapticsLocality
	RightHandle: HapticsLocality
	Triggers: HapticsLocality
	LeftTrigger: HapticsLocality
	RightTrigger: HapticsLocality
}

HapticDurationInfinite: f64 : 1e300

ControllerPlayerIndexUnset :: foundation.Integer(-1)

@(objc_class = "ControllerArray")
ControllerArray :: struct {
	using _: foundation.Object,
}

@(objc_type = ControllerArray, objc_name = "object")
ControllerArrayObject :: proc "c" (
	self: ^ControllerArray,
	index: foundation.UInteger,
) -> ^Controller {
	return messageSend(^Controller, self, "objectAtIndexedSubscript:", index)
}

@(objc_type = ControllerArray, objc_name = "count")
ControllerArrayCount :: proc "c" (self: ^ControllerArray) -> foundation.UInteger {
	return messageSend(foundation.UInteger, self, "count")
}

@(objc_class = "GCController")
Controller :: struct {
	using _: foundation.Object,
}

@(objc_type = Controller, objc_name = "controllers", objc_is_class_method = true)
ControllerControllers :: proc "c" () -> ^ControllerArray {
	return messageSend(^ControllerArray, Controller, "controllers")
}

@(objc_type = Controller, objc_name = "startWirelessControllerDiscovery", objc_is_class_method = true)
ControllerStartWirelessControllerDiscovery :: proc "c" (completionHandler: rawptr = nil) {
	messageSend(
		nil,
		Controller,
		"startWirelessControllerDiscoveryWithCompletionHandler:",
		completionHandler,
	)
}

@(objc_type = Controller, objc_name = "stopWirelessControllerDiscovery", objc_is_class_method = true)
ControllerStopWirelessControllerDiscovery :: proc "c" () {
	messageSend(nil, Controller, "stopWirelessControllerDiscovery")
}

@(objc_type = Controller, objc_name = "extendedGamepad")
ControllerExtendedGamepad :: proc "c" (self: ^Controller) -> ^ExtendedGamepad {
	return messageSend(^ExtendedGamepad, self, "extendedGamepad")
}

@(objc_type = Controller, objc_name = "playerIndex")
ControllerPlayerIndex :: proc "c" (self: ^Controller) -> foundation.Integer {
	return messageSend(foundation.Integer, self, "playerIndex")
}

@(objc_type = Controller, objc_name = "setPlayerIndex")
ControllerSetPlayerIndex :: proc "c" (self: ^Controller, index: foundation.Integer) {
	messageSend(nil, self, "setPlayerIndex:", index)
}

@(objc_type = Controller, objc_name = "vendorName")
ControllerVendorName :: proc "c" (self: ^Controller) -> ^foundation.String {
	return messageSend(^foundation.String, self, "vendorName")
}

@(objc_class = "GCExtendedGamepad")
ExtendedGamepad :: struct {
	using _: foundation.Object,
}

@(objc_type = ExtendedGamepad, objc_name = "leftThumbstick")
ExtendedGamepadLeftThumbstick :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerDirectionPad {
	return messageSend(^ControllerDirectionPad, self, "leftThumbstick")
}

@(objc_type = ExtendedGamepad, objc_name = "rightThumbstick")
ExtendedGamepadRightThumbstick :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerDirectionPad {
	return messageSend(^ControllerDirectionPad, self, "rightThumbstick")
}

@(objc_type = ExtendedGamepad, objc_name = "dpad")
ExtendedGamepadDpad :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerDirectionPad {
	return messageSend(^ControllerDirectionPad, self, "dpad")
}

@(objc_type = ExtendedGamepad, objc_name = "buttonA")
ExtendedGamepadButtonA :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "buttonA")
}

@(objc_type = ExtendedGamepad, objc_name = "buttonB")
ExtendedGamepadButtonB :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "buttonB")
}

@(objc_type = ExtendedGamepad, objc_name = "buttonX")
ExtendedGamepadButtonX :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "buttonX")
}

@(objc_type = ExtendedGamepad, objc_name = "buttonY")
ExtendedGamepadButtonY :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "buttonY")
}

@(objc_type = ExtendedGamepad, objc_name = "leftShoulder")
ExtendedGamepadLeftShoulder :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "leftShoulder")
}

@(objc_type = ExtendedGamepad, objc_name = "rightShoulder")
ExtendedGamepadRightShoulder :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "rightShoulder")
}

@(objc_type = ExtendedGamepad, objc_name = "leftTrigger")
ExtendedGamepadLeftTrigger :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "leftTrigger")
}

@(objc_type = ExtendedGamepad, objc_name = "rightTrigger")
ExtendedGamepadRightTrigger :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "rightTrigger")
}

@(objc_type = ExtendedGamepad, objc_name = "buttonMenu")
ExtendedGamepadButtonMenu :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "buttonMenu")
}

@(objc_type = ExtendedGamepad, objc_name = "buttonOptions")
ExtendedGamepad_buttonOptions :: proc "c" (self: ^ExtendedGamepad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "buttonOptions")
}

@(objc_type = ExtendedGamepad, objc_name = "leftThumbstickButton")
ExtendedGamepadLeftThumbstickButton :: proc "c" (
	self: ^ExtendedGamepad,
) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "leftThumbstickButton")
}

@(objc_type = ExtendedGamepad, objc_name = "rightThumbstickButton")
ExtendedGamepadRightThumbstickButton :: proc "c" (
	self: ^ExtendedGamepad,
) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "rightThumbstickButton")
}

@(objc_class = "GCControllerDirectionPad")
ControllerDirectionPad :: struct {
	using _: foundation.Object,
}

@(objc_type = ControllerDirectionPad, objc_name = "xAxis")
ControllerDirectionPadXAxis :: proc "c" (self: ^ControllerDirectionPad) -> ^ControllerAxisInput {
	return messageSend(^ControllerAxisInput, self, "xAxis")
}

@(objc_type = ControllerDirectionPad, objc_name = "yAxis")
ControllerDirectionPadYAxis :: proc "c" (self: ^ControllerDirectionPad) -> ^ControllerAxisInput {
	return messageSend(^ControllerAxisInput, self, "yAxis")
}

@(objc_type = ControllerDirectionPad, objc_name = "up")
ControllerDirectionPadUp :: proc "c" (self: ^ControllerDirectionPad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "up")
}

@(objc_type = ControllerDirectionPad, objc_name = "down")
ControllerDirectionPadDown :: proc "c" (self: ^ControllerDirectionPad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "down")
}

@(objc_type = ControllerDirectionPad, objc_name = "left")
ControllerDirectionPadLeft :: proc "c" (self: ^ControllerDirectionPad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "left")
}

@(objc_type = ControllerDirectionPad, objc_name = "right")
ControllerDirectionPadRight :: proc "c" (self: ^ControllerDirectionPad) -> ^ControllerButtonInput {
	return messageSend(^ControllerButtonInput, self, "right")
}

@(objc_class = "GCControllerAxisInput")
ControllerAxisInput :: struct {
	using _: foundation.Object,
}

@(objc_type = ControllerAxisInput, objc_name = "value")
ControllerAxisInputValue :: proc "c" (self: ^ControllerAxisInput) -> f32 {
	return messageSend(f32, self, "value")
}

@(objc_class = "GCControllerButtonInput")
ControllerButtonInput :: struct {
	using _: foundation.Object,
}

@(objc_type = ControllerButtonInput, objc_name = "isPressed")
ControllerButtonInputIsPressed :: proc "c" (self: ^ControllerButtonInput) -> bool {
	return messageSend(foundation.BOOL, self, "isPressed")
}

@(objc_type = ControllerButtonInput, objc_name = "value")
ControllerButtonInputValue :: proc "c" (self: ^ControllerButtonInput) -> f32 {
	return messageSend(f32, self, "value")
}

@(objc_type = ControllerButtonInput, objc_name = "isTouched")
ControllerButtonInputIsTouched :: proc "c" (self: ^ControllerButtonInput) -> bool {
	return messageSend(foundation.BOOL, self, "isTouched")
}

when ODIN_MINIMUM_OS_VERSION >= 11_00_00 {
	@(objc_type = Controller, objc_name = "haptics")
	ControllerHaptics :: proc "c" (self: ^Controller) -> rawptr {
		return messageSend(rawptr, self, "haptics")
	}
}
