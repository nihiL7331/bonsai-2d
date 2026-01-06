package ui

import "bonsai:core/gmath"
import "bonsai:core/input"
import "bonsai:core/render"

import "core:fmt"
import "core:math"

@(private = "package")
_resolveWindowStyle :: proc(config: WindowConfig) -> (style: WindowStyle) {
	// LAYOUT
	style.maximumHeight = config.maximumHeight.? or_else DEFAULT_WINDOW_CONFIG.maximumHeight.?

	// COLORS
	style.backgroundColor =
		config.backgroundColor.? or_else DEFAULT_WINDOW_CONFIG.backgroundColor.?
	style.borderColor = config.borderColor.? or_else DEFAULT_WINDOW_CONFIG.borderColor.?

	// HEADER
	style.headerMargin = config.headerMargin.? or_else DEFAULT_WINDOW_CONFIG.headerMargin.?

	style.headerBackgroundNormalColor =
		config.headerBackgroundNormalColor.? or_else DEFAULT_WINDOW_CONFIG.headerBackgroundNormalColor.?
	style.headerBackgroundHoverColor =
		config.headerBackgroundHoverColor.? or_else DEFAULT_WINDOW_CONFIG.headerBackgroundHoverColor.?
	style.headerBackgroundActiveColor =
		config.headerBackgroundActiveColor.? or_else DEFAULT_WINDOW_CONFIG.headerBackgroundActiveColor.?

	style.headerTextNormalColor =
		config.headerTextNormalColor.? or_else DEFAULT_WINDOW_CONFIG.headerTextNormalColor.?
	style.headerTextHoverColor =
		config.headerTextHoverColor.? or_else DEFAULT_WINDOW_CONFIG.headerTextHoverColor.?
	style.headerTextActiveColor =
		config.headerTextActiveColor.? or_else DEFAULT_WINDOW_CONFIG.headerTextActiveColor.?

	// CLOSE BUTTON
	style.closeNormalColor =
		config.closeNormalColor.? or_else DEFAULT_WINDOW_CONFIG.closeNormalColor.?
	style.closeHoverColor =
		config.closeHoverColor.? or_else DEFAULT_WINDOW_CONFIG.closeHoverColor.?
	style.closeActiveColor =
		config.closeActiveColor.? or_else DEFAULT_WINDOW_CONFIG.closeActiveColor.?
	style.closeRune = config.closeRune.? or_else DEFAULT_WINDOW_CONFIG.closeRune.?

	// TOGGLE BUTTON
	style.toggleNormalColor =
		config.toggleNormalColor.? or_else DEFAULT_WINDOW_CONFIG.toggleNormalColor.?
	style.toggleHoverColor =
		config.toggleHoverColor.? or_else DEFAULT_WINDOW_CONFIG.toggleHoverColor.?
	style.toggleActiveColor =
		config.toggleActiveColor.? or_else DEFAULT_WINDOW_CONFIG.toggleActiveColor.?
	style.toggleRune = config.toggleRune.? or_else DEFAULT_WINDOW_CONFIG.toggleRune.?

	// SCROLLBAR
	style.scrollbarBackgroundColor =
		config.scrollbarBackgroundColor.? or_else DEFAULT_WINDOW_CONFIG.scrollbarBackgroundColor.?
	style.scrollbarThumbColor =
		config.scrollbarThumbColor.? or_else DEFAULT_WINDOW_CONFIG.scrollbarThumbColor.?
	style.scrollbarWidth = config.scrollbarWidth.? or_else DEFAULT_WINDOW_CONFIG.scrollbarWidth.?
	style.scrollbarSpeed = config.scrollbarSpeed.? or_else DEFAULT_WINDOW_CONFIG.scrollbarSpeed.?

	return style
}

@(private = "package")
_resolveButtonStyle :: proc(config: ButtonConfig) -> (style: ButtonStyle) {
	// LAYOUT
	style.pivot = config.pivot.? or_else DEFAULT_BUTTON_CONFIG.pivot.?
	style.padding = config.padding.? or_else DEFAULT_BUTTON_CONFIG.padding.?
	style.margin = config.margin.? or_else DEFAULT_BUTTON_CONFIG.margin.?

	// BACKGROUND COLOR
	style.backgroundNormalColor =
		config.backgroundNormalColor.? or_else DEFAULT_BUTTON_CONFIG.backgroundNormalColor.?
	style.backgroundHoverColor =
		config.backgroundHoverColor.? or_else DEFAULT_BUTTON_CONFIG.backgroundHoverColor.?
	style.backgroundActiveColor =
		config.backgroundActiveColor.? or_else DEFAULT_BUTTON_CONFIG.backgroundActiveColor.?

	// TEXT COLOR
	style.textNormalColor =
		config.textNormalColor.? or_else DEFAULT_BUTTON_CONFIG.textNormalColor.?
	style.textHoverColor = config.textHoverColor.? or_else DEFAULT_BUTTON_CONFIG.textHoverColor.?
	style.textActiveColor =
		config.textActiveColor.? or_else DEFAULT_BUTTON_CONFIG.textActiveColor.?

	return style
}

@(private = "package")
_resolveTextStyle :: proc(config: TextConfig) -> (style: TextStyle) {
	// LAYOUT
	style.pivot = config.pivot.? or_else DEFAULT_TEXT_CONFIG.pivot.?
	style.padding = config.padding.? or_else DEFAULT_TEXT_CONFIG.padding.?
	style.margin = config.margin.? or_else DEFAULT_TEXT_CONFIG.margin.?

	// COLORS
	style.backgroundColor = config.backgroundColor.? or_else DEFAULT_TEXT_CONFIG.backgroundColor.?
	style.textColor = config.textColor.? or_else DEFAULT_TEXT_CONFIG.textColor.?

	return style
}

@(private = "package")
_resolveCheckboxStyle :: proc(config: CheckboxConfig) -> (style: CheckboxStyle) {
	// LAYOUT
	style.pivot = config.pivot.? or_else DEFAULT_CHECKBOX_CONFIG.pivot.?
	style.padding = config.padding.? or_else DEFAULT_CHECKBOX_CONFIG.padding.?
	style.margin = config.margin.? or_else DEFAULT_CHECKBOX_CONFIG.margin.?

	// BACKGROUND COLORS
	style.backgroundNormalColor =
		config.backgroundNormalColor.? or_else DEFAULT_CHECKBOX_CONFIG.backgroundNormalColor.?
	style.backgroundHoverColor =
		config.backgroundHoverColor.? or_else DEFAULT_CHECKBOX_CONFIG.backgroundHoverColor.?
	style.backgroundActiveColor =
		config.backgroundActiveColor.? or_else DEFAULT_CHECKBOX_CONFIG.backgroundActiveColor.?

	// TEXT COLORS
	style.textNormalColor =
		config.textNormalColor.? or_else DEFAULT_CHECKBOX_CONFIG.textNormalColor.?
	style.textHoverColor = config.textHoverColor.? or_else DEFAULT_CHECKBOX_CONFIG.textHoverColor.?
	style.textActiveColor =
		config.textActiveColor.? or_else DEFAULT_CHECKBOX_CONFIG.textActiveColor.?

	// RUNE
	style.checkboxRune = config.checkboxRune.? or_else DEFAULT_CHECKBOX_CONFIG.checkboxRune.?
	style.checkboxRuneScale =
		config.checkboxRuneScale.? or_else DEFAULT_CHECKBOX_CONFIG.checkboxRuneScale.?

	return style
}

@(private = "package")
_resolveSliderStyle :: proc(config: SliderConfig) -> (style: SliderStyle) {
	// LAYOUT
	style.padding = config.padding.? or_else DEFAULT_SLIDER_CONFIG.padding.?
	style.margin = config.margin.? or_else DEFAULT_SLIDER_CONFIG.margin.?

	// BACKGROUND
	style.backgroundNormalColor =
		config.backgroundNormalColor.? or_else DEFAULT_SLIDER_CONFIG.backgroundNormalColor.?
	style.backgroundHoverColor =
		config.backgroundHoverColor.? or_else DEFAULT_SLIDER_CONFIG.backgroundHoverColor.?
	style.backgroundActiveColor =
		config.backgroundActiveColor.? or_else DEFAULT_SLIDER_CONFIG.backgroundActiveColor.?
	style.backgroundHeight =
		config.backgroundHeight.? or_else DEFAULT_SLIDER_CONFIG.backgroundHeight.?

	// FILL COLORS
	style.fillNormalColor =
		config.fillNormalColor.? or_else DEFAULT_SLIDER_CONFIG.fillNormalColor.?
	style.fillHoverColor = config.fillHoverColor.? or_else DEFAULT_SLIDER_CONFIG.fillHoverColor.?
	style.fillActiveColor =
		config.fillActiveColor.? or_else DEFAULT_SLIDER_CONFIG.fillActiveColor.?

	// THUMB COLORS
	style.thumbNormalColor =
		config.thumbNormalColor.? or_else DEFAULT_SLIDER_CONFIG.thumbNormalColor.?
	style.thumbHoverColor =
		config.thumbHoverColor.? or_else DEFAULT_SLIDER_CONFIG.thumbHoverColor.?
	style.thumbActiveColor =
		config.thumbActiveColor.? or_else DEFAULT_SLIDER_CONFIG.thumbActiveColor.?

	// THUMB
	style.thumbPadding = config.thumbPadding.? or_else DEFAULT_SLIDER_CONFIG.thumbPadding.?
	style.thumbWidth = config.thumbWidth.? or_else DEFAULT_SLIDER_CONFIG.thumbWidth.?

	return style
}

@(private = "package")
_getMouseDelta :: proc() -> gmath.Vector2 {
	return state.mousePosition - state.previousMousePosition
}

@(private = "package")
_calculateObjectLayout :: proc(
	parent: ^Container,
	text: string,
	pivot: gmath.Pivot,
	padding: gmath.Vector2,
	margin: gmath.Vector4,
	isInline: bool,
	isSquare: bool = false,
	scale: f32 = 0.5,
) -> (
	rectangle: gmath.Rectangle,
	isVisible: bool,
) {
	textSize := render.getTextSize(DEFAULT_FONT, DEFAULT_FONT_SIZE, text) * scale
	if isSquare {
		maxDimension := max(textSize.x, textSize.y)
		textSize = {maxDimension, maxDimension}
	}

	widgetSize := textSize + (padding * 2)

	marginTop := margin.x
	marginRight := margin.y
	marginBottom := margin.z
	marginLeft := margin.w

	totalFootprint := widgetSize
	totalFootprint.x += marginLeft + marginRight
	totalFootprint.y += marginTop + marginBottom

	currentWindowWidth := parent.rectangle.z - parent.rectangle.x
	if totalFootprint.x > currentWindowWidth {
		parent.rectangle.z = parent.rectangle.x + totalFootprint.x
		currentWindowWidth = totalFootprint.x
	}

	availableWidth := currentWindowWidth - (marginLeft + marginRight)
	if parent.isScrolling {
		availableWidth -= parent.scrollbarWidth
	}

	pivotX := gmath.scaleFromPivot(pivot).x
	pivotOffset := pivotX * (availableWidth - widgetSize.x)
	screenX := parent.rectangle.x + marginLeft + pivotOffset

	if !isInline {
		parent.cursor.y += totalFootprint.y
		parent.currentCursorY = max(parent.currentCursorY, parent.cursor.y)
	}

	currentWindowHeight := parent.rectangle.w - parent.rectangle.y
	maximumHeight := DEFAULT_WINDOW_CONFIG.maximumHeight.?
	if !parent.isScrolling && currentWindowHeight < maximumHeight {
		parent.rectangle.y -= totalFootprint.y
	}

	screenY := parent.rectangle.w - parent.cursor.y + marginBottom + parent.scrollOffset
	rectangle = gmath.rectangleMake(gmath.Vector2{screenX, screenY}, widgetSize)

	viewBottom := parent.rectangle.y
	viewTop := parent.rectangle.w - parent.headerHeight

	isVisible = rectangle.w >= viewBottom && rectangle.y <= viewTop

	return rectangle, isVisible
}

@(private = "package")
_initializeWindowState :: proc(
	id: u32,
	title: string,
	position: gmath.Vector2,
	style: WindowStyle,
) {
	titleSize := render.getTextSize(DEFAULT_FONT, DEFAULT_FONT_SIZE, title) * 0.5

	closeString := fmt.tprintf("%r", style.closeRune)
	closeSize := render.getTextSize(DEFAULT_FONT, DEFAULT_FONT_SIZE, closeString)

	toggleString := fmt.tprintf("%r", style.toggleRune)
	toggleSize := render.getTextSize(DEFAULT_FONT, DEFAULT_FONT_SIZE, toggleString)

	windowWidth := titleSize.x + closeSize.x + toggleSize.x + (style.headerMargin.x * 2) + 2
	windowHeight := titleSize.y + (style.headerMargin.y * 2)

	rectangleSize := gmath.Vector2{windowWidth, windowHeight}
	rectangle := gmath.rectangleMake(position, rectangleSize, style.pivot)

	pivotOffset := rectangleSize * gmath.scaleFromPivot(style.pivot)
	rectangle.xy += pivotOffset
	rectangle.zw += pivotOffset

	container := new(Container)
	container.id = id
	container.rectangle = rectangle
	container.headerHeight = titleSize.y + style.headerMargin.y
	container.scrollbarWidth = style.scrollbarWidth
	container.closeWidth = closeSize.x
	container.toggleWidth = toggleSize.x
	container.isOpen = true
	container.isExpanded = true
	container.isScrolling = false

	state.containers[id] = container
	append(&state.containerOrder, id)
}

@(private = "package")
_handleWindowMovement :: proc(
	id: u32,
	container: ^Container,
	style: WindowStyle,
) -> (
	headerBackgroundColor: gmath.Vector4,
	headerTextColor: gmath.Vector4,
	headerRectangle: gmath.Rectangle,
) {
	headerRectangle = gmath.Rectangle {
		container.rectangle.x,
		container.rectangle.w - container.headerHeight,
		container.rectangle.z,
		container.rectangle.w,
	}

	headerBackgroundColor = style.headerBackgroundNormalColor
	headerTextColor = style.headerTextNormalColor

	isTopWindow := _hoveredWindowId == id
	isHover := gmath.rectangleContains(headerRectangle, state.mousePosition)

	if state.active == id {
		headerBackgroundColor = style.headerBackgroundActiveColor
		headerTextColor = style.headerTextActiveColor

		mouseDelta := _getMouseDelta()
		container.rectangle = gmath.rectangleShift(container.rectangle, mouseDelta)
		headerRectangle = gmath.rectangleShift(headerRectangle, mouseDelta)

		if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
			state.active = 0
		}
	} else if state.active == 0 && isHover && isTopWindow {
		state.hot = id
		headerBackgroundColor = style.headerBackgroundHoverColor
		headerTextColor = style.headerTextHoverColor

		if input.isKeyPressed(input.KeyCode.LEFT_MOUSE) && state.lastFrameHot == id {
			state.active = id
			input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
		}
	}

	return
}

@(private = "package")
_handleSliderInteractionAndDraw :: proc(
	id: u32,
	parent: ^Container,
	isInline: bool,
	style: SliderStyle,
	currentValue: f32,
	minimumValue: f32,
	maximumValue: f32,
	isInteger: bool,
) -> (
	value: f32,
) {
	value = currentValue

	marginTop := style.margin.x
	marginRight := style.margin.y
	marginBottom := style.margin.z
	marginLeft := style.margin.w

	currentWindowWidth := parent.rectangle.z - parent.rectangle.x
	availableWidth :=
		currentWindowWidth -
		(marginLeft + marginRight) -
		((style.thumbWidth + style.thumbPadding.x) / 2)

	if parent.isScrolling {
		availableWidth -= parent.scrollbarWidth
	}

	backgroundSize := gmath.Vector2{availableWidth, style.backgroundHeight}
	fillSize := backgroundSize - (style.padding * 2)
	thumbSize := gmath.Vector2{style.thumbWidth, fillSize.y} + (style.thumbPadding * 2)

	fullSize := backgroundSize
	fullSize.x += marginLeft + marginRight
	fullSize.y += marginTop + marginBottom

	screenX := parent.rectangle.x + marginLeft

	if !isInline {
		parent.cursor.y += fullSize.y
		parent.currentCursorY = max(parent.currentCursorY, parent.cursor.y)
	}

	currentWindowHeight := parent.rectangle.w - parent.rectangle.y
	maximumHeight := DEFAULT_WINDOW_CONFIG.maximumHeight.?

	if !parent.isScrolling && currentWindowHeight < maximumHeight {
		parent.rectangle.y -= fullSize.y
	}

	screenY := parent.rectangle.w - parent.cursor.y + marginBottom + parent.scrollOffset

	backgroundRectangle := gmath.rectangleMake(gmath.Vector2{screenX, screenY}, backgroundSize)

	viewBottom := parent.rectangle.y
	viewTop := parent.rectangle.w - parent.headerHeight
	isVisible := backgroundRectangle.w >= viewBottom && backgroundRectangle.y <= viewTop

	if !isVisible do return

	backgroundHitRectangle := backgroundRectangle
	isHover := gmath.rectangleContains(backgroundHitRectangle, state.mousePosition)
	isBlockedByWindow := _hoveredWindowId != parent.id

	thumbColor := style.thumbNormalColor
	backgroundColor := style.backgroundNormalColor
	fillColor := style.fillNormalColor

	if state.active == id {
		thumbColor = style.thumbActiveColor
		backgroundColor = style.backgroundActiveColor
		fillColor = style.fillActiveColor

		fillStart := screenX + style.padding.x
		fillWidth := fillSize.x

		mouseRelativeX := state.mousePosition.x - fillStart
		newRatio := clamp(mouseRelativeX / fillWidth, 0, 1)

		value = minimumValue + (newRatio * (maximumValue - minimumValue))
		if isInteger {
			value = math.round(value)
		}

		if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
			state.active = 0
		}
	} else if isHover && !isBlockedByWindow {
		thumbColor = style.thumbHoverColor
		backgroundColor = style.backgroundHoverColor
		fillColor = style.fillHoverColor

		state.hot = id

		if state.active == 0 &&
		   input.isKeyPressed(input.KeyCode.LEFT_MOUSE) &&
		   state.lastFrameHot == id {
			state.active = id
			input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
		}
	}

	finalRatio := (value - minimumValue) / (maximumValue - minimumValue)

	append(
		&state.currentContainer.commands,
		DrawRectangleCommand {
			rectangle = backgroundRectangle,
			color = backgroundColor,
			outlineColor = {},
		},
	)

	fillRectangle := gmath.rectangleMake(
		gmath.Vector2{screenX, screenY} + style.padding,
		gmath.Vector2{fillSize.x * finalRatio, fillSize.y},
	)
	append(
		&state.currentContainer.commands,
		DrawRectangleCommand{rectangle = fillRectangle, color = fillColor, outlineColor = {}},
	)

	finalThumbCenter := screenX + style.padding.x + (finalRatio * fillSize.x)
	thumbRectangle := gmath.rectangleMake(
		gmath.Vector2 {
			finalThumbCenter - (thumbSize.x * 0.5),
			screenY + style.padding.y - style.thumbPadding.y,
		},
		thumbSize,
	)
	append(
		&state.currentContainer.commands,
		DrawRectangleCommand{rectangle = thumbRectangle, color = thumbColor, outlineColor = {}},
	)

	return value
}


@(private = "package")
_handleScrollbarInteractionAndDraw :: proc(
	container: ^Container,
	viewHeight: f32,
	maxScroll: f32,
	style: WindowStyle,
) {
	scrollbarId := getId(fmt.tprintf("%v_%s", container.id, "scrollbar"))

	backgroundRectangle := gmath.Rectangle {
		container.rectangle.z - style.scrollbarWidth,
		container.rectangle.y,
		container.rectangle.z,
		container.rectangle.w - container.headerHeight,
	}

	append(
		&state.currentContainer.commands,
		DrawRectangleCommand {
			rectangle = backgroundRectangle,
			color = style.scrollbarBackgroundColor,
			outlineColor = {},
		},
	)

	thumbSize := max(20, viewHeight * (viewHeight / container.contentHeight))
	availableTrack := viewHeight - thumbSize

	if availableTrack <= 0 do return

	scrollRatio := container.scrollOffset / maxScroll
	currentThumbY := backgroundRectangle.w - (scrollRatio * availableTrack) - thumbSize

	hitRectangle := gmath.Rectangle {
		backgroundRectangle.x,
		currentThumbY,
		backgroundRectangle.z,
		currentThumbY + thumbSize,
	}

	isHover := gmath.rectangleContains(hitRectangle, state.mousePosition)
	isBlockedByWindow := _hoveredWindowId != container.id

	if state.active == scrollbarId {
		mouseDeltaY := _getMouseDelta().y
		pixelScale := maxScroll / availableTrack
		scrollChange := -mouseDeltaY * pixelScale

		container.scrollOffset += scrollChange
		container.scrollOffset = clamp(container.scrollOffset, 0, maxScroll)

		if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
			state.active = 0
		}
	} else if isHover && !isBlockedByWindow {
		state.hot = scrollbarId

		if state.active == 0 &&
		   input.isKeyPressed(input.KeyCode.LEFT_MOUSE) &&
		   state.lastFrameHot == scrollbarId {
			state.active = scrollbarId
			input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
		}
	}

	finalRatio := container.scrollOffset / maxScroll
	finalThumbY := backgroundRectangle.w - (finalRatio * availableTrack) - thumbSize

	finalThumbRectangle := gmath.Rectangle {
		backgroundRectangle.x,
		finalThumbY,
		backgroundRectangle.z,
		finalThumbY + thumbSize,
	}

	append(
		&state.currentContainer.commands,
		DrawRectangleCommand {
			rectangle = finalThumbRectangle,
			color = style.scrollbarThumbColor,
			outlineColor = {},
		},
	)
}

@(private = "package")
_drawHeader :: proc(
	id: u32,
	title: string,
	container: ^Container,
	headerBackgroundColor: gmath.Vector4,
	headerTextColor: gmath.Vector4,
	headerRectangle: gmath.Rectangle,
	style: WindowStyle,
) {
	append(
		&state.currentContainer.commands,
		DrawRectangleCommand {
			rectangle = headerRectangle,
			color = headerBackgroundColor,
			outlineColor = {},
		},
	)

	titlePosition := gmath.getRectangleCenter(headerRectangle)
	append(
		&state.currentContainer.commands,
		DrawTextCommand {
			text = title,
			position = titlePosition,
			color = headerTextColor,
			pivot = .centerCenter,
			scale = 0.5,
			rotation = 0.0,
		},
	)

	container.isOpen = _closeButton(
		style.closeNormalColor,
		style.closeHoverColor,
		style.closeActiveColor,
		style.closeRune,
	)

	container.isExpanded =
		_toggleButton(
			style.toggleNormalColor,
			style.toggleHoverColor,
			style.toggleActiveColor,
			style.toggleRune,
		).? or_else container.isExpanded
}

@(private = "package")
_handleButtonInteractionAndDraw :: proc(
	id: u32,
	rectangle: gmath.Rectangle,
	label: string,
	style: ButtonStyle,
	parent: ^Container,
) -> (
	clicked: bool,
) {
	clicked = false
	backgroundColor := style.backgroundNormalColor
	textColor := style.textNormalColor

	viewBottom := parent.rectangle.y
	viewTop := parent.rectangle.w - parent.headerHeight
	mouseInWindow := state.mousePosition.y >= viewBottom && state.mousePosition.y <= viewTop

	isBlockedByWindow := parent.id != _hoveredWindowId
	isHover := gmath.rectangleContains(rectangle, state.mousePosition)

	if isHover &&
	   !isBlockedByWindow &&
	   (state.active == 0 || state.active == id) &&
	   mouseInWindow {
		state.hot = id
		backgroundColor = style.backgroundHoverColor
		textColor = style.textHoverColor
	}

	if state.active == id {
		backgroundColor = style.backgroundActiveColor
		textColor = style.textActiveColor

		if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
			if isHover do clicked = true
			state.active = 0
		}
	} else if isHover && !isBlockedByWindow {
		if input.isKeyPressed(input.KeyCode.LEFT_MOUSE) {
			if id == state.lastFrameHot {
				state.active = id
				input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
			}
		}
	}

	append(
		&state.currentContainer.commands,
		DrawRectangleCommand{rectangle = rectangle, color = backgroundColor, outlineColor = {}},
	)

	append(
		&state.currentContainer.commands,
		DrawTextCommand {
			text = label,
			position = gmath.getRectangleCenter(rectangle),
			color = textColor,
			pivot = .centerCenter,
			scale = 0.5,
			rotation = 0.0,
		},
	)

	return clicked
}

@(private = "package")
_headerButton :: proc(
	id: u32,
	position: gmath.Vector2,
	size: gmath.Vector2,
	textNormalColor, textHoverColor, textActiveColor: gmath.Vector4,
	content: any,
	rotation: f32 = 0,
	offset: gmath.Vector2 = {0, 0},
) -> (
	clicked: bool,
	isHover: bool,
) {
	rectangle := gmath.rectangleMake(position, size)
	clicked = false
	textColor := textNormalColor

	parent := state.currentContainer
	isBlockedByWindow := parent.id != _hoveredWindowId
	isHover = gmath.rectangleContains(rectangle, state.mousePosition)

	if state.active == id {
		textColor = textActiveColor
		if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
			if isHover do clicked = true
			state.active = 0
		}
	} else if isHover && !isBlockedByWindow && state.active == 0 {
		state.hot = id
		textColor = textHoverColor
		if input.isKeyPressed(input.KeyCode.LEFT_MOUSE) && state.lastFrameHot == id {
			state.active = id
			input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
		}
	}

	textString := ""
	switch v in content {
	case rune:
		textString = fmt.tprintf("%r", v)
	case string:
		textString = v
	}

	append(
		&state.currentContainer.commands,
		DrawTextCommand {
			text = textString,
			position = gmath.getRectangleCenter(rectangle) + offset,
			color = textColor,
			pivot = .centerCenter,
			scale = 1.0,
			rotation = rotation,
		},
	)

	return clicked, isHover
}

@(private = "package")
_drawText :: proc(textString: string, rectangle: gmath.Rectangle, style: TextStyle) {
	append(
		&state.currentContainer.commands,
		DrawRectangleCommand {
			rectangle = rectangle,
			color = style.backgroundColor,
			outlineColor = {},
		},
	)

	append(
		&state.currentContainer.commands,
		DrawTextCommand {
			text = textString,
			position = gmath.getRectangleCenter(rectangle),
			color = style.textColor,
			pivot = .centerCenter,
			scale = 0.5,
			rotation = 0.0,
		},
	)
}

@(private = "package")
_handleCheckboxInteractionAndDraw :: proc(
	value: ^bool,
	rectangle: gmath.Rectangle,
	parent: ^Container,
	id: u32,
	style: CheckboxStyle,
	checkboxString: string,
	scale: f32,
) -> (
	clicked: bool,
) {
	clicked = false
	backgroundColor := style.backgroundNormalColor
	textColor := style.textNormalColor

	viewBottom := parent.rectangle.y
	viewTop := parent.rectangle.w - parent.headerHeight
	mouseInWindow := state.mousePosition.y >= viewBottom && state.mousePosition.y <= viewTop

	isBlockedByWindow := parent.id != _hoveredWindowId
	isHover := gmath.rectangleContains(rectangle, state.mousePosition)

	if isHover &&
	   !isBlockedByWindow &&
	   (state.active == 0 || state.active == id) &&
	   mouseInWindow {
		state.hot = id
		backgroundColor = style.backgroundHoverColor
		textColor = style.textHoverColor
	}

	if state.active == id {
		backgroundColor = style.backgroundActiveColor
		textColor = style.textActiveColor

		if input.isKeyReleased(input.KeyCode.LEFT_MOUSE) {
			if isHover do clicked = true
			state.active = 0
		}
	} else if isHover && !isBlockedByWindow {
		if input.isKeyPressed(input.KeyCode.LEFT_MOUSE) {
			if id == state.lastFrameHot {
				state.active = id
				input.consumeKeyPressed(input.KeyCode.LEFT_MOUSE)
			}
		}
	}

	append(
		&state.currentContainer.commands,
		DrawRectangleCommand{rectangle = rectangle, color = backgroundColor, outlineColor = {}},
	)

	append(
		&state.currentContainer.commands,
		DrawTextCommand {
			text = checkboxString,
			position = gmath.getRectangleCenter(rectangle),
			color = textColor,
			pivot = .centerCenter,
			scale = scale,
			rotation = 0.0,
		},
	)

	return clicked
}
