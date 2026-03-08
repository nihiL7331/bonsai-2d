package ui

import "bonsai:core/clock"
import "bonsai:core/gmath"
import "bonsai:core/input"
import "bonsai:core/render"

import "base:intrinsics"
import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:unicode/utf8"

when !ODIN_DEBUG {
	_ :: reflect
	_ :: gmath
	_ :: strings
	_ :: input
	_ :: render
	_ :: clock
	_ :: utf8
	_ :: fmt
}

// @ref
// Shows a tooltip if the **previous** widget is hovered.
// Call this immediately after the widget you want to describe.
tooltip :: proc(text: string) {
	when ODIN_DEBUG {
		isHovered := gmath.rectangleContains(_ui.lastWidgetRectangle, _ui.mousePosition)
		if isHovered && _ui.currentWindowId == _ui.hoveredWindowId {
			_ui.tooltipText = strings.clone(text, context.temp_allocator)
		}
	}
}

// @ref
// Draws a color picker (preview box + RGB(A) sliders).
// Returns `true` if the color changed.
colorPicker :: proc(label: string, color: ^gmath.Color, alpha: bool = true) -> bool {
	when ODIN_DEBUG {
		changed := false

		if header(label) {
			indent()

			previewRectangle := _advance(DEFAULT_STYLE.colorPreviewWidth, DEFAULT_STYLE.itemHeight)
			_pushRectangle(previewRectangle, color^, true)
			_pushRectangle(previewRectangle, DEFAULT_STYLE.textColor, true, true)

			r := color.r
			if slider(&r, 0.0, 1.0, "R") {
				color.r = r
				changed = true
			}

			g := color.g
			if slider(&g, 0.0, 1.0, "G") {
				color.g = g
				changed = true
			}

			b := color.b
			if slider(&b, 0.0, 1.0, "B") {
				color.b = b
				changed = true
			}

			if alpha {
				a := color.a
				if slider(&a, 0.0, 1.0, "A") {
					color.a = a
					changed = true
				}
			}
			unindent()
		}

		return changed
	} else {
		return false
	}
}

// @ref
// Draws a simple line plot for a slice of numbers.
// Useful for FPS counters or physics debugging.
plot :: proc(
	label: string,
	values: []f32,
	minimumValue: f32 = 0.0,
	maximumValue: f32 = 0.0,
	height: f32 = 0.0,
) {
	when ODIN_DEBUG {
		width := getAvailableWidth()
		actualHeight := height
		if actualHeight == 0 {
			actualHeight = DEFAULT_STYLE.plotHeight
		}

		rectangle := _advance(width, actualHeight)

		if !isRectangleVisible(rectangle) do return

		_pushScissor(gmath.rectangleExpand(rectangle, DEFAULT_STYLE.outlineThickness * 2))

		_pushRectangle(
			rectangle,
			DEFAULT_STYLE.backgroundColor,
			isRounding = false,
			isOutline = false,
		)

		actualMinimum := minimumValue
		actualMaximum := maximumValue

		if minimumValue == 0 && maximumValue == 0 {
			actualMinimum = values[0]
			actualMaximum = values[0]
			for value in values {
				if value < actualMinimum {
					actualMinimum = value
				} else if value > actualMaximum {
					actualMaximum = value
				}
				if actualMinimum == actualMaximum {
					actualMaximum += 1.0
				}
			}
		}

		range := actualMaximum - actualMinimum
		if range == 0 {
			range = 1.0
		}

		gridColor := DEFAULT_STYLE.textColor
		gridColor.a = 0.3

		isHovered := gmath.rectangleContains(rectangle, _ui.mousePosition)
		hoverIndex := -1

		if isHovered {
			relativeX := _ui.mousePosition.x - rectangle.x
			rectangleWidth := rectangle.z - rectangle.x
			hoverIndex = int((relativeX / rectangleWidth) * f32(len(values)))
			hoverIndex = gmath.clamp(hoverIndex, 0, len(values) - 1)
		}

		drawGridLine :: proc(
			value: f32,
			rect: gmath.Rectangle,
			minValue, maxValue: f32,
			col: gmath.Color,
			showText: bool,
		) {
			ratio := gmath.remap(value, minValue, maxValue, 0.0, rect.w - rect.y)
			y := rect.y + ratio

			_pushLine(gmath.Vector2{rect.x, y}, gmath.Vector2{rect.z, y}, col)

			if showText {
				text := fmt.tprintf("%.1f", value)
				textY := y
				if ratio > 0.9 {
					textY = y - f32(DEFAULT_STYLE.fontSize)
				}
				_pushText(gmath.Vector2{rect.x + 2, textY}, text, col)
			}
		}

		if actualMinimum < 0 && actualMaximum > 0 {
			drawGridLine(
				0,
				rectangle,
				actualMinimum,
				actualMaximum,
				gmath.Color{1, 1, 1, 0.5},
				false,
			)
		}

		drawGridLine(actualMinimum, rectangle, actualMinimum, actualMaximum, gridColor, true)
		drawGridLine(actualMaximum, rectangle, actualMinimum, actualMaximum, gridColor, true)

		count := len(values)
		if count > 1 {
			stepX := (rectangle.z - rectangle.x) / f32(count - 1)
			previousPosition: gmath.Vector2

			for i in 0 ..< count {
				value := values[i]
				ratio := gmath.remap(
					value,
					actualMinimum,
					actualMaximum,
					0.0,
					rectangle.w - rectangle.y,
				)

				position := gmath.Vector2{rectangle.x + f32(i) * stepX, rectangle.y + ratio}

				if i == hoverIndex {
					_pushLine(
						gmath.Vector2{position.x, rectangle.y},
						gmath.Vector2{position.x, rectangle.w},
						gmath.Color{1.0, 1.0, 1.0, 0.5},
					)
					tooltip(fmt.tprintf("%.2f", values[i]))
				}

				if i > 0 {
					_pushLine(previousPosition, position, DEFAULT_STYLE.textColor)
				}
				previousPosition = position
			}

			endRatio := gmath.remap(values[count - 1], actualMinimum, actualMaximum, 0.0, 1.0)
			if endRatio > 0.1 && endRatio < 0.9 {
				drawGridLine(
					values[count - 1],
					rectangle,
					actualMinimum,
					actualMaximum,
					gridColor,
					true,
				)
			}

			startRatio := gmath.remap(values[0], actualMinimum, actualMaximum, 0.0, 1.0)
			if startRatio > 0.1 && startRatio < 0.9 && abs(startRatio - endRatio) > 0.1 {
				drawGridLine(values[0], rectangle, actualMinimum, actualMaximum, gridColor, true)
			}
		}

		_pushRectangle(rectangle, DEFAULT_STYLE.textColor, isRounding = false, isOutline = true)

		latestValue := values[count - 1]
		titleText := fmt.tprintf("%s\n%.2f", label, latestValue)
		_pushText(
			gmath.Vector2 {
				rectangle.z - DEFAULT_STYLE.padding,
				rectangle.w - DEFAULT_STYLE.padding,
			},
			titleText,
			DEFAULT_STYLE.textColor,
			.topRight,
		)
		_popScissor()
	}
}

// @ref
// Draws a static text label.
label :: proc(text: string) {
	when ODIN_DEBUG {
		textSize := render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, text)
		rectangle := _advance(textSize.x, max(textSize.y, DEFAULT_STYLE.itemHeight))

		if !isRectangleVisible(rectangle) do return

		_pushText(
			gmath.getRectangleCenter(rectangle),
			text,
			DEFAULT_STYLE.textColor,
			.centerCenter,
		)
	}
}

// @ref
// Starts a tab bar container.
// Must be followed by [`tabItem`](#tabitem)
// calls and ended with [`endTabBar`](#endtabbar).
beginTabBar :: proc(idString: string) -> bool {
	when ODIN_DEBUG {
		id := _getId(idString)

		_ui.currentTabBarId = id

		beginRow()
		return true
	} else {
		return false
	}
}

// @ref
// Ends the tab bar container.
endTabBar :: proc() {
	when ODIN_DEBUG {
		endRow()
		separator()

		_ui.cursor.y -= _ui.tabContentHeight
		_ui.tabContentHeight = 0
		_ui.currentTabBarId = 0
	}
}

// @ref
// Draws a tab button.
// Returns `true` if this tab is currently selected.
beginTabItem :: proc(label: string) -> bool {
	when ODIN_DEBUG {
		id := _getId(label)
		barId := _ui.currentTabBarId
		if barId == 0 do return false

		activeId := _ui.tabBars[barId]
		if activeId == 0 {
			activeId = id
			_ui.tabBars[barId] = id
		}

		isActive := activeId == id

		width :=
			render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, label).x +
			DEFAULT_STYLE.padding * 2
		rectangle := _advance(width, DEFAULT_STYLE.itemHeight)

		isHovered, isClicked, _ := _interact(rectangle, id)

		if isClicked {
			_ui.tabBars[barId] = id
			isActive = true
		}

		color := DEFAULT_STYLE.backgroundColor
		if isActive {
			color = DEFAULT_STYLE.activeColor
		} else if isHovered {
			color = DEFAULT_STYLE.hotColor
		}

		_pushRectangle(rectangle, color, isRounding = true)
		_pushText(
			gmath.getRectangleCenter(rectangle),
			label,
			DEFAULT_STYLE.textColor,
			.centerCenter,
		)

		if isActive {
			_ui.tabSavedCursor = _ui.cursor
			_ui.inRow = false
			_ui.cursor.x = _ui.startX + _ui.indentation
			_ui.cursor.y -=
				(DEFAULT_STYLE.itemHeight +
					DEFAULT_STYLE.padding * 2 +
					DEFAULT_STYLE.separatorHeight)

			return true
		}
		return false
	} else {
		return false
	}
}

// @ref
// Ends the current tab item content block.
// Must be called if [`beginTabItem`](#begintabitem) returns true.
endTabItem :: proc() {
	when ODIN_DEBUG {
		contentTop := _ui.tabSavedCursor.y - DEFAULT_STYLE.itemHeight - DEFAULT_STYLE.padding
		height := contentTop - _ui.cursor.y

		_ui.tabContentHeight = height

		_ui.cursor = _ui.tabSavedCursor
		_ui.inRow = true
	}
}

// @ref
// Draws a slider.
// Modifies `value` directly via a pointer.
// Returns `true` if the value was changed this frame.
// Function overload for [`sliderFloat`](#sliderfloat)/[`sliderInteger`](#sliderinteger)
slider :: proc {
	sliderFloat,
	sliderInteger,
}

// @ref
// Draws a float slider.
sliderFloat :: proc(
	value: ^f32,
	minimumValue: f32,
	maximumValue: f32,
	label: string = "",
	width: f32 = 60.0,
	step: f32 = 0.0,
) -> bool {
	when ODIN_DEBUG {
		id := _getIdPointer(label, rawptr(value))

		totalWidth := width
		textSize := gmath.Vector2{0, 0}

		if len(label) > 0 {
			textSize = render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, label)
			totalWidth += DEFAULT_STYLE.padding + textSize.x
		}

		rectangle := _advance(totalWidth, DEFAULT_STYLE.itemHeight)

		if !isRectangleVisible(rectangle) do return false

		sliderRectangle := gmath.Rectangle {
			rectangle.x,
			rectangle.y,
			rectangle.x + width,
			rectangle.w,
		}

		_, _, isActive := _interact(sliderRectangle, id)
		valueChanged := false

		if isActive {
			sliderWidth := sliderRectangle.z - sliderRectangle.x
			mouseOffset := _ui.mousePosition.x - sliderRectangle.x
			ratio := gmath.clamp(mouseOffset / sliderWidth, 0.0, 1.0)
			newValue := gmath.lerp(minimumValue, maximumValue, ratio)
			if step > 0 {
				newValue = gmath.round(newValue / step) * step
			}

			if value^ != newValue {
				value^ = newValue
				valueChanged = true
			}
		}

		_pushRectangle(sliderRectangle, DEFAULT_STYLE.backgroundColor, true)

		if step > 0 {
			range := maximumValue - minimumValue
			stepCount := range / step

			sliderWidth := sliderRectangle.z - sliderRectangle.x
			pixelsPerStep := sliderWidth / stepCount

			if pixelsPerStep > 10.0 {
				count := int(gmath.round(stepCount))

				for i in 1 ..< count {
					ratio := f32(i) / f32(count)
					lineX := sliderRectangle.x + (sliderWidth * ratio)

					_pushLine(
						gmath.Vector2{lineX, sliderRectangle.y},
						gmath.Vector2{lineX, sliderRectangle.w},
						DEFAULT_STYLE.activeColor,
					)
				}
			}
		}

		currentRatio := gmath.remap(value^, minimumValue, maximumValue, 0.0, 1.0)
		sliderWidth := sliderRectangle.z - sliderRectangle.x
		fillWidth := sliderWidth * currentRatio

		fillRectangle := gmath.Rectangle {
			sliderRectangle.x,
			sliderRectangle.y,
			sliderRectangle.x + fillWidth,
			sliderRectangle.w,
		}

		_pushRectangle(fillRectangle, DEFAULT_STYLE.activeColor, true)
		_pushRectangle(sliderRectangle, DEFAULT_STYLE.textColor, true, true)

		precision := 2
		if step > 0 {
			precision = 0
			if step >= 1.0 {
			} else {
				val := f64(step)

				for precision < 6 {
					if gmath.almostEquals(val, gmath.round(val), 0.001) {
						break
					}
					val *= 10.0
					precision += 1
				}
			}
		}

		fmtString := fmt.tprintf("%%.%df", precision)
		valueText := fmt.tprintf(fmtString, value^)
		textCenter := gmath.getRectangleCenter(sliderRectangle)
		_pushText(textCenter, valueText, DEFAULT_STYLE.textColor, .centerCenter)

		if len(label) > 0 {
			textPosition := gmath.Vector2 {
				sliderRectangle.z + DEFAULT_STYLE.padding,
				sliderRectangle.y + (DEFAULT_STYLE.itemHeight * 0.5),
			}

			_pushText(textPosition, label, DEFAULT_STYLE.textColor, .centerLeft)
		}

		return valueChanged
	} else {
		return false
	}
}

// @ref
// Draws a integer slider.
sliderInteger :: proc(
	value: ^int,
	minimumValue: int,
	maximumValue: int,
	label: string = "",
	width: f32 = 60.0,
	step: int = 1,
) -> bool {
	floatValue := f32(value^)
	floatMinimum := f32(minimumValue)
	floatMaximum := f32(maximumValue)
	floatStep := f32(step)

	if slider(&floatValue, floatMinimum, floatMaximum, label, width, floatStep) {
		value^ = int(floatValue)
		return true
	}

	return false
}

// @ref
// Draws a clickable button.
// Returns `true` if clicked.
button :: proc(text: string, width: f32 = 60.0) -> bool {
	when ODIN_DEBUG {
		id := _getId(text)
		rectangle := _advance(width, DEFAULT_STYLE.itemHeight)

		if !isRectangleVisible(rectangle) do return false

		isHovered, isClicked, isActive := _interact(rectangle, id)

		color := DEFAULT_STYLE.buttonColor
		if isHovered {
			color = DEFAULT_STYLE.hotColor
		}
		if isActive {
			color = DEFAULT_STYLE.activeColor
		}

		_pushRectangle(rectangle, color, true)

		_pushText(
			gmath.getRectangleCenter(rectangle),
			text,
			DEFAULT_STYLE.textColor,
			.centerCenter,
		)

		return isClicked
	} else {
		return false
	}
}

// @ref
// Draws a text input field that modifies a string directly.
// Manages a temporary builder internally.
// Updates `text` only when **enter** is pressed or focus is lost.
// Returns `true` if the user pressed **enter**.
inputText :: proc(text: ^string, label: string = "", width: f32 = 60.0) -> bool {
	when ODIN_DEBUG {
		id := _getIdPointer(label, text)
		committed := false

		if _ui.activeId == id {
			builder, exists := &_ui.inputBuffers[id]
			if !exists {
				_ui.activeId = 0
				return false
			}

			if inputTextBuilder(label, builder, width, idOverride = id) {
				committed = true
			}

			if _ui.activeId != id {
				text^ = strings.clone(strings.to_string(builder^))
				strings.builder_destroy(builder)
				delete_key(&_ui.inputBuffers, id)
			}
		} else {
			temporaryBuilder := strings.builder_make(context.temp_allocator)
			strings.write_string(&temporaryBuilder, text^)

			inputTextBuilder(label, &temporaryBuilder, width, idOverride = id)

			if _ui.activeId == id {
				newBuilder := strings.builder_make()
				strings.write_string(&newBuilder, text^)
				_ui.inputBuffers[id] = newBuilder
			}
		}

		return committed
	} else {
		return false
	}
}

// @ref
// Low-level builder for text input.
// Handles the core interaction and rendering logic for [`inputText`](#inputtext)
inputTextBuilder :: proc(
	label: string,
	builder: ^strings.Builder,
	width: f32 = 60.0,
	idOverride: u64 = 0,
) -> bool {
	when ODIN_DEBUG {
		id := idOverride
		if id == 0 {
			id = _getIdPointer(label, builder)
		}

		labelSize := gmath.Vector2{0, 0}
		if len(label) > 0 {
			labelSize = render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, label)
		}

		totalWidth := width
		if len(label) > 0 {
			totalWidth += DEFAULT_STYLE.padding + labelSize.x
		}
		rectangle := _advance(totalWidth, DEFAULT_STYLE.itemHeight)

		if !isRectangleVisible(rectangle) do return false

		boxRectangle := gmath.Rectangle{rectangle.x, rectangle.y, rectangle.x + width, rectangle.w}

		isHovered :=
			gmath.rectangleContains(boxRectangle, _ui.mousePosition) &&
			_ui.currentWindowId == _ui.hoveredWindowId

		if input.isKeyPressedRaw(.LEFT_MOUSE) {
			if isHovered {
				_ui.activeId = id
				input.consumeKeyPressed(.LEFT_MOUSE)
			} else if _ui.activeId == id {
				_ui.activeId = 0
				input.setCaptured(false)
			}
		}

		committed := false
		if _ui.activeId == id {
			input.setCaptured(true)

			characterQueue := input.getCharacterQueue()
			for character in characterQueue {
				strings.write_rune(builder, character)
			}

			if input.isKeyPressedRaw(.BACKSPACE) {
				textLength := len(builder.buf)
				if textLength > 0 {
					_, width := utf8.decode_last_rune(builder.buf[:])
					if width > 0 {
						resize(&builder.buf, textLength - width)
					}
				}
			}

			if input.isKeyPressedRaw(.ENTER) {
				_ui.activeId = 0
				input.setCaptured(false)
				committed = true
			}

			if input.isKeyPressedRaw(.ESC) {
				_ui.activeId = 0
				input.setCaptured(false)
			}
		}

		backgroundColor := DEFAULT_STYLE.backgroundColor
		if _ui.activeId == id {
			backgroundColor = DEFAULT_STYLE.activeColor
		}
		_pushRectangle(boxRectangle, backgroundColor, true)
		_pushRectangle(boxRectangle, DEFAULT_STYLE.textColor, true, true)

		textString := strings.to_string(builder^)

		scissorRectangle := gmath.Rectangle {
			boxRectangle.x + 2,
			boxRectangle.y,
			boxRectangle.z - 2,
			boxRectangle.w,
		}

		_pushScissor(scissorRectangle)

		textPosition := gmath.Vector2 {
			boxRectangle.x + DEFAULT_STYLE.padding,
			boxRectangle.y + (DEFAULT_STYLE.itemHeight * 0.5),
		}

		_pushText(
			textPosition,
			strings.clone(textString, context.temp_allocator),
			DEFAULT_STYLE.textColor,
			.centerLeft,
		)

		if _ui.activeId == id {
			textSize := render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, textString)
			cursorX := textPosition.x + textSize.x + 1

			BLINK_INTERVAL :: 0.5
			time := clock.getApplicationTime()

			if int(time / BLINK_INTERVAL) % 2 == 0 {
				cursorHeight := f32(DEFAULT_STYLE.fontSize)
				_pushLine(
					gmath.Vector2{cursorX, textPosition.y - (cursorHeight * 0.5)},
					gmath.Vector2{cursorX, textPosition.y + (cursorHeight * 0.5)},
					DEFAULT_STYLE.textColor,
				)
			}
		}

		_popScissor()

		if len(label) > 0 {
			labelPosition := gmath.Vector2 {
				boxRectangle.z + DEFAULT_STYLE.padding,
				rectangle.y + (DEFAULT_STYLE.itemHeight * 0.5),
			}

			_pushText(labelPosition, label, DEFAULT_STYLE.textColor, .centerLeft)
		}

		return committed
	} else {
		return false
	}
}

// @ref
// Draws a checkbox.
// Modifies `value` directly via a pointer.
// Returns `true` if the value was toggled this frame.
checkbox :: proc(label: string, value: ^bool) -> bool {
	when ODIN_DEBUG {
		id := _getIdPointer(label, rawptr(value))

		boxSize := DEFAULT_STYLE.itemHeight
		textPadding := DEFAULT_STYLE.padding

		textSize := render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, label)
		totalWidth := boxSize + textPadding + textSize.x

		rectangle := _advance(totalWidth, DEFAULT_STYLE.itemHeight)

		if !isRectangleVisible(rectangle) do return false

		_, isClicked, _ := _interact(rectangle, id)

		if isClicked {
			value^ = !value^
		}

		boxRectangle := gmath.rectangleMake(rectangle.xy, gmath.Vector2{boxSize, boxSize})

		_pushRectangle(boxRectangle, DEFAULT_STYLE.textColor, true, true)

		if value^ {
			innerRectangle := gmath.rectangleExpand(boxRectangle, -2)
			_pushLine(
				gmath.Vector2{innerRectangle.x, innerRectangle.y},
				gmath.Vector2{innerRectangle.z, innerRectangle.w},
				DEFAULT_STYLE.textColor,
			)
			_pushLine(
				gmath.Vector2{innerRectangle.x, innerRectangle.w},
				gmath.Vector2{innerRectangle.z, innerRectangle.y},
				DEFAULT_STYLE.textColor,
			)
		}

		textPosition := gmath.Vector2 {
			rectangle.x + boxSize + textPadding,
			rectangle.y + DEFAULT_STYLE.itemHeight * 0.5,
		}

		_pushText(textPosition, label, DEFAULT_STYLE.textColor, .centerLeft)

		return isClicked
	} else {
		return false
	}
}

// @ref
// Starts a dropdown menu (combo box).
// - `preview`: The text to display on the closed button.
// Returns `true` if the dropdown is open and items should be rendered.
// **Must** be ended with [`endCombo`](#endcombo).
beginCombo :: proc(label: string, preview: string, width: f32 = 50.0) -> bool {
	when ODIN_DEBUG {
		id := _getId(label)

		labelSize := render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, label)
		totalWidth := width + DEFAULT_STYLE.padding + labelSize.x

		rectangle := _advance(totalWidth, DEFAULT_STYLE.itemHeight)
		buttonRectangle := gmath.Rectangle {
			rectangle.x,
			rectangle.y,
			rectangle.x + width,
			rectangle.w,
		}

		isHovered, isClicked, _ := _interact(buttonRectangle, id)

		if isClicked {
			if _ui.openComboId == id {
				_ui.openComboId = 0
			} else {
				_ui.openComboId = id
				_ui.activeId = 0
			}
			input.consumeKeyPressed(.LEFT_MOUSE)
		}

		buttonColor := DEFAULT_STYLE.buttonColor
		if isHovered {
			buttonColor = DEFAULT_STYLE.hotColor
		}

		_pushRectangle(buttonRectangle, buttonColor, isRounding = true)
		_pushRectangle(
			buttonRectangle,
			DEFAULT_STYLE.textColor,
			isRounding = true,
			isOutline = true,
		)

		dropdownSize := DEFAULT_STYLE.itemHeight * 0.25
		dropdownCenter := gmath.Vector2 {
			buttonRectangle.z -
			DEFAULT_STYLE.outlineThickness -
			DEFAULT_STYLE.padding -
			dropdownSize * 0.5,
			buttonRectangle.y + DEFAULT_STYLE.itemHeight * 0.5,
		}
		point1 := dropdownCenter + gmath.Vector2{-dropdownSize, dropdownSize * 0.5}
		point2 := dropdownCenter + gmath.Vector2{dropdownSize, dropdownSize * 0.5}
		point3 := dropdownCenter + gmath.Vector2{0, -dropdownSize * 0.8}
		_pushTriangle(point1, point2, point3, DEFAULT_STYLE.textColor)

		_pushText(
			gmath.getRectangleCenter(buttonRectangle),
			preview,
			DEFAULT_STYLE.textColor,
			.centerCenter,
		)

		if len(label) > 0 {
			textPosition := gmath.Vector2 {
				buttonRectangle.z + DEFAULT_STYLE.padding,
				rectangle.y + DEFAULT_STYLE.itemHeight * 0.5,
			}
			_pushText(textPosition, label, DEFAULT_STYLE.textColor, .centerLeft)
		}

		if _ui.openComboId == id {
			_ui.isRecordingPopup = true
			_ui.popupCursor = gmath.Vector2 {
				buttonRectangle.x,
				buttonRectangle.y - DEFAULT_STYLE.padding,
			}
			_ui.comboWidth = width
			return true
		}

		return false
	} else {
		return false
	}
}

// @ref
// Ends the dropdown menu block.
// Must be called if [`beginCombo`](#begincombo) returns `true`.
endCombo :: proc() {
	when ODIN_DEBUG {
		_ui.isRecordingPopup = false

		if input.isKeyPressed(.LEFT_MOUSE) && _ui.openComboId != 0 {
			_ui.openComboId = 0
		}
	}
}

// @ref
// Draws a selectable item inside a dropdown menu.
// Returns `true` if clicked.
selectable :: proc(text: string, selected: bool) -> bool {
	when ODIN_DEBUG {
		rectangle := _advance(_ui.comboWidth, DEFAULT_STYLE.itemHeight)

		isHovered := gmath.rectangleContains(rectangle, _ui.mousePosition)

		clicked := false
		if isHovered {
			_pushRectangle(rectangle, DEFAULT_STYLE.hotColor, isRounding = true)

			if input.isKeyPressed(.LEFT_MOUSE) {
				clicked = true
				_ui.openComboId = 0
				input.consumeKeyPressed(.LEFT_MOUSE)
			}
		} else if selected {
			_pushRectangle(rectangle, DEFAULT_STYLE.activeColor, isRounding = true)
		} else {
			_pushRectangle(rectangle, DEFAULT_STYLE.buttonColor, isRounding = true)
		}

		_pushText(
			gmath.getRectangleCenter(rectangle),
			text,
			DEFAULT_STYLE.textColor,
			.centerCenter,
		)

		return clicked
	} else {
		return false
	}
}

// @ref
// Draws a combo box that selects an index from a list of strings.
// - `currentItemIndex`: Pointer to the index of the selected item
// - `items`: Slice of strings to display.
// Returns `true` if the selection changed.
comboString :: proc(
	label: string,
	currentItemIndex: ^int,
	items: []string,
	width: f32 = 50.0,
) -> bool {
	when ODIN_DEBUG {
		changed := false

		if currentItemIndex == nil || len(items) == 0 do return false

		if currentItemIndex^ < 0 {
			currentItemIndex^ = 0
		}
		if currentItemIndex^ >= len(items) {
			currentItemIndex^ = len(items) - 1
		}

		preview := items[currentItemIndex^]

		if beginCombo(label, preview, width) {
			for item, i in items {
				if selectable(item, i == currentItemIndex^) {
					currentItemIndex^ = i
					changed = true
				}
			}
			endCombo()
		}

		return changed
	} else {
		return false
	}
}

// @ref
// Draws a combo box for any `enum`.
// Automatically extracts enum names.
// - `value`: Pointer to the enum variable.
comboEnum :: proc(
	label: string,
	value: ^$T,
	width: f32 = 50.0,
) -> bool where intrinsics.type_is_enum(T) {
	when ODIN_DEBUG {
		changed := false

		typeInfo := type_info_of(T)
		if named, isNamed := typeInfo.variant.(reflect.Type_Info_Named); isNamed {
			typeInfo = named.base
		}
		enumInfo := typeInfo.variant.(reflect.Type_Info_Enum)

		currentIndex := 0
		currentValueRaw := i64(0)

		switch size_of(T) {
		case 1:
			currentValueRaw = i64((^i8)(value)^)
		case 2:
			currentValueRaw = i64((^i16)(value)^)
		case 4:
			currentValueRaw = i64((^i32)(value)^)
		case 8:
			currentValueRaw = i64((^i64)(value)^)
		}

		for enumValue, i in enumInfo.values {
			if i64(enumValue) == currentValueRaw {
				currentIndex = i
				break
			}
		}

		preview := enumInfo.names[currentIndex]

		if beginCombo(label, preview, width) {
			for name, i in enumInfo.names {
				if selectable(name, i == currentIndex) {
					newValue := enumInfo.values[i]

					switch size_of(T) {
					case 1:
						(^i8)(value)^ = i8(newValue)
					case 2:
						(^i16)(value)^ = i16(newValue)
					case 4:
						(^i32)(value)^ = i32(newValue)
					case 8:
						(^i64)(value)^ = i64(newValue)
					}

					changed = true
				}
			}

			endCombo()
		}

		return changed
	} else {
		return false
	}
}

// internal helper to handle standard widget interaction.
// returns the state flags for the widget.
@(private = "file")
_interact :: proc(
	rectangle: gmath.Rectangle,
	id: u64,
) -> (
	isHovered: bool,
	isClicked: bool,
	isActive: bool,
) {
	when ODIN_DEBUG {
		if _ui.openComboId != 0 && id != _ui.openComboId do return false, false, false

		isHovered =
			gmath.rectangleContains(rectangle, _ui.mousePosition) &&
			_ui.currentWindowId == _ui.hoveredWindowId

		if isHovered {
			_ui.hotId = id
			if _ui.activeId == 0 && input.isKeyPressed(.LEFT_MOUSE) {
				_ui.activeId = id
			}
		}

		isActive = _ui.activeId == id

		if isActive && input.isKeyReleased(.LEFT_MOUSE) && isHovered {
			isClicked = true
		}

		return
	} else {
		return false, false, false
	}
}
