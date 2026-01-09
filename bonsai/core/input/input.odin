package input

// @overview
// This package manages user input across keyboard and mouse devices (gamepad WIP).
// It supports both raw key polling and an abstract `Action` system for remappable key controls.
//
// **Features:**
// - **Action system:** Maps physical keys to logical `InputAction` enums, allowing for
//   easy control remapping and clean game logic code.
// - **Input consumption:** `consume` functions (e.g. `consumeKeyPressed`) that make single-frame events easy.
// - **Mouse utilities:** Helpers for easy usage of the mouse inputs (`getMousePosition`, `getScrollY`)
// - **Key reading:** Direct access to key states via `isKeyDown`, `isKeyPressed` and `isKeyReleased`.
// - **Cursor control:** Functions to lock or hide the system cursor (`setCursorLocked`, `setCursorVisible`) **(Desktop only)**
//
// **Usage:**
// ```Odin
// update :: proc() {
//   // ...
//   pot.position += input.getInputVector() * speed * deltaTime
//
//   if input.isKeyPressed(.LEFT_MOUSE) {
//     mousePosition := input.getMousePosition()
//     potTeleport(mousePosition)
//     input.consumeKeyPressed(.LEFT_MOUSE)
//   }
// }
// ```

import "bonsai:core"
import "bonsai:core/gmath"
import "bonsai:core/render"
import sokol_app "bonsai:libs/sokol/app"

// internal capacity for the input buffer
@(private = "file")
_KEY_CODE_CAPACITY :: 512

// @ref
// Configuration constant for touch support. If set to `true`,
// makes each touch (0-index) emulate a mouse click.
TOUCH_EMULATE_MOUSE :: true

@(private = "file")
_inputState: Input

// @ref
// Main container for the **current frame**'s input state.
Input :: struct {
	keys:          [_KEY_CODE_CAPACITY]bit_set[InputFlag], //bitset of 4 bits (down, pressed, released, repeat)
	mousePosition: gmath.Vector2,
	mouseScroll:   gmath.Vector2,
}

// @ref
// Bit flags representing the state of a specific **key** or **button** in the **current frame**.
InputFlag :: enum u8 {
	down, // Key is currently held down
	pressed, // Key was pressed this frame
	released, // Key was released this frame
	repeat, // Key is being held (repeating event)
}

// @ref
// Default mapping of **abstract game actions** to **physical** keys.
// This can be modified at runtime to support **key re-binding**.
actionMap: [InputAction]KeyCode = {
	.left  = .A,
	.right = .D,
	.up    = .W,
	.down  = .S,
	// add more if needed
}

// @ref
// **Abstract** actions that decouple game logic from specific **physical** keys.
InputAction :: enum u8 {
	left,
	right,
	up,
	down,
	// add more if needed
}

// @ref
// **Physical** key codes (Stripped from **Sokol**), but with included **mouse buttons**.
KeyCode :: enum {
	INVALID       = 0,
	SPACE         = 32,
	APOSTROPHE    = 39,
	COMMA         = 44,
	MINUS         = 45,
	PERIOD        = 46,
	SLASH         = 47,
	_0            = 48,
	_1            = 49,
	_2            = 50,
	_3            = 51,
	_4            = 52,
	_5            = 53,
	_6            = 54,
	_7            = 55,
	_8            = 56,
	_9            = 57,
	SEMICOLON     = 59,
	EQUAL         = 61,
	A             = 65,
	B             = 66,
	C             = 67,
	D             = 68,
	E             = 69,
	F             = 70,
	G             = 71,
	H             = 72,
	I             = 73,
	J             = 74,
	K             = 75,
	L             = 76,
	M             = 77,
	N             = 78,
	O             = 79,
	P             = 80,
	Q             = 81,
	R             = 82,
	S             = 83,
	T             = 84,
	U             = 85,
	V             = 86,
	W             = 87,
	X             = 88,
	Y             = 89,
	Z             = 90,
	LEFT_BRACKET  = 91,
	BACKSLASH     = 92,
	RIGHT_BRACKET = 93,
	GRAVE_ACCENT  = 96,
	WORLD_1       = 161,
	WORLD_2       = 162,
	ESC           = 256,
	ENTER         = 257,
	TAB           = 258,
	BACKSPACE     = 259,
	INSERT        = 260,
	DELETE        = 261,
	RIGHT         = 262,
	LEFT          = 263,
	DOWN          = 264,
	UP            = 265,
	PAGE_UP       = 266,
	PAGE_DOWN     = 267,
	HOME          = 268,
	END           = 269,
	CAPS_LOCK     = 280,
	SCROLL_LOCK   = 281,
	NUM_LOCK      = 282,
	PRINT_SCREEN  = 283,
	PAUSE         = 284,
	F1            = 290,
	F2            = 291,
	F3            = 292,
	F4            = 293,
	F5            = 294,
	F6            = 295,
	F7            = 296,
	F8            = 297,
	F9            = 298,
	F10           = 299,
	F11           = 300,
	F12           = 301,
	F13           = 302,
	F14           = 303,
	F15           = 304,
	F16           = 305,
	F17           = 306,
	F18           = 307,
	F19           = 308,
	F20           = 309,
	F21           = 310,
	F22           = 311,
	F23           = 312,
	F24           = 313,
	F25           = 314,
	KP_0          = 320,
	KP_1          = 321,
	KP_2          = 322,
	KP_3          = 323,
	KP_4          = 324,
	KP_5          = 325,
	KP_6          = 326,
	KP_7          = 327,
	KP_8          = 328,
	KP_9          = 329,
	KP_DECIMAL    = 330,
	KP_DIVIDE     = 331,
	KP_MULTIPLY   = 332,
	KP_SUBTRACT   = 333,
	KP_ADD        = 334,
	KP_ENTER      = 335,
	KP_EQUAL      = 336,
	LEFT_SHIFT    = 340,
	LEFT_CONTROL  = 341,
	LEFT_ALT      = 342,
	LEFT_SUPER    = 343,
	RIGHT_SHIFT   = 344,
	RIGHT_CONTROL = 345,
	RIGHT_ALT     = 346,
	RIGHT_SUPER   = 347,
	MENU          = 348,
	LEFT_MOUSE    = 400,
	RIGHT_MOUSE   = 401,
	MIDDLE_MOUSE  = 402,
}


// Initializes the input subsystem.
// Called in main.odin
init :: proc() {
	// reset state on init
	resetInputState(&_inputState)
}

// @ref
// Returns the input state for **current frame**.
getInputState :: proc() -> ^Input {
	return &_inputState
}

// Returns the internal input event callback.
//
// This is used by the core application loop to route window events into the input system.
// Called in main.odin.
getInputEventCallback :: proc() -> proc "c" (event: ^sokol_app.Event) {
	return _inputEventCallback
}

// @ref
// Checks if a physical key was **pressed** this frame.
// Returns **true** only on the frame the key went down.
isKeyPressed :: proc(code: KeyCode) -> bool {
	return .pressed in _inputState.keys[code]
}

// @ref
// Checks if a physical key was **released** this frame.
// Returns **true** only on the frame the key went up.
isKeyReleased :: proc(code: KeyCode) -> bool {
	return .released in _inputState.keys[code]
}

// @ref
// Checks if a physical key is currently **held down**.
// Returns **true** as long as the key is held.
isKeyDown :: proc(code: KeyCode) -> bool {
	return .down in _inputState.keys[code]
}

// @ref
// Checks if a physical key is sending **repeat** events **(OS specific)**.
// Useful for text input fields.
isKeyRepeating :: proc(code: KeyCode) -> bool {
	return .repeat in _inputState.keys[code]
}

// @ref
// Manually consumes a **pressed** event for a key.
// Useful if an event should only trigger one game action per frame.
consumeKeyPressed :: proc(code: KeyCode) {
	_inputState.keys[code] -= {.pressed}
}

// @ref
// Manually consumes a **released** event for a key.
consumeKeyReleased :: proc(code: KeyCode) {
	_inputState.keys[code] -= {.released}
}

// @ref
// Checks if **any** key is pressed this frame.
// If found, it **consumes** that press and returns **true**.
// Useful for "Press any key" interactions.
consumeAnyKeyPress :: proc() -> bool {
	for &flag, key in _inputState.keys {
		if key >= int(KeyCode.LEFT_MOUSE) do continue

		if .pressed in flag {
			flag -= {.pressed}
			return true
		}
	}
	return false
}

// @ref
// Checks if a mapped action (e.g. **.use**, **.interact**) was **pressed** this frame.
isActionPressed :: proc(action: InputAction) -> bool {
	key := _getKeyFromAction(action)
	return isKeyPressed(key)
}

// @ref
// Checks if a mapped action was **released** this frame.
isActionReleased :: proc(action: InputAction) -> bool {
	key := _getKeyFromAction(action)
	return isKeyReleased(key)
}

// @ref
// Checks if a mapped action is currently **held down**.
isActionDown :: proc(action: InputAction) -> bool {
	key := _getKeyFromAction(action)
	return isKeyDown(key)
}

// @ref
// Consumes the **press** event for a specific action.
consumeActionPressed :: proc(action: InputAction) {
	key := _getKeyFromAction(action)
	consumeKeyPressed(key)
}

// @ref
// Consumes the **release** event for a specific action.
consumeActionReleased :: proc(action: InputAction) {
	key := _getKeyFromAction(action)
	consumeKeyReleased(key)
}

// @ref
// Controls the visibility of the system (hardware) cursor.
// Set to **false** if you intend to render your own custom cursor sprite.
setCursorVisible :: proc(visible: bool) {
	sokol_app.show_mouse(visible)
}

// @ref
// Locks the cursor to the window.
setCursorLocked :: proc(locked: bool) {
	sokol_app.lock_mouse(locked)
}

// @ref
// Helper to construct a normalized directional vector from the standard
// up/down/left/right actions.
//
// Returns a zero vector if no input, or a normalized vector (length equal to 1.0).
getInputVector :: proc() -> gmath.Vector2 {
	input: gmath.Vector2
	if isActionDown(InputAction.left) do input.x -= 1.0
	if isActionDown(InputAction.right) do input.x += 1.0
	if isActionDown(InputAction.down) do input.y -= 1.0
	if isActionDown(InputAction.up) do input.y += 1.0

	if input == {} {
		return {}
	} else {
		return gmath.normalize(input)
	}
}

// @ref
// Converts the raw screen mouse coordinates into World/UI space coordinates
// by un-projecting them using the current renderer's projection matrix.
getMousePosition :: proc() -> gmath.Vector2 {
	drawFrame := render.getDrawFrame()
	coreContext := core.getCoreContext()
	projectionMatrix := drawFrame.reset.coordSpace.projectionMatrix

	mousePosition := _inputState.mousePosition

	// normalize mouse to -1.0 -> +1.0
	normalX := (mousePosition.x / (f32(coreContext.windowWidth) * 0.5)) - 1.0
	normalY := (mousePosition.y / (f32(coreContext.windowHeight) * 0.5)) - 1.0
	normalY *= -1

	mouseNormal := gmath.Vector2{normalX, normalY}
	mouseWorld := gmath.Vector4{mouseNormal.x, mouseNormal.y, 0, 1}

	mouseWorld = gmath.matrixInverse(projectionMatrix) * mouseWorld

	return mouseWorld.xy
}

// @ref
// Returns the current vertical scroll delta (mouse wheel).
getScrollY :: proc() -> f32 {
	return _inputState.mouseScroll.y
}

// helper to get key from action
@(private = "file")
_getKeyFromAction :: proc(action: InputAction) -> KeyCode {
	return actionMap[action]
}

// resets per-frame flags.
// called internally from main.odin at the start of a frame.
resetInputState :: proc(input: ^Input) {
	for &key in input.keys {
		key -= ~{.down}
	}
	input.mouseScroll = {}
}

@(private = "file")
_inputEventCallback :: proc "c" (event: ^sokol_app.Event) {
	inputState := &_inputState

	#partial switch event.type {
	case .MOUSE_SCROLL:
		inputState.mouseScroll.x = event.scroll_x
		inputState.mouseScroll.y = event.scroll_y

	case .MOUSE_MOVE:
		inputState.mousePosition.x = event.mouse_x
		inputState.mousePosition.y = event.mouse_y

	case .MOUSE_UP:
		if .down in inputState.keys[_mapSokolMouseButton(event.mouse_button)] {
			inputState.keys[_mapSokolMouseButton(event.mouse_button)] -= {.down}
			inputState.keys[_mapSokolMouseButton(event.mouse_button)] += {.released}
		}

	case .MOUSE_DOWN:
		if !(.down in inputState.keys[_mapSokolMouseButton(event.mouse_button)]) {
			inputState.keys[_mapSokolMouseButton(event.mouse_button)] += {.down, .pressed}
		}

	case .KEY_UP:
		if .down in inputState.keys[event.key_code] {
			inputState.keys[event.key_code] -= {.down}
			inputState.keys[event.key_code] += {.released}
		}

	case .KEY_DOWN:
		if !event.key_repeat && !(.down in inputState.keys[event.key_code]) {
			inputState.keys[event.key_code] += {.down, .pressed}
		}
		if event.key_repeat {
			inputState.keys[event.key_code] += {.repeat}
		}

	case .TOUCHES_BEGAN:
		when !TOUCH_EMULATE_MOUSE do break

		if event.num_touches > 0 {
			touch := event.touches[0]

			inputState.mousePosition.x = touch.pos_x
			inputState.mousePosition.y = touch.pos_y

			if !(.down in inputState.keys[KeyCode.LEFT_MOUSE]) {
				inputState.keys[KeyCode.LEFT_MOUSE] += {.down, .pressed}
			}
		}

	case .TOUCHES_MOVED:
		when !TOUCH_EMULATE_MOUSE do break

		if event.num_touches > 0 {
			touch := event.touches[0]
			inputState.mousePosition.x = touch.pos_x
			inputState.mousePosition.y = touch.pos_y
		}

	case .TOUCHES_ENDED, .TOUCHES_CANCELLED:
		when !TOUCH_EMULATE_MOUSE do break

		if event.num_touches > 0 {
			touch := event.touches[0]
			inputState.mousePosition.x = touch.pos_x
			inputState.mousePosition.y = touch.pos_y
		}

		if .down in inputState.keys[KeyCode.LEFT_MOUSE] {
			inputState.keys[KeyCode.LEFT_MOUSE] -= {.down}
			inputState.keys[KeyCode.LEFT_MOUSE] += {.released}
		}
	}
}

@(private = "file")
_mapSokolMouseButton :: proc "c" (sokolMouseButton: sokol_app.Mousebutton) -> KeyCode {
	#partial switch sokolMouseButton {
	case .LEFT:
		return .LEFT_MOUSE
	case .RIGHT:
		return .RIGHT_MOUSE
	case .MIDDLE:
		return .MIDDLE_MOUSE
	}
	return nil
}
