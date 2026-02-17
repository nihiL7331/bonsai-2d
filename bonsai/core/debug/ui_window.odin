package debug

import "bonsai:core/clock"
import "bonsai:core/gmath"
import "bonsai:core/input"
import "bonsai:core/render"

import "core:fmt"

when !ODIN_DEBUG {
	_ :: clock
	_ :: render
	_ :: gmath
	_ :: input
	_ :: fmt
}

@(private = "file")
WindowGeometry :: struct {
	currentTopY:       f32,
	viewHeight:        f32,
	hasScrollbar:      bool,
	minimumSize:       gmath.Vector2,
	titleRectangle:    gmath.Rectangle,
	collapseRectangle: gmath.Rectangle,
	resizeRectangle:   gmath.Rectangle,
	closeRectangle:    gmath.Rectangle,
	windowRectangle:   gmath.Rectangle,
	viewRectangle:     gmath.Rectangle,
}

// @ref
// Begins a draggable window.
// Returns `true` if the window is visible (not collapsed).
// Accepts an optional `isOpen` pointer. If provided, an 'X'
// button is drawn. If clicked, `isOpen^` becomes `false`
// and the window stops rendering.
// :::caution
// You must call `uiEndWindow()` after your widgets.
// :::
uiWindow :: proc(
	title: string,
	rectangle: gmath.Rectangle,
	isOpen: ^bool = nil,
	idSuffix: string = "",
) -> bool {
	when ODIN_DEBUG {
		if isOpen != nil && !isOpen^ do return false

		id, state := _uiWindowInitializeState(title, rectangle, idSuffix)
		closeId := _uiGetId(fmt.tprintf("##%sClose", title))
		collapseId := _uiGetId(fmt.tprintf("##%sCollapse", title))
		resizeId := _uiGetId(fmt.tprintf("##%sResize", title))

		MIN_HEIGHT := DEFAULT_STYLE.titleHeight + (DEFAULT_STYLE.padding * 2)
		MIN_WIDTH :: 25.0
		if state.size.x < MIN_WIDTH {
			state.size.x = MIN_WIDTH
		}
		if state.size.y < MIN_HEIGHT {
			state.size.y = MIN_HEIGHT
		}

		geometry := _uiWindowCalculateGeometry(title, state, isOpen != nil)

		if _uiWindowHandleInput(
			id,
			closeId,
			collapseId,
			resizeId,
			state,
			geometry,
			isOpen != nil,
		) {
			isOpen^ = false
			return false
		}

		renderGeometry := _uiWindowCalculateGeometry(title, state, isOpen != nil)

		_ui.currentWindowId = id
		_uiWindowRender(
			id,
			closeId,
			collapseId,
			resizeId,
			state,
			title,
			renderGeometry,
			isOpen != nil,
		)

		if !state.isCollapsed {
			_uiWindowSetupLayout(id, state, renderGeometry)
			return true
		}

		_ui.currentWindowId = 0
		return false
	} else {
		return false
	}
}

// @ref
// Ends the current window block.
// Calculates content height, draws scrollbar, and cleans up window state.
// **Must** be called if [`uiWindow`](#uiwindow) returns `true`.
uiEndWindow :: proc() {
	when ODIN_DEBUG {
		if _ui.currentWindowId != 0 {
			state := &_ui.windows[_ui.currentWindowId]
			_popScissor()

			currentYUnscrolled := _ui.cursor.y - state.scrollY
			topY :=
				state.position.y + state.size.y - DEFAULT_STYLE.titleHeight - DEFAULT_STYLE.padding

			state.contentHeight = topY - currentYUnscrolled
			viewHeight := state.size.y - DEFAULT_STYLE.titleHeight

			if state.contentHeight > viewHeight {
				barWidth := DEFAULT_STYLE.scrollbarWidth
				barRectangle := gmath.Rectangle {
					state.position.x + state.size.x - barWidth - DEFAULT_STYLE.padding,
					state.position.y + DEFAULT_STYLE.padding + DEFAULT_STYLE.resizeSize,
					state.position.x + state.size.x - DEFAULT_STYLE.padding,
					state.position.y + viewHeight - DEFAULT_STYLE.padding,
				}

				barHeight := barRectangle.w - barRectangle.y
				scrollRatio := state.scrollY / (state.contentHeight - viewHeight)
				handleHeight := max(
					DEFAULT_STYLE.minimumScrollbarHeight,
					barHeight * (viewHeight / state.contentHeight),
				)

				availableHeight := barRectangle.w - barRectangle.y - handleHeight
				handleY := barRectangle.w - handleHeight - availableHeight * scrollRatio

				handleRectangle := gmath.Rectangle {
					barRectangle.x,
					handleY,
					barRectangle.z,
					handleY + handleHeight,
				}

				barId := _uiGetId("##Scrollbar")

				isBarHovered := gmath.rectangleContains(barRectangle, _ui.mousePosition)
				isHandleHovered := gmath.rectangleContains(handleRectangle, _ui.mousePosition)

				if isBarHovered {
					_ui.hotId = barId
					if _ui.activeId == 0 && input.isKeyPressed(.LEFT_MOUSE) {
						_ui.activeId = barId
					}
				}

				if _ui.activeId == barId {
					if input.isKeyDown(.LEFT_MOUSE) {
						relativeY := barRectangle.w - _ui.mousePosition.y - (handleHeight * 0.5)
						newRatio := gmath.remap(relativeY, 0.0, availableHeight, 0.0, 1.0)
						newRatio = gmath.clamp(newRatio, 0.0, 1.0)
						maxScroll := state.contentHeight - viewHeight
						state.scrollY = maxScroll * newRatio
					} else {
						_ui.activeId = 0
					}
				}

				_pushRectangle(barRectangle, DEFAULT_STYLE.hotColor, true)

				handleColor := DEFAULT_STYLE.textColor
				if _ui.activeId == barId || isHandleHovered {
					handleColor = DEFAULT_STYLE.activeColor
				}
				_pushRectangle(handleRectangle, handleColor, true)
			}

			_ui.currentWindowId = 0
		}
	}
}

// @ref
// Draws a collapsible header.
// Returns `true` if open.
// :::note[Usage]
// ```Odin
// if debug.uiHeader("Physics") {
//   debug.uiSlider(...)
// }
// ```
// :::
uiHeader :: proc(text: string, width: f32 = 60.0) -> bool {
	when ODIN_DEBUG {
		id := _uiGetId(text)
		isOpen := _ui.headers[id]
		rectangle := _uiAdvance(width, DEFAULT_STYLE.itemHeight)

		isHovered :=
			gmath.rectangleContains(rectangle, _ui.mousePosition) &&
			_ui.currentWindowId == _ui.hoveredWindowId

		if isHovered {
			_ui.hotId = id
			if _ui.activeId == 0 && input.isKeyPressed(.LEFT_MOUSE) {
				_ui.activeId = id
			}
		}

		if _ui.activeId == id && input.isKeyReleased(.LEFT_MOUSE) && isHovered {
			isOpen = !isOpen
			_ui.headers[id] = isOpen
			_ui.activeId = 0
		}

		if isHovered {
			_pushRectangle(rectangle, DEFAULT_STYLE.hotColor, true)
		}

		arrowSize := DEFAULT_STYLE.itemHeight * 0.3
		arrowCenter := gmath.Vector2 {
			rectangle.x + DEFAULT_STYLE.padding + arrowSize * 0.5,
			rectangle.y + DEFAULT_STYLE.itemHeight * 0.5,
		}

		if isOpen {
			topLeftPoint := arrowCenter + gmath.Vector2{-arrowSize, arrowSize * 0.5}
			topRightPoint := arrowCenter + gmath.Vector2{arrowSize, arrowSize * 0.5}
			bottomCenterPoint := arrowCenter + gmath.Vector2{0, -arrowSize * 0.8}
			_pushTriangle(topLeftPoint, topRightPoint, bottomCenterPoint, DEFAULT_STYLE.textColor)
		} else {
			topLeftPoint := arrowCenter + gmath.Vector2{-arrowSize * 0.5, arrowSize}
			bottomLeftPoint := arrowCenter + gmath.Vector2{-arrowSize * 0.5, -arrowSize}
			centerRightPoint := arrowCenter + gmath.Vector2{arrowSize * 0.8, 0}
			_pushTriangle(topLeftPoint, bottomLeftPoint, centerRightPoint, DEFAULT_STYLE.textColor)
		}

		textPosition := gmath.Vector2 {
			rectangle.x + DEFAULT_STYLE.padding * 2 + arrowSize,
			rectangle.y + (DEFAULT_STYLE.itemHeight * 0.5),
		}

		_pushText(textPosition, text, DEFAULT_STYLE.textColor, .centerLeft)

		return isOpen
	} else {
		return false
	}
}

//
// HELPERS
//

@(private = "file")
_uiWindowInitializeState :: proc(
	title: string,
	rectangle: gmath.Rectangle,
	idSuffix: string,
) -> (
	u64,
	^WindowState,
) {
	when ODIN_DEBUG {
		fullIdString := title
		if len(idSuffix) > 0 {
			fullIdString = fmt.tprintf("%s%s", title, idSuffix)
		}
		id := _uiGetId(fullIdString)

		if id not_in _ui.windows {
			_ui.windows[id] = WindowState {
				position    = rectangle.xy,
				size        = gmath.getRectangleSize(rectangle),
				isCollapsed = false,
			}
		}

		state := &_ui.windows[id]
		state.lastFrameSeen = clock.getTicks()

		state.commands = make([dynamic]UiCommand, 0, 64, context.temp_allocator)

		return id, state
	} else {
		return 0, nil
	}
}

@(private = "file")
_uiWindowCalculateGeometry :: proc(
	title: string,
	state: ^WindowState,
	hasCloseButton: bool,
) -> WindowGeometry {
	when ODIN_DEBUG {
		geometry: WindowGeometry

		geometry.currentTopY = state.position.y + state.size.y

		geometry.titleRectangle = gmath.Rectangle {
			state.position.x,
			geometry.currentTopY - DEFAULT_STYLE.titleHeight,
			state.position.x + state.size.x,
			geometry.currentTopY,
		}

		titleSize := render.getTextSize(DEFAULT_STYLE.font, DEFAULT_STYLE.fontSize, title)
		geometry.minimumSize.x =
			DEFAULT_STYLE.padding * 3 + DEFAULT_STYLE.titleButtonSize + titleSize.x
		if hasCloseButton {
			geometry.minimumSize.x += DEFAULT_STYLE.titleButtonSize + DEFAULT_STYLE.padding
		}
		geometry.minimumSize.y =
			DEFAULT_STYLE.titleHeight +
			DEFAULT_STYLE.padding * 2 +
			DEFAULT_STYLE.minimumScrollbarHeight +
			DEFAULT_STYLE.resizeSize

		buttonY :=
			geometry.titleRectangle.y +
			(DEFAULT_STYLE.titleHeight - DEFAULT_STYLE.titleButtonSize) * 0.5
		geometry.collapseRectangle = gmath.Rectangle {
			geometry.titleRectangle.x + DEFAULT_STYLE.padding,
			buttonY,
			geometry.titleRectangle.x + DEFAULT_STYLE.padding + DEFAULT_STYLE.titleButtonSize,
			buttonY + DEFAULT_STYLE.titleButtonSize,
		}

		if hasCloseButton {
			geometry.closeRectangle = gmath.Rectangle {
				geometry.titleRectangle.z - DEFAULT_STYLE.padding - DEFAULT_STYLE.titleButtonSize,
				buttonY,
				geometry.titleRectangle.z - DEFAULT_STYLE.padding,
				buttonY + DEFAULT_STYLE.titleButtonSize,
			}
		}

		geometry.resizeRectangle = gmath.Rectangle {
			state.position.x + state.size.x - DEFAULT_STYLE.resizeSize,
			state.position.y,
			state.position.x + state.size.x,
			state.position.y + DEFAULT_STYLE.resizeSize,
		}

		geometry.viewHeight = geometry.currentTopY - DEFAULT_STYLE.titleHeight - state.position.y
		geometry.hasScrollbar = state.contentHeight > geometry.viewHeight

		geometry.viewRectangle = gmath.Rectangle {
			state.position.x,
			state.position.y,
			state.position.x + state.size.x,
			geometry.currentTopY - DEFAULT_STYLE.titleHeight,
		}

		geometry.windowRectangle = gmath.Rectangle {
			state.position.x,
			state.position.y,
			state.position.x + state.size.x,
			geometry.currentTopY,
		}

		return geometry
	} else {
		return {}
	}
}

@(private = "file")
_uiWindowHandleInput :: proc(
	id: u64,
	closeId: u64,
	collapseId: u64,
	resizeId: u64,
	state: ^WindowState,
	geometry: WindowGeometry,
	hasCloseButton: bool,
) -> (
	shouldClose: bool,
) {
	when ODIN_DEBUG {
		isActiveWindow := _ui.hoveredWindowId == id

		isTitleHovered :=
			gmath.rectangleContains(geometry.titleRectangle, _ui.mousePosition) && isActiveWindow
		isCollapseHovered :=
			gmath.rectangleContains(geometry.collapseRectangle, _ui.mousePosition) &&
			isActiveWindow
		isResizeHovered :=
			gmath.rectangleContains(geometry.resizeRectangle, _ui.mousePosition) && isActiveWindow
		isCloseHovered :=
			gmath.rectangleContains(geometry.closeRectangle, _ui.mousePosition) && isActiveWindow
		isWindowHovered :=
			gmath.rectangleContains(geometry.windowRectangle, _ui.mousePosition) && isActiveWindow

		if isWindowHovered && input.isKeyPressed(.LEFT_MOUSE) {
			if state.zIndex > _ui.clickClaimedZ {
				_ui.nextFocusedWindowId = id
				_ui.clickClaimedZ = state.zIndex
			}
		}

		windowZ := _ui.nextZIndex
		_ui.nextZIndex += 1.0
		if _ui.focusedWindowId == id {
			windowZ += 1000.0
		}
		state.zIndex = windowZ
		_ui.currentZIndex = windowZ

		if _ui.activeId == 0 {
			if isCloseHovered {
				if input.isKeyPressed(.LEFT_MOUSE) {
					_ui.activeId = closeId
				}
				_ui.hotId = closeId
			} else if isCollapseHovered {
				if input.isKeyPressed(.LEFT_MOUSE) {
					_ui.activeId = collapseId
				}
				_ui.hotId = collapseId
			} else if isTitleHovered {
				if input.isKeyPressed(.LEFT_MOUSE) {
					_ui.activeId = id
				}
				_ui.hotId = id
			} else if isResizeHovered {
				if input.isKeyPressed(.LEFT_MOUSE) {
					_ui.activeId = resizeId
				}
				_ui.hotId = resizeId
			}
		}

		if _ui.activeId == closeId {
			if input.isKeyReleased(.LEFT_MOUSE) {
				_ui.activeId = 0
				if _ui.focusedWindowId == id {
					_ui.focusedWindowId = 0
				}
				if _ui.hoveredWindowId == id {
					_ui.hoveredWindowId = 0
				}
				return true
			}
		}

		if _ui.activeId == collapseId {
			if input.isKeyReleased(.LEFT_MOUSE) {
				state.isCollapsed = !state.isCollapsed
				_ui.activeId = 0
			}
		}

		if _ui.activeId == id {
			if input.isKeyDown(.LEFT_MOUSE) {
				viewportSize := gmath.getRectangleSize(render.getViewportRectangle())
				state.position += input.getMouseDelta()
				state.position = gmath.clamp(
					state.position,
					gmath.Vector2{0, DEFAULT_STYLE.titleHeight - state.size.y},
					gmath.Vector2{viewportSize.x - state.size.x, viewportSize.y - state.size.y},
				)
			}
		}

		if _ui.activeId == resizeId {
			if input.isKeyDown(.LEFT_MOUSE) {
				mouseDelta := input.getMouseDelta()
				if state.size.x + mouseDelta.x > geometry.minimumSize.x {
					state.size.x += mouseDelta.x
				}
				if state.size.y - mouseDelta.y > geometry.minimumSize.y {
					state.size.y -= mouseDelta.y
					state.position.y += mouseDelta.y
				}
			}
		}

		if !state.isCollapsed {
			isViewHovered := gmath.rectangleContains(geometry.viewRectangle, _ui.mousePosition)
			if isViewHovered && isActiveWindow {
				scrollDelta := input.getScrollY()
				if scrollDelta != 0 {
					state.scrollY -= scrollDelta * DEFAULT_STYLE.scrollSpeed
					maxScroll := max(
						0.0,
						state.contentHeight - geometry.viewHeight + DEFAULT_STYLE.padding,
					)
					state.scrollY = gmath.clamp(state.scrollY, f32(0.0), maxScroll)
				}
			}
		}
		return false
	} else {
		return false
	}
}

@(private = "file")
_uiWindowRender :: proc(
	id: u64,
	closeId: u64,
	collapseId: u64,
	resizeId: u64,
	state: ^WindowState,
	title: string,
	geometry: WindowGeometry,
	hasCloseButton: bool,
) {
	when ODIN_DEBUG {
		isActiveWindow := (_ui.hoveredWindowId == id)

		if !state.isCollapsed {
			bodyRectangle := gmath.Rectangle {
				state.position.x,
				state.position.y,
				state.position.x + state.size.x,
				geometry.currentTopY,
			}
			_pushRectangle(bodyRectangle, DEFAULT_STYLE.backgroundColor, isRounding = true)
		}

		_pushRectangle(geometry.titleRectangle, DEFAULT_STYLE.titleColor, isRounding = true)

		isCollapseHovered :=
			gmath.rectangleContains(geometry.collapseRectangle, _ui.mousePosition) &&
			isActiveWindow
		if isCollapseHovered && _ui.hotId == collapseId {
			_pushRectangle(geometry.collapseRectangle, DEFAULT_STYLE.hotColor, isRounding = true)
		}

		collapseCenter := gmath.getRectangleCenter(geometry.collapseRectangle)
		collapseSize := DEFAULT_STYLE.titleButtonSize * 0.4

		if state.isCollapsed {
			point1 := collapseCenter + gmath.Vector2{-collapseSize * 0.5, collapseSize}
			point2 := collapseCenter + gmath.Vector2{-collapseSize * 0.5, -collapseSize}
			point3 := collapseCenter + gmath.Vector2{collapseSize * 0.8, 0}
			_pushTriangle(point1, point2, point3, DEFAULT_STYLE.textColor)
		} else {
			point1 := collapseCenter + gmath.Vector2{-collapseSize, collapseSize * 0.5}
			point2 := collapseCenter + gmath.Vector2{collapseSize, collapseSize * 0.5}
			point3 := collapseCenter + gmath.Vector2{0, -collapseSize * 0.8}
			_pushTriangle(point1, point2, point3, DEFAULT_STYLE.textColor)
		}

		if hasCloseButton {
			isCloseHovered :=
				gmath.rectangleContains(geometry.closeRectangle, _ui.mousePosition) &&
				isActiveWindow
			if isCloseHovered && _ui.hotId == closeId {
				_pushRectangle(geometry.closeRectangle, DEFAULT_STYLE.hotColor, isRounding = true)
			}

			closeCenter := gmath.getRectangleCenter(geometry.closeRectangle)
			halfSize := DEFAULT_STYLE.titleButtonSize * 0.3

			_pushLine(
				closeCenter + gmath.Vector2{-halfSize, halfSize},
				closeCenter + gmath.Vector2{halfSize, -halfSize},
				DEFAULT_STYLE.textColor,
			)
			_pushLine(
				closeCenter + gmath.Vector2{-halfSize, -halfSize},
				closeCenter + gmath.Vector2{halfSize, halfSize},
				DEFAULT_STYLE.textColor,
			)
		}

		if !state.isCollapsed {
			isResizeHovered := gmath.rectangleContains(geometry.resizeRectangle, _ui.mousePosition)

			resizeColor := DEFAULT_STYLE.buttonColor
			if isResizeHovered && _ui.hotId == resizeId {
				resizeColor = DEFAULT_STYLE.hotColor
				if _ui.activeId == resizeId {
					resizeColor = DEFAULT_STYLE.activeColor
				}
			}
			_pushTriangle(
				gmath.Vector2{geometry.resizeRectangle.x, geometry.resizeRectangle.y},
				gmath.Vector2{geometry.resizeRectangle.z, geometry.resizeRectangle.y},
				gmath.Vector2{geometry.resizeRectangle.z, geometry.resizeRectangle.w},
				resizeColor,
			)
		}

		textCenter := gmath.getRectangleCenter(geometry.titleRectangle)

		leftWidth := DEFAULT_STYLE.titleButtonSize + DEFAULT_STYLE.padding
		rightWidth: f32 = 0.0
		if hasCloseButton {
			rightWidth = DEFAULT_STYLE.titleButtonSize + DEFAULT_STYLE.padding
		}
		textCenter.x += (leftWidth - rightWidth) * 0.5

		_pushText(textCenter, title, DEFAULT_STYLE.textColor, .centerCenter)
	}
}

@(private = "file")
_uiWindowSetupLayout :: proc(id: u64, state: ^WindowState, geometry: WindowGeometry) {
	when ODIN_DEBUG {
		_ui.currentWindowId = id

		window := &_ui.windows[id]

		_ui.cursor = gmath.Vector2 {
			state.position.x + DEFAULT_STYLE.padding,
			geometry.currentTopY -
			DEFAULT_STYLE.titleHeight -
			DEFAULT_STYLE.padding +
			state.scrollY,
		}
		_ui.startX = _ui.cursor.x
		_ui.rowStartX = geometry.currentTopY - DEFAULT_STYLE.titleHeight - DEFAULT_STYLE.padding

		scissorWidth := state.size.x
		if geometry.hasScrollbar {
			scissorWidth -= DEFAULT_STYLE.scrollbarWidth
		}

		window.scissorRectangle = gmath.Rectangle {
			state.position.x,
			state.position.y,
			state.position.x + scissorWidth,
			geometry.currentTopY - DEFAULT_STYLE.titleHeight,
		}
		_pushScissor(window.scissorRectangle)
	}
}
