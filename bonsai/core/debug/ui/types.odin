package ui

import "bonsai:core/gmath"
import "bonsai:generated"

import "core:strings"

when !ODIN_DEBUG {
	_ :: strings
}

// @ref
// Configuration struct defining the visual appearence of the UI.
Style :: struct {
	backgroundColor:        gmath.Color,
	hotColor:               gmath.Color,
	activeColor:            gmath.Color,
	textColor:              gmath.Color,
	buttonColor:            gmath.Color,
	titleColor:             gmath.Color,
	rounding:               f32,
	padding:                f32,
	outlineThickness:       f32,
	itemHeight:             f32,
	titleHeight:            f32,
	titleButtonSize:        f32,
	resizeSize:             f32,
	scrollbarWidth:         f32,
	scrollSpeed:            f32,
	minimumScrollbarHeight: f32,
	separatorHeight:        f32,
	plotHeight:             f32,
	colorPreviewWidth:      f32,
	fontSize:               uint,
	font:                   generated.FontName,
}

// @ref
// Default style configuration (Dark theme).
DEFAULT_STYLE :: Style {
	backgroundColor        = gmath.Color{0.2, 0.2, 0.2, 0.9},
	hotColor               = gmath.Color{0.6, 0.6, 0.6, 1.0},
	activeColor            = gmath.Color{0.4, 0.4, 0.4, 1.0},
	textColor              = gmath.Color{1.0, 1.0, 1.0, 1.0},
	buttonColor            = gmath.Color{0.3, 0.3, 0.3, 1.0},
	titleColor             = gmath.Color{0.0, 0.0, 0.0, 1.0},
	rounding               = 2.0,
	padding                = 2.0,
	outlineThickness       = 0.5,
	itemHeight             = 7.0,
	titleHeight            = 8.0,
	titleButtonSize        = 6.0,
	resizeSize             = 6.0,
	scrollbarWidth         = 2.0,
	scrollSpeed            = 10.0,
	minimumScrollbarHeight = 20.0,
	separatorHeight        = 0.5,
	plotHeight             = 40.0,
	colorPreviewWidth      = 30.0,
	fontSize               = 6,
	font                   = .PixelCode,
}

// @ref
// Union of all possible drawing commands recorded by the UI system.
// These are executed in [`draw`](#draw) at the end of the frame.
Command :: union {
	LineCommand,
	RectangleCommand,
	TriangleCommand,
	TextCommand,
	ScissorCommand,
	PopScissorCommand,
}

LineCommand :: struct {
	start: gmath.Vector2,
	end:   gmath.Vector2,
	color: gmath.Color,
}

RectangleCommand :: struct {
	rectangle:  gmath.Rectangle,
	color:      gmath.Color,
	isRounding: bool,
	isOutline:  bool,
}

TriangleCommand :: struct {
	point1: gmath.Vector2,
	point2: gmath.Vector2,
	point3: gmath.Vector2,
	color:  gmath.Color,
}

TextCommand :: struct {
	position: gmath.Vector2,
	text:     string,
	color:    gmath.Color,
	pivot:    gmath.Pivot,
}

ScissorCommand :: struct {
	rectangle: gmath.Rectangle,
}

PopScissorCommand :: struct {}

// @ref
// Persistent state for a draggable window.
WindowState :: struct {
	position:         gmath.Vector2,
	size:             gmath.Vector2,
	isCollapsed:      bool,
	scrollY:          f32,
	contentHeight:    f32,
	commands:         [dynamic]Command,
	zIndex:           f32,
	lastFrameSeen:    u64,
	scissorRectangle: gmath.Rectangle,
}

when ODIN_DEBUG {
	// @ref
	// Internal global state for the Immediate mode UI.
	// Stores layout cursors, input state, and widget persistence maps.
	@(private = "file")
	_State :: struct {
		hotId:               u64, // widget currently hovered
		activeId:            u64, // widget currently clicked
		cursor:              gmath.Vector2, // current layout position
		startX:              f32, // where the current column started
		indentation:         f32, // current x offset
		maxWidth:            f32, // widest item in the current column
		windows:             map[u64]WindowState, // state storage
		headers:             map[u64]bool, // id -> is open
		inputBuffers:        map[u64]strings.Builder, // id -> text buffer
		tabBars:             map[u64]u64, // tab id -> active tab id
		idStack:             [dynamic]u64, // id stack for loops and scopes
		currentWindowId:     u64, // track if we are currently inside window
		focusedWindowId:     u64, // track the last clicked window
		hoveredWindowId:     u64,
		nextFocusedWindowId: u64, // candidate for focus next frame
		clickClaimedZ:       f32, // z index of window claiming the click
		inRow:               bool,
		rowStartX:           f32,
		rowMaxHeight:        f32,
		currentZIndex:       f32,
		nextZIndex:          f32,
		tooltipText:         string, // if not empty drawn at the end of frame
		lastWidgetRectangle: gmath.Rectangle, // rect of the widget just drawn
		currentTabBarId:     u64,
		tabSavedCursor:      gmath.Vector2,
		tabContentHeight:    f32,
		openComboId:         u64, // id of currently open combo
		comboWidth:          f32, // width of currently open combo
		isRecordingPopup:    bool, // true if inside uiBeginCombo
		popupCursor:         gmath.Vector2, // layout cursor for the popup
		popupCommands:       [dynamic]Command, // draw list for popup
		mousePosition:       gmath.Vector2, // store it to avoid unneeded matrix inverses
	}


	@(private = "package")
	_ui: _State
}
