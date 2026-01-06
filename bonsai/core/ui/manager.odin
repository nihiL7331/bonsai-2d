package ui

import "bonsai:core/gmath"
import "bonsai:core/input"
import "bonsai:core/render"

import "core:log"

@(private = "package")
_uiVisible := false

// @ref
// Sets the key that needs to be pressed to toggle the **Debug UI**.
UI_VISIBLE_KEYCODE :: input.KeyCode.F1

FNV_OFFSET_BASIS :: 2166136261
FNV_PRIME :: 16777619

DrawRectangleCommand :: struct {
	rectangle:    gmath.Rectangle,
	color:        gmath.Color,
	outlineColor: gmath.Color,
}

DrawTextCommand :: struct {
	text:     string,
	position: gmath.Vector2,
	color:    gmath.Color,
	pivot:    gmath.Pivot,
	scale:    f32,
	rotation: f32,
}

SetScissorCommand :: struct {
	rectangle: gmath.Rectangle,
}

// @ref
// Union of all possible draw operations a UI widget can request.
Command :: union {
	DrawRectangleCommand,
	DrawTextCommand,
	SetScissorCommand,
}

// @ref
// Represents a persistent **Window**.
Container :: struct {
	id:             u32,
	lastFrameIndex: u32,
	widgetCount:    u32,

	// Layout State
	rectangle:      gmath.Rectangle,
	headerHeight:   f32,
	scrollbarWidth: f32,
	closeWidth:     f32,
	toggleWidth:    f32,

	// Cursor / Scroll State
	cursor:         gmath.Vector2,
	scrollOffset:   f32,
	contentHeight:  f32,
	currentCursorY: f32,

	// Flags
	isHot:          bool,
	isOpen:         bool,
	isExpanded:     bool,
	isScrolling:    bool,
	isInitialized:  bool,

	// Draw List
	commands:       [dynamic]Command,
}

// @ref
// Represents the **Immediate UI** state.
UiState :: struct {
	// Interaction State
	hot:                   u32, // The element currently hovered/ready
	lastFrameHot:          u32,
	active:                u32, // The element currently being clicked/dragged
	frameIndex:            u32,

	// Input State
	mousePosition:         gmath.Vector2,
	previousMousePosition: gmath.Vector2,

	// Window Management
	containers:            map[u32]^Container,
	containerOrder:        [dynamic]u32, // Z-Order (Back -> Front)
	currentContainer:      ^Container, // The window currently being built

	// ID Stack for hashing
	ids:                   [dynamic]u32,
}

// Global UI State instance
state: UiState

// @ref
// Generates a unique UI ID based on a string label and the current ID stack.
// Uses FNV-1a hashing.
getId :: proc(title: string) -> u32 {
	seed: u32 = FNV_OFFSET_BASIS

	if len(state.ids) > 0 {
		// use the top of the user-pushed ID stack
		seed = state.ids[len(state.ids) - 1]
	} else if state.currentContainer != nil {
		// use the current window + widget counter for automatic differentiation
		parent := state.currentContainer
		seed = parent.id
		parent.widgetCount += 1
		seed = (seed ~ parent.widgetCount) * FNV_PRIME
	}

	hash := seed
	for byteValue in transmute([]u8)title {
		hash = (hash ~ u32(byteValue)) * FNV_PRIME
	}

	return hash
}

pushId :: proc {
	pushIdInt,
	pushIdString,
}

pushIdInt :: proc(id: int) {
	seed: u32
	if len(state.ids) > 0 {
		seed = state.ids[len(state.ids) - 1]
	} else if state.currentContainer != nil {
		seed = state.currentContainer.id
	} else {
		seed = FNV_OFFSET_BASIS
	}

	newHash := (seed ~ u32(id)) * FNV_PRIME
	append(&state.ids, newHash)
}

pushIdString :: proc(title: string) {
	seed: u32
	if len(state.ids) > 0 {
		seed = state.ids[len(state.ids) - 1]
	} else if state.currentContainer != nil {
		seed = state.currentContainer.id
	} else {
		seed = FNV_OFFSET_BASIS
	}

	hash := seed
	for byteValue in transmute([]u8)title {
		hash = (hash ~ u32(byteValue)) * FNV_PRIME
	}
	append(&state.ids, hash)
}

popId :: proc() {
	if len(state.ids) > 0 {
		pop(&state.ids)
	} else {
		log.error("popId called with empty stack.")
	}
}

init :: proc() {
	state.containers = make(map[u32]^Container)
	state.hot = 0
	state.active = 0
	state.mousePosition = {0, 0}
	state.previousMousePosition = {0, 0}
	state.ids = make([dynamic]u32)
}

@(private = "package")
_hoveredWindowId: u32

// @ref
// Starts a new UI frame.
// Determines which window is currently hovered to handle Z-ordering and click masking.
begin :: proc(mousePosition: gmath.Vector2) {
	state.mousePosition = mousePosition
	state.frameIndex += 1

	clear(&state.ids)

	state.lastFrameHot = state.hot
	state.hot = 0
	_hoveredWindowId = 0

	#reverse for id in state.containerOrder {
		container := state.containers[id]
		if !container.isOpen do continue

		hitRectangle := container.rectangle
		if !container.isExpanded {
			// if collapsed, only check header
			hitRectangle.y = container.rectangle.w - container.headerHeight
		}

		if gmath.rectangleContains(hitRectangle, state.mousePosition) {
			_hoveredWindowId = id
			break
		}
	}

	// bring clicked window to front
	if input.isKeyPressed(input.KeyCode.LEFT_MOUSE) && _hoveredWindowId != 0 {
		index := -1
		for id, i in state.containerOrder {
			if id == _hoveredWindowId {
				index = i
				break
			}
		}

		// move to end of array (top)
		if index != -1 {
			ordered_remove(&state.containerOrder, index)
			append(&state.containerOrder, _hoveredWindowId)
		}
	}
}

// @ref
// Ends the UI frame and dispatches render commands.
// Handles clicking consumption so gameplay doesn't react to UI clicks.
end :: proc() {
	if input.isKeyPressed(input.KeyCode.LEFT_MOUSE) {
		hitWindowId: u32 = 0

		#reverse for id in state.containerOrder {
			container := state.containers[id]
			hitRectangle := container.rectangle
			if !container.isExpanded {
				hitRectangle.y = container.rectangle.w - container.headerHeight
			}

			if gmath.rectangleContains(hitRectangle, state.mousePosition) {
				hitWindowId = id
				break
			}
		}

		if hitWindowId != 0 {
			input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
		}
	}

	// render windows
	for id in state.containerOrder {
		container := state.containers[id]

		// skip if window wasnt submitted this frame
		if container.lastFrameIndex != state.frameIndex {
			clear(&container.commands)
			continue
		}

		// layout fixup for first frame
		if !container.isInitialized {
			container.rectangle = gmath.rectangleShift(
				container.rectangle,
				gmath.Vector2 {
					0,
					container.rectangle.w - container.rectangle.y - container.headerHeight,
				},
			)
			container.isInitialized = true
		}

		// execute draw commands
		render.clearScissor()

		for command in container.commands {
			switch c in command {
			case DrawRectangleCommand:
				render.drawRectangle(c.rectangle, outlineColor = c.outlineColor, color = c.color)
			case DrawTextCommand:
				render.drawText(
					c.position,
					c.text,
					DEFAULT_FONT,
					DEFAULT_FONT_SIZE,
					c.rotation,
					color = c.color,
					scale = f64(c.scale),
					pivot = c.pivot,
				)
			case SetScissorCommand:
				render.setScissorRectangle(c.rectangle)
			}
		}
	}

	if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
		state.active = 0
	}

	// debug toggle
	when ODIN_DEBUG {
		if input.isKeyPressed(UI_VISIBLE_KEYCODE) {
			_uiVisible = !_uiVisible
			log.infof("Debug UI Visibility: %v", _uiVisible)
		}
	}

	state.previousMousePosition = state.mousePosition
	render.clearScissor()
}
