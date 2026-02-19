package ui

import "bonsai:core/gmath"

when !ODIN_DEBUG {
	_ :: gmath
}

// @ref
// Starts a horizontal layout row.
// Subsequent widgets will be placed side-by-side until [`endRow`](#endrow) is called.
beginRow :: proc() {
	when ODIN_DEBUG {
		_ui.inRow = true
		_ui.rowStartX = _ui.cursor.x
		_ui.rowMaxHeight = 0
	}
}

// @ref
// Ends the current horizontal layout row.
// Moves the cursor down by the height of the tallest item in the row.
endRow :: proc() {
	when ODIN_DEBUG {
		_ui.inRow = false
		_ui.cursor.x = _ui.rowStartX
		_ui.cursor.y -= (_ui.rowMaxHeight + DEFAULT_STYLE.padding)
		_ui.rowMaxHeight = 0
	}
}

// @ref
// Draws a horizontal separator line.
// Spans the full available width of the current window or column.
separator :: proc() {
	when ODIN_DEBUG {
		width := getAvailableWidth()
		height := DEFAULT_STYLE.separatorHeight

		rectangle := _advance(width, height)
		lineY := rectangle.y + (height * 0.5)

		_pushLine(
			gmath.Vector2{rectangle.x, lineY},
			gmath.Vector2{rectangle.x + width, lineY},
			DEFAULT_STYLE.textColor,
		)
	}
}

// @ref
// Checks if `rectangle` is visible within the current window's scissor area.
// Useful for culling optimization.
isRectangleVisible :: proc(rectangle: gmath.Rectangle) -> bool {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 do return true

		window := _ui.windows[_ui.currentWindowId]

		return gmath.rectangleIntersects(window.scissorRectangle, rectangle)
	} else {
		return false
	}
}

// @ref
// Returns the available width in the current window/column.
// Automatically subtracts scrollbar width if active.
getAvailableWidth :: proc() -> f32 {
	when ODIN_DEBUG {
		if _ui.currentWindowId == 0 {
			return 50.0
		}

		window := _ui.windows[_ui.currentWindowId]
		width := window.size.x - (DEFAULT_STYLE.padding * 2) - _ui.indentation

		viewHeight := window.size.y - DEFAULT_STYLE.titleHeight
		if window.contentHeight > viewHeight {
			width -= (DEFAULT_STYLE.scrollbarWidth + DEFAULT_STYLE.padding)
		}

		return width
	} else {
		return 0
	}
}

@(private = "package")
_advance :: proc(width: f32, height: f32) -> gmath.Rectangle {
	when ODIN_DEBUG {
		cursor := &_ui.cursor
		if _ui.isRecordingPopup {
			cursor = &_ui.popupCursor
		}

		currentX := cursor.x + _ui.indentation

		rectangle := gmath.Rectangle{currentX, cursor.y - height, currentX + width, cursor.y}

		if _ui.inRow {
			cursor.x += width + DEFAULT_STYLE.padding
			if height > _ui.rowMaxHeight {
				_ui.rowMaxHeight = height
			}
		} else {
			cursor.y -= (height + DEFAULT_STYLE.padding)
		}

		if width > _ui.maxWidth {
			_ui.maxWidth = width
		}

		_ui.lastWidgetRectangle = rectangle

		return rectangle
	} else {
		return {}
	}
}

// @ref
// Increases the layout indentation (shifts cursor right).
// Useful for hierarchical data or grouping.
indent :: proc(amount: f32 = 5.0) {
	when ODIN_DEBUG {
		_ui.indentation += amount
	}
}

// @ref
// Decreases the layout indentation (shifts cursor left).
// Clamps indentation to `0`.
unindent :: proc(amount: f32 = 5.0) {
	when ODIN_DEBUG {
		_ui.indentation -= amount
		if _ui.indentation < 0 do _ui.indentation = 0
	}
}
