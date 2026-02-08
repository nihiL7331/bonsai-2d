package input

// @overview
// This package manages user input across keyboard, mouse and gamepad devices.
// It supports both raw key polling and an abstract, player-centric binding system that
// decouples physical inputs from logical game actions.
//
// **Features:**
// - **Action system:** Maps physical keys to logical [`Action`](#action) enums (digital).
// - **Axis system:** Maps keys and sticks to logical [`Axis`](#axis) enums (analog).
// - **Multi-User:** Supports separate bindings for multiple (default: 5) players via [`PlayerProfile`](#playerprofile).
// - **Hybrid input:** Automatically handles switching between keyboard and gamepad, as well as multiplayer input.
// - **Mouse utilities:** Helpers for easy usage of the mouse inputs ([`getMousePosition`](#getmouseposition), [`getScrollY`](#getscrolly))
// - **Key reading:** Direct access to key states via [`isKeyDown`](#iskeydown), [`isKeyPressed`](#iskeypressed) and [`isKeyReleased`](#iskeyreleased).
// - **Cursor control:** Functions to lock or hide the system cursor ([`setCursorLocked`](#setcursorlocked), [`setCursorVisible`](#setcursorvisible)) **(Desktop only)**
//
// :::note[Usage]
// ```Odin
// update :: proc() {
//   // ...
//   move := input.getInputVector() // handles WASD/Stick automatically
//   player.position += move * speed * deltaTime
//
//   if input.isActionPressed(.Jump) { // handles e.g. Space + Gamepad 'A'
//     player.velocity.z = jumpForce
//   }
//
//   if input.isActionPressed(.Jump, playerIndex = 1) {
//     // Player 2 logic...
//   }
// }
// ```
// :::

import "base:runtime"
import "bonsai:core"
import "bonsai:core/gmath"
import "bonsai:core/render"
import sokol_app "bonsai:libs/sokol/app"

// internal capacity for the input buffer
@(private = "file")
_KEY_CODE_CAPACITY :: 512

// @ref
// Maximum count of logical players that will have their inputs separated.
MAX_PLAYERS :: MAX_GAMEPADS + 1

// @ref
// Configuration constant for touch support. If set to `true`,
// makes each touch (0-index) emulate a mouse click.
TOUCH_EMULATE_MOUSE :: true

// @ref
// Configuration constant for touch emulation. If set to `true`,
// makes each mouse click emulate a 0-index touch.
MOUSE_EMULATE_TOUCH :: true

@(private = "package")
_inputState: Input

@(private = "package")
_players: [MAX_PLAYERS]PlayerProfile

// @ref
// Main container for the **current frame**'s input state.
Input :: struct {
	keys:              [_KEY_CODE_CAPACITY]bit_set[InputFlag], //bitset of 4 bits (down, pressed, released, repeat)
	mousePosition:     gmath.Vector2,
	mouseScroll:       gmath.Vector2,
	gamepadKeys:       [MAX_GAMEPADS][GamepadButton]bit_set[InputFlag],
	touches:           [MAX_TOUCHES]Touch,
	virtualAxisValues: [MAX_GAMEPADS][GamepadAxis]f32,
}

// @ref
// Represents a single physical input source.
BindingSource :: union {
	KeyCode,
	GamepadButton,
	GamepadAxis,
}

// @ref
// Configuration for a single axis binding (e.g., 'W' key contributes -1.0 to `MoveY`).
AxisBind :: struct {
	source:   BindingSource,
	scale:    f32,
	deadzone: f32,
}

// @ref
// Configuration state for a logical player.
// Contains their assigned device ID and input mappings.
PlayerProfile :: struct {
	gamepadIndex: GamepadIndex, // -1 for no gamepad
	useKeyboard:  bool,
	bindings:     [Action][dynamic]BindingSource,
	axes:         [Axis][dynamic]AxisBind,
}

// @ref
// Bit flags representing the state of a specific **key** or **button** in the **current frame**.
InputFlag :: enum u8 {
	down, // Key is currently held down
	pressed, // Key was pressed this frame
	released, // Key was released this frame
}

// @ref
// **Abstract** digital actions (on/off) that decouple game logic from specific **physical** keys.
Action :: enum u8 {
	MenuLeft,
	MenuRight,
	MenuUp,
	MenuDown,
	// Add more if needed!
}

// @ref
// **Abstract** analog axes (Float -1.0 to 1.0).
// Used e.g. for movement.
Axis :: enum u8 {
	MoveX,
	MoveY,
	LookX,
	LookY,
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
	initGamepad()

	_players[0].useKeyboard = true
}

// @ref
// Returns the input state for **current frame**.
getInputState :: proc() -> ^Input {
	return &_inputState
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
// Manually consumes a **pressed** event for a key.
// Returns `true` if the state was changed.
// :::tip
// Useful if an event should only trigger one game action per frame.
// :::
consumeKeyPressed :: proc(code: KeyCode) -> bool {
	if .pressed in _inputState.keys[code] {
		_inputState.keys[code] -= {.pressed}
		return true
	}
	return false
}

// @ref
// Manually consumes a **released** event for a key.
// Returns `true` if the state was changed.
consumeKeyReleased :: proc(code: KeyCode) -> bool {
	if .released in _inputState.keys[code] {
		_inputState.keys[code] -= {.released}
		return true
	}
	return false
}

// @ref
// Checks if **any** key is pressed this frame.
// If found, it **consumes** that press and returns **true**.
// :::tip
// Useful for "Press any key" interactions.
// :::
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
// Checks if a mapped action (e.g. [`.MenuLeft`](#action), [`.MenuRight`](#action)) was **pressed** this frame.
// Default `playerIndex` is **0**.
isActionPressed :: proc(action: Action, playerIndex: uint = 0) -> bool {
	player := &_players[playerIndex]

	for bind in player.bindings[action] {
		if _checkBindPressed(player, bind) do return true
	}
	return false
}

// @ref
// Checks if a mapped action was **released** this frame.
// Default `playerIndex` is **0**.
isActionReleased :: proc(action: Action, playerIndex: uint = 0) -> bool {
	player := &_players[playerIndex]

	for bind in player.bindings[action] {
		if _checkBindReleased(player, bind) do return true
	}
	return false
}

// @ref
// Checks if a mapped action is currently **held down**.
// Default `playerIndex` is **0**.
isActionDown :: proc(action: Action, playerIndex: uint = 0) -> bool {
	player := &_players[playerIndex]

	for bind in player.bindings[action] {
		if _checkBindDown(player, bind) do return true
	}
	return false
}

// @ref
// Consumes the **press** event for a specific action.
// Returns `true` if the [`Action`](#action) state was changed.
consumeActionPressed :: proc(action: Action, playerIndex: uint = 0) -> bool {
	player := &_players[playerIndex]
	hasConsumedAny := false

	for bind in player.bindings[action] {
		if _consumeBindPressed(player, bind) {
			hasConsumedAny = true
		}
	}

	return hasConsumedAny
}

// @ref
// Consumes the **release** event for a specific action.
// Returns `true` if the [`Action`](#action) state was changed.
// Default `playerIndex` is **0**.
consumeActionReleased :: proc(action: Action, playerIndex: uint = 0) -> bool {
	player := &_players[playerIndex]
	hasConsumedAny := false

	for bind in player.bindings[action] {
		if _consumeBindReleased(player, bind) {
			hasConsumedAny = true
		}
	}

	return hasConsumedAny
}

// @ref
// Binds a physical input to a logical [`Action`](#action).
// Default `playerIndex` is **0**.
bindAction :: proc(action: Action, source: BindingSource, playerIndex: uint = 0) {
	append(&_players[playerIndex].bindings[action], source)
}

// @ref
// Binds a physical input to an [`Axis`](#axis) with a specific scale.
// Default `playerIndex` is **0**.
// :::note(Example)
// ```Odin
// bindAxis(.MoveY, .W, 1.0)
// bindAxis(.MoveY, .S, -1.0)
// bindAxis(.MoveX, .A, -1.0)
// bindAxis(.MoveX, .D, 1.0)
// ```
// :::
bindAxis :: proc(
	axis: Axis,
	source: BindingSource,
	scale: f32,
	deadzone: f32 = 0.1,
	playerIndex: uint = 0,
) {
	bind := AxisBind {
		source   = source,
		scale    = scale,
		deadzone = deadzone,
	}
	append(&_players[playerIndex].axes[axis], bind)
}

// @ref
// Helper to assign a specific gamepad of index `gamepadIndex` to a player slot of index `playerIndex`.
assignGamepad :: proc(playerIndex: uint, gamepadIndex: GamepadIndex) {
	_players[playerIndex].gamepadIndex = gamepadIndex
}

// @ref
// Controls the visibility of the system (hardware) cursor.
// Set to **false** if you intend to render your own custom cursor sprite.
setCursorVisible :: proc(isVisible: bool) {
	sokol_app.show_mouse(isVisible)
}

// @ref
// Locks the cursor to the window.
setCursorLocked :: proc(isLocked: bool) {
	sokol_app.lock_mouse(isLocked)
}

// @ref
// Returns clamped float (-1.0 to 1.0) combining **all** bound inputs.
// Default `playerIndex` is **0**.
getAxis :: proc(axis: Axis, playerIndex: uint = 0) -> f32 {
	totalAxis: f32 = 0.0
	player := &_players[playerIndex]
	bindings := player.axes[axis]

	for axisBind in bindings {
		totalAxis += _readBindingValue(player, axisBind)
	}

	return gmath.clamp(totalAxis, f32(-1.0), f32(1.0))
}

// @ref
// Helper to construct a normalized directional vector from the standard
// up/down/left/right actions.
// Default `playerIndex` is **0**.
// Returns a zero vector if no input, or a normalized vector (length equal to 1.0).
getInputVector :: proc(playerIndex: uint = 0) -> gmath.Vector2 {
	inputVector := gmath.Vector2{getAxis(.MoveX, playerIndex), getAxis(.MoveY, playerIndex)}
	if gmath.length(inputVector) > 1.0 do return gmath.normalize(inputVector)
	return inputVector
}

@(private = "package")
_convertRawCoordinates :: proc(coordinates: gmath.Vector2) -> gmath.Vector2 {
	drawFrame := render.getDrawFrame()
	coreContext := core.getCoreContext()
	projectionMatrix := drawFrame.reset.coordSpace.projectionMatrix

	normalX := (coordinates.x / (f32(coreContext.windowWidth) * 0.5)) - 1.0
	normalY := (coordinates.y / (f32(coreContext.windowHeight) * 0.5)) - 1.0
	normalY *= -1

	worldMatrix := gmath.Vector4{normalX, normalY, 0, 1}
	worldMatrix = gmath.matrixInverse(projectionMatrix) * worldMatrix

	return worldMatrix.xy
}

// @ref
// Converts the raw screen mouse coordinates into World/UI space coordinates
// by un-projecting them using the current renderer's projection matrix.
getMousePosition :: proc() -> gmath.Vector2 {
	return _convertRawCoordinates(_inputState.mousePosition)
}

// @ref
// Returns the current vertical scroll delta (mouse wheel).
getScrollY :: proc() -> f32 {
	return _inputState.mouseScroll.y
}

// resets per-frame flags.
// called internally from main.odin at the end of a frame.
resetInputState :: proc(input: ^Input) {
	for &key in input.keys {
		key -= ~{.down}
	}
	input.mouseScroll = {}

	for &touch in input.touches {
		if touch.phase == .Ended || touch.phase == .Cancelled {
			touch.phase = .None
			touch.index = 0
		} else if touch.phase == .Began || touch.phase == .Moved {
			touch.phase = .Stationary
		}
	}
	input.virtualAxisValues = {}
}

inputEventCallback :: proc "c" (event: ^sokol_app.Event, ctx: runtime.Context) {
	context = ctx
	inputState := &_inputState

	#partial switch event.type {
	case .MOUSE_SCROLL:
		inputState.mouseScroll.x = event.scroll_x
		inputState.mouseScroll.y = event.scroll_y

	case .MOUSE_MOVE:
		when MOUSE_EMULATE_TOUCH {
			fakeTouch := sokol_app.Touchpoint {
				identifier = 0,
				pos_x      = event.mouse_x,
				pos_y      = event.mouse_y,
			}
			_updateTouchState(.TOUCHES_MOVED, fakeTouch)
		}
		inputState.mousePosition.x = event.mouse_x
		inputState.mousePosition.y = event.mouse_y

	case .MOUSE_UP:
		if .down in inputState.keys[_mapSokolMouseButton(event.mouse_button)] {
			when MOUSE_EMULATE_TOUCH {
				fakeTouch := sokol_app.Touchpoint {
					identifier = 0,
					pos_x      = event.mouse_x,
					pos_y      = event.mouse_y,
				}
				_updateTouchState(.TOUCHES_ENDED, fakeTouch)
			}
			inputState.keys[_mapSokolMouseButton(event.mouse_button)] -= {.down}
			inputState.keys[_mapSokolMouseButton(event.mouse_button)] += {.released}
		}

	case .MOUSE_DOWN:
		if !(.down in inputState.keys[_mapSokolMouseButton(event.mouse_button)]) {
			when MOUSE_EMULATE_TOUCH {
				fakeTouch := sokol_app.Touchpoint {
					identifier = 0,
					pos_x      = event.mouse_x,
					pos_y      = event.mouse_y,
				}
				_updateTouchState(.TOUCHES_BEGAN, fakeTouch)
			}
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

	case .TOUCHES_BEGAN, .TOUCHES_MOVED, .TOUCHES_ENDED, .TOUCHES_CANCELLED:
		touchCount := event.num_touches

		for i in 0 ..< touchCount {
			sokolTouch := event.touches[i]
			_updateTouchState(event.type, sokolTouch)
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
	return .INVALID
}

@(private = "file")
_updateTouchState :: proc(type: sokol_app.Event_Type, point: sokol_app.Touchpoint) {
	phase: TouchPhase = .Moved
	if type == .TOUCHES_BEGAN do phase = .Began
	if type == .TOUCHES_ENDED do phase = .Ended
	if type == .TOUCHES_CANCELLED do phase = .Cancelled

	slotIndex := -1
	for i in 0 ..< MAX_TOUCHES {
		touch := &_inputState.touches[i]
		if touch.phase != .None && touch.index == cast(i64)point.identifier {
			slotIndex = i
			break
		}
	}

	if slotIndex == -1 && phase == .Began {
		for i in 0 ..< MAX_TOUCHES {
			if _inputState.touches[i].phase == .None {
				slotIndex = i
				break
			}
		}
	}

	if slotIndex != -1 {
		touch := &_inputState.touches[slotIndex]
		touch.index = cast(i64)point.identifier
		touch.position = gmath.Vector2{point.pos_x, point.pos_y}
		touch.position = _convertRawCoordinates(touch.position)

		if phase == .Moved && (touch.phase == .Began || touch.phase == .Ended) {
			return
		}
		touch.phase = phase
	}
}

@(private = "file")
_checkBindPressed :: proc(player: ^PlayerProfile, bind: BindingSource) -> bool {
	switch button in bind {
	case KeyCode:
		return player.useKeyboard && isKeyPressed(button)
	case GamepadButton:
		return player.gamepadIndex != -1 && isGamepadPressed(player.gamepadIndex, button)
	case GamepadAxis:
		return false
	}
	return false
}

@(private = "file")
_checkBindReleased :: proc(player: ^PlayerProfile, bind: BindingSource) -> bool {
	switch button in bind {
	case KeyCode:
		return player.useKeyboard && isKeyReleased(button)
	case GamepadButton:
		return player.gamepadIndex >= 0 && isGamepadReleased(player.gamepadIndex, button)
	case GamepadAxis:
		return false
	}
	return false
}

@(private = "file")
_checkBindDown :: proc(player: ^PlayerProfile, bind: BindingSource) -> bool {
	switch button in bind {
	case KeyCode:
		return player.useKeyboard && isKeyDown(button)
	case GamepadButton:
		return player.gamepadIndex >= 0 && isGamepadDown(player.gamepadIndex, button)
	case GamepadAxis:
		return false
	}
	return false
}

@(private = "file")
_consumeBindPressed :: proc(player: ^PlayerProfile, bind: BindingSource) -> bool {
	switch button in bind {
	case KeyCode:
		return player.useKeyboard && consumeKeyPressed(button)
	case GamepadButton:
		return player.gamepadIndex >= 0 && consumeGamepadPressed(player.gamepadIndex, button)
	case GamepadAxis:
		return false
	}
	return false
}

@(private = "file")
_consumeBindReleased :: proc(player: ^PlayerProfile, bind: BindingSource) -> bool {
	switch button in bind {
	case KeyCode:
		return player.useKeyboard && consumeKeyReleased(button)
	case GamepadButton:
		return player.gamepadIndex >= 0 && consumeGamepadReleased(player.gamepadIndex, button)
	case GamepadAxis:
		return false
	}
	return false
}

@(private = "file")
_readBindingValue :: proc(player: ^PlayerProfile, bind: AxisBind) -> f32 {
	value: f32 = 0.0

	switch source in bind.source {
	case KeyCode:
		if player.useKeyboard && isKeyDown(source) do value = 1.0
	case GamepadButton:
		if player.gamepadIndex >= 0 && isGamepadDown(player.gamepadIndex, source) do value = 1.0
	case GamepadAxis:
		if player.gamepadIndex >= 0 {
			hardwareValue := getGamepadAxis(player.gamepadIndex, source)
			virtualValue := _inputState.virtualAxisValues[player.gamepadIndex][source]

			if abs(virtualValue) > abs(hardwareValue) {
				value = virtualValue
			} else {
				value = hardwareValue
			}
		}
	}

	if abs(value) < bind.deadzone do value = 0.0

	return value * bind.scale
}
