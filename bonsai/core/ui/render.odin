package ui

import "bonsai:core/gmath"
import "bonsai:core/input"

import "base:intrinsics"
import "core:fmt"
import "core:hash"
import "core:log"
import "core:math"

// @ref
// Begins a new **Window** container.
// Returns true if the window is open and expanded.
// Objects inside the window should be within the **if-block**.
//
// **Example:**
// ```Odin
// if ui.window("Debug") {
//   ui.button("Reset")
// }
// ```
window :: proc(
	title: string,
	position: gmath.Vector2 = {0, 0},
	config: WindowConfig = DEFAULT_WINDOW_CONFIG,
) -> bool {
	if !_uiVisible do return false

	style := _resolveWindowStyle(config)

	id := hash.fnv32(transmute([]u8)title)

	if !(id in state.containers) {
		_initializeWindowState(id, title, position, style)
	}
	container := state.containers[id]

	if !container.isOpen do return false

	container.lastFrameIndex = state.frameIndex
	clear(&container.commands)
	state.currentContainer = container
	container.widgetCount = 0

	container.contentHeight = container.currentCursorY
	container.currentCursorY = 0
	container.cursor.y = container.headerHeight

	viewHeight := (container.rectangle.w - container.rectangle.y) - container.headerHeight
	container.isScrolling = container.contentHeight > viewHeight
	maxScroll := max(0, container.contentHeight - viewHeight)

	mouseInWindow := gmath.rectangleContains(container.rectangle, state.mousePosition)
	if container.isScrolling && mouseInWindow {
		container.scrollOffset -= input.getScrollY() * style.scrollbarSpeed
		container.scrollOffset = clamp(container.scrollOffset, 0, maxScroll)
	} else if !container.isScrolling {
		container.scrollOffset = 0
	}

	headerBackgroundColor, headerTextColor, headerRectangle := _handleWindowMovement(
		id,
		container,
		style,
	)

	if container.isExpanded {
		append(
			&container.commands,
			DrawRectangleCommand {
				rectangle = container.rectangle,
				color = style.backgroundColor,
				outlineColor = style.borderColor,
			},
		)
		if container.isScrolling {
			_handleScrollbarInteractionAndDraw(container, viewHeight, maxScroll, style)
		}
	}

	_drawHeader(
		id,
		title,
		container,
		headerBackgroundColor,
		headerTextColor,
		headerRectangle,
		style,
	)

	if container.isExpanded {
		contentRectangle := gmath.Rectangle {
			container.rectangle.x,
			container.rectangle.y,
			container.rectangle.z,
			container.rectangle.w - container.headerHeight,
		}

		append(&container.commands, SetScissorCommand{rectangle = contentRectangle})
	}

	return container.isOpen && container.isExpanded
}

// @ref
// Renders a clickable button. Returns **true** if clicked this frame.
//
// Must be used within a **Window if-block**.
button :: proc(
	label: string,
	isInline: bool = false,
	config: ButtonConfig = DEFAULT_BUTTON_CONFIG,
) -> bool {
	parent := state.currentContainer
	if parent == nil {
		log.error("No parent container set. Button", label, "can't be drawn.")
		return false
	}

	style := _resolveButtonStyle(config)

	rectangle, isVisible := _calculateObjectLayout(
		parent,
		label,
		style.pivot,
		style.padding,
		style.margin,
		isInline,
	)

	if !isVisible do return false

	id := getId(label)

	return _handleButtonInteractionAndDraw(id, rectangle, label, style, parent)
}


// @ref
// Renders a **static text label**.
//
// Must be used within a **Window if-block**.
text :: proc(text: string, isInline: bool = false, config: TextConfig = DEFAULT_TEXT_CONFIG) {
	parent := state.currentContainer
	if parent == nil {
		log.error("No parent container set. Text", text, "can't be drawn.")
		return
	}

	style := _resolveTextStyle(config)

	rectangle, isVisible := _calculateObjectLayout(
		parent,
		text,
		style.pivot,
		style.padding,
		style.margin,
		isInline,
	)
	if !isVisible do return

	_drawText(text, rectangle, style)
}

// @ref
// Renders a boolean checkbox toggle.
// Modifies the **value** pointer directly. Returns **true** if the state has changed this frame.
//
// Must be used within a **Window if-block**.
checkbox :: proc(
	value: ^bool,
	isInline: bool = false,
	config: CheckboxConfig = DEFAULT_CHECKBOX_CONFIG,
) -> bool {
	parent := state.currentContainer

	style := _resolveCheckboxStyle(config)

	checkboxString := " "
	if value^ {
		checkboxString = fmt.tprintf("%r", style.checkboxRune)
	}

	id := getId(checkboxString)

	rectangle, isVisible := _calculateObjectLayout(
		parent,
		checkboxString,
		style.pivot,
		style.padding,
		style.margin,
		isInline,
		true, // force square
		style.checkboxRuneScale,
	)

	if !isVisible do return false

	clicked := _handleCheckboxInteractionAndDraw(
		value,
		rectangle,
		parent,
		id,
		style,
		checkboxString,
		style.checkboxRuneScale,
	)

	if clicked {
		value^ = !value^
	}

	return clicked
}

// @ref
// Renders a **draggable slider** for numeric types (**int**, **float**, etc.).
// Returns **true** if the value changed this frame.
//
// Must be used within a **Window if-block**.
slider :: proc(
	value: ^$T,
	minimumValue: T,
	maximumValue: T,
	isInline: bool = false,
	config: SliderConfig = DEFAULT_SLIDER_CONFIG,
) -> bool where intrinsics.type_is_numeric(T) {
	parent := state.currentContainer

	style := _resolveSliderStyle(config)

	// create unique id based on parent id and widget count, since sliders dont have any labels
	id := getId(fmt.tprintf("slider_%d_%d", parent.id, parent.widgetCount))

	currentValueF32 := f32(value^)
	minimumValueF32 := f32(minimumValue)
	maximumValueF32 := f32(maximumValue)

	newValueF32 := _handleSliderInteractionAndDraw(
		id,
		parent,
		isInline,
		style,
		currentValueF32,
		minimumValueF32,
		maximumValueF32,
		intrinsics.type_is_integer(T),
	)

	if intrinsics.type_is_integer(T) {
		value^ = T(math.round(newValueF32))
	} else {
		value^ = T(newValueF32)
	}

	return currentValueF32 != newValueF32
}

@(private = "package")
_closeButton :: proc(
	normalColor, hoverColor, activeColor: gmath.Vector4,
	closeRune: rune,
) -> bool {
	parent := state.currentContainer

	// create unique id based on parent id and rune
	id := getId(fmt.tprintf("close_%d_%r", parent.id, closeRune))

	size := gmath.Vector2{parent.closeWidth, parent.headerHeight}
	position := gmath.Vector2 {
		parent.rectangle.z - size.x,
		parent.rectangle.w - size.y - f32(DEFAULT_FONT_SIZE / 8),
	}

	clicked, _ := _headerButton(
		id,
		position,
		size,
		normalColor,
		hoverColor,
		activeColor,
		closeRune,
	)

	// returns true if the window is still meant to be open
	return !clicked
}

@(private = "package")
_toggleButton :: proc(
	normalColor, hoverColor, activeColor: gmath.Vector4,
	toggleRune: rune,
) -> Maybe(bool) {
	parent := state.currentContainer

	// create unique id based on parent id and rune
	id := getId(fmt.tprintf("%v_%r", parent.id, toggleRune))

	size := gmath.Vector2{parent.toggleWidth, parent.headerHeight}
	position := gmath.Vector2 {
		parent.rectangle.x,
		parent.rectangle.w - size.y - f32(DEFAULT_FONT_SIZE / 8),
	}

	// rotate caret when expanded
	rotation: f32 = parent.isExpanded ? gmath.PI : 0.0
	offset := parent.isExpanded ? gmath.Vector2{0, 3} : gmath.Vector2{2, 0}

	clicked, _ := _headerButton(
		id,
		position,
		size,
		normalColor,
		hoverColor,
		activeColor,
		toggleRune,
		rotation,
		offset,
	)

	if clicked {
		return !parent.isExpanded
	}
	return nil
}
