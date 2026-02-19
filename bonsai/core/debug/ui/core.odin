package ui

import "bonsai:core/clock"
import "bonsai:core/gmath"
import "bonsai:core/input"
import "bonsai:core/render"

import "core:hash"
import "core:slice"
import "core:strings"

when !ODIN_DEBUG {
	_ :: clock
	_ :: gmath
	_ :: input
	_ :: render
	_ :: strings
	_ :: hash
	_ :: slice
}

// @ref
// Initializes the UI state for the new frame.
// Resets per-frame counters, clears command buffers, and performs window hit-testing.
// Called internally at the start of each frame.
start :: proc() {
	when ODIN_DEBUG {
		_ui.cursor = render.getViewportPivot(.topLeft)
		_ui.startX = 0
		_ui.indentation = 0
		_ui.hotId = 0
		_ui.maxWidth = 0
		_ui.nextZIndex = 1.0
		_ui.clickClaimedZ = -1.0
		_ui.isRecordingPopup = false

		if input.isKeyPressed(.LEFT_MOUSE) {
			_ui.nextFocusedWindowId = 0
		}

		if _ui.windows == nil {
			_ui.windows = make(map[u64]WindowState)
		}

		if _ui.headers == nil {
			_ui.headers = make(map[u64]bool)
		}

		if _ui.inputBuffers == nil {
			_ui.inputBuffers = make(map[u64]strings.Builder)
		}

		if _ui.tabBars == nil {
			_ui.tabBars = make(map[u64]u64)
		}

		if _ui.idStack == nil {
			_ui.idStack = make([dynamic]u64)
		}
		clear(&_ui.idStack)

		if _ui.popupCommands == nil {
			_ui.popupCommands = make([dynamic]Command)
		}
		clear(&_ui.popupCommands)

		_ui.hoveredWindowId = 0
		_ui.mousePosition = input.getMousePosition(.Screen)

		WindowReference :: struct {
			id: u64,
			z:  f32,
		}
		references := make([dynamic]WindowReference, 0, len(_ui.windows), context.temp_allocator)
		for id, state in _ui.windows {
			if state.lastFrameSeen == clock.getTicks() - 1 {
				append(&references, WindowReference{id, state.zIndex})
			}
		}

		slice.sort_by(references[:], proc(a, b: WindowReference) -> bool {
			return a.z > b.z
		})

		for reference in references {
			state := _ui.windows[reference.id]
			currentTopY := state.position.y + state.size.y

			rectangle := gmath.Rectangle {
				state.position.x,
				currentTopY - DEFAULT_STYLE.titleHeight,
				state.position.x + state.size.x,
				currentTopY,
			}
			if !state.isCollapsed {
				rectangle.y = state.position.y
			}

			if gmath.rectangleContains(rectangle, _ui.mousePosition) {
				_ui.hoveredWindowId = reference.id
				break
			}
		}
	}
}

// @ref
// Executes all deferred UI commands.
// Sorts windows by Z-index, renders them back-to-front, then renders popups and tooltips on top.
// Called internally at the end of the frame.
draw :: proc() {
	when ODIN_DEBUG {
		windows := make([dynamic]WindowState, 0, len(_ui.windows), context.temp_allocator)

		for _, window in _ui.windows {
			if window.lastFrameSeen == clock.getTicks() {
				append(&windows, window)
			}
		}

		slice.sort_by(windows[:], proc(a, b: WindowState) -> bool {
			return a.zIndex < b.zIndex
		})

		visualZ: f32 = 1.0

		for window in windows {
			visualZ += 1000.0

			for cmd in window.commands {
				visualZ += 0.1
				_executeCommand(cmd, visualZ)
			}
		}

		if len(_ui.popupCommands) > 0 {
			popupZ: f32 = 99999.0

			for cmd in _ui.popupCommands {
				popupZ += 0.1
				_executeCommand(cmd, visualZ)
			}
		}

		_drawTooltip()
		_ui.tooltipText = ""
	}
}

// @ref
// Finalizes the UI frame state.
// Commits focus changes and resets active widget state on mouse release.
// Called internally at the end of each frame.
end :: proc() {
	when ODIN_DEBUG {
		if input.isKeyPressed(.LEFT_MOUSE) && _ui.nextFocusedWindowId != 0 {
			_ui.focusedWindowId = _ui.nextFocusedWindowId
		}

		if input.isKeyReleased(.LEFT_MOUSE) {
			_ui.activeId = 0
		}
	}
}

@(private = "package")
_getIdPointer :: proc(text: string, pointer: rawptr) -> u64 {
	when ODIN_DEBUG {
		seed := _getCurrentSeed()
		textHash := hash.fnv64a(transmute([]byte)text, seed = seed)
		pointerInt := uintptr(pointer)
		pointerBytes := transmute([size_of(uintptr)]byte)pointerInt
		return hash.fnv64a(pointerBytes[:], seed = textHash)
	} else {
		return 0
	}
}

@(private = "package")
_getId :: proc(text: string) -> u64 {
	when ODIN_DEBUG {
		seed := _getCurrentSeed()

		return hash.fnv64a(transmute([]byte)text, seed = seed)
	} else {
		return 0
	}
}

// @ref
// Pushes an integer identifier onto the ID stack.
pushIdInt :: proc(value: int) {
	when ODIN_DEBUG {
		seed := _getCurrentSeed()

		valueBytes := transmute([size_of(int)]byte)value
		newId := hash.fnv64a(valueBytes[:], seed = seed)

		append(&_ui.idStack, newId)
	}
}

// @ref
// Pushes a string identifier onto the ID stack.
pushIdString :: proc(value: string) {
	when ODIN_DEBUG {
		seed := _getCurrentSeed()
		newId := hash.fnv64a(transmute([]byte)value, seed = seed)
		append(&_ui.idStack, newId)
	}
}

// @ref
// Pushes a pointer identifier onto the ID stack.
pushIdPointer :: proc(pointer: rawptr) {
	when ODIN_DEBUG {
		seed := _getCurrentSeed()

		pointerInt := uintptr(pointer)
		pointerBytes := transmute([size_of(uintptr)]byte)pointerInt
		newId := hash.fnv64a(pointerBytes[:], seed = seed)

		append(&_ui.idStack, newId)
	}
}

// @ref
// Pops the last identifier from the stack.
popId :: proc() {
	when ODIN_DEBUG {
		if len(_ui.idStack) > 0 {
			pop(&_ui.idStack)
		}
	}
}

// @ref
// Generic overload for functions used to pushing variable based
// identifiers onto the ID stack.
pushId :: proc {
	pushIdInt,
	pushIdString,
	pushIdPointer,
}

//
// HELPERS
//

@(private = "file")
_drawTooltip :: proc() {
	when ODIN_DEBUG {
		if len(_ui.tooltipText) == 0 do return

		viewportSize := gmath.getRectangleSize(render.getViewportRectangle())

		text := _ui.tooltipText

		textSize := render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, text)
		width := textSize.x + (DEFAULT_STYLE.padding * 2)
		height := textSize.y + (DEFAULT_STYLE.padding * 2)

		position := _ui.mousePosition + gmath.Vector2{5, -5}

		rectangle := gmath.rectangleMake(position, gmath.Vector2{width, height}, .topLeft)

		shiftX := max(rectangle.z - viewportSize.x, 0.0)
		shiftY := max(-rectangle.y, 0.0)
		rectangle = gmath.shift(rectangle, gmath.Vector2{-shiftX, shiftY})

		TOOLTIP_Z :: 99999.0

		render.drawRoundedRectangle(
			rectangle,
			DEFAULT_STYLE.rounding,
			DEFAULT_STYLE.backgroundColor,
			drawLayer = .top,
			sortKey = TOOLTIP_Z,
		)
		render.drawRoundedRectangleLines(
			rectangle,
			DEFAULT_STYLE.rounding,
			DEFAULT_STYLE.textColor,
			drawLayer = .top,
			sortKey = TOOLTIP_Z,
		)

		textPosition := gmath.Vector2 {
			rectangle.x + DEFAULT_STYLE.padding,
			rectangle.w - DEFAULT_STYLE.padding,
		}

		render.drawTextSimple(
			textPosition,
			text,
			DEFAULT_STYLE.font,
			DEFAULT_STYLE.fontSize,
			color = DEFAULT_STYLE.textColor,
			pivot = .topLeft,
			drawLayer = .top,
			sortKey = TOOLTIP_Z + 1.0,
		)
	}
}

@(private = "package")
_pushLine :: proc(start: gmath.Vector2, end: gmath.Vector2, color: gmath.Color) {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return

		command := LineCommand {
			start = start,
			end   = end,
			color = color,
		}

		if _ui.isRecordingPopup {
			append(&_ui.popupCommands, command)
		} else {
			window := &_ui.windows[_ui.currentWindowId]
			append(&window.commands, command)
		}
	}
}

@(private = "package")
_pushRectangle :: proc(
	rectangle: gmath.Rectangle,
	color: gmath.Color,
	isRounding: bool = false,
	isOutline: bool = false,
) {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return

		command := RectangleCommand {
			rectangle  = rectangle,
			color      = color,
			isRounding = isRounding,
			isOutline  = isOutline,
		}

		if _ui.isRecordingPopup {
			append(&_ui.popupCommands, command)
		} else {
			window := &_ui.windows[_ui.currentWindowId]
			append(&window.commands, command)
		}
	}
}

@(private = "package")
_pushTriangle :: proc(
	point1: gmath.Vector2,
	point2: gmath.Vector2,
	point3: gmath.Vector2,
	color: gmath.Color,
) {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return

		command := TriangleCommand {
			point1 = point1,
			point2 = point2,
			point3 = point3,
			color  = color,
		}

		if _ui.isRecordingPopup {
			append(&_ui.popupCommands, command)
		} else {
			window := &_ui.windows[_ui.currentWindowId]
			append(&window.commands, command)
		}
	}
}

@(private = "package")
_pushText :: proc(
	position: gmath.Vector2,
	text: string,
	color: gmath.Color,
	pivot: gmath.Pivot = .bottomLeft,
) {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return

		command := TextCommand {
			position = position,
			text     = text,
			color    = color,
			pivot    = pivot,
		}

		if _ui.isRecordingPopup {
			append(&_ui.popupCommands, command)
		} else {
			window := &_ui.windows[_ui.currentWindowId]
			append(&window.commands, command)
		}
	}
}

@(private = "package")
_pushScissor :: proc(rectangle: gmath.Rectangle) {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return

		command := ScissorCommand {
			rectangle = rectangle,
		}

		window := &_ui.windows[_ui.currentWindowId]
		append(&window.commands, command)
	}
}

@(private = "package")
_popScissor :: proc() {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return

		command := PopScissorCommand{}

		window := &_ui.windows[_ui.currentWindowId]
		append(&window.commands, command)
	}
}

@(private = "file")
_getCurrentSeed :: proc() -> u64 {
	when ODIN_DEBUG {
		if len(_ui.idStack) > 0 {
			return _ui.idStack[len(_ui.idStack) - 1]
		}

		if _ui.currentWindowId != 0 {
			windowBytes := transmute([8]byte)_ui.currentWindowId
			return hash.fnv64a(windowBytes[:])
		}

		return 0
	} else {
		return 0
	}
}

@(private = "file")
_executeCommand :: proc(cmd: Command, zIndex: f32) {
	when ODIN_DEBUG {
		switch command in cmd {
		case LineCommand:
			render.drawLine(
				command.start,
				command.end,
				command.color,
				drawLayer = .top,
				sortKey = zIndex,
			)
		case RectangleCommand:
			if command.isOutline {
				if command.isRounding {
					render.drawRoundedRectangleLines(
						command.rectangle,
						DEFAULT_STYLE.rounding,
						command.color,
						DEFAULT_STYLE.outlineThickness,
						drawLayer = .top,
						sortKey = zIndex,
					)
				} else {
					render.drawRectangleLines(
						command.rectangle,
						command.color,
						drawLayer = .top,
						sortKey = zIndex,
					)
				}
			} else {
				if command.isRounding {
					render.drawRoundedRectangle(
						command.rectangle,
						DEFAULT_STYLE.rounding,
						command.color,
						drawLayer = .top,
						sortKey = zIndex,
					)
				} else {
					render.drawRectangle(
						command.rectangle,
						color = command.color,
						drawLayer = .top,
						sortKey = zIndex,
					)
				}
			}
		case TriangleCommand:
			render.drawTriangle(
				command.point1,
				command.point2,
				command.point3,
				command.color,
				drawLayer = .top,
				sortKey = zIndex,
			)
		case TextCommand:
			render.drawTextSimple(
				command.position,
				command.text,
				DEFAULT_STYLE.font,
				DEFAULT_STYLE.fontSize,
				color = command.color,
				pivot = command.pivot,
				drawLayer = .top,
				sortKey = zIndex,
			)
		case ScissorCommand:
			render.pushScissor(command.rectangle)
		case PopScissorCommand:
			render.popScissor()
		}
	}
}
