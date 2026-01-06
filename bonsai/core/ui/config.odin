package ui

import "bonsai:core/gmath"
import "bonsai:types/game"

DEFAULT_FONT_SIZE :: 12
DEFAULT_FONT :: game.FontName.PixelCode

// --- GRUVBOX MATERIAL PALETTE (Dark Hard) ---
GRUV_BG_HARD :: gmath.Vector4{40.0 / 255.0, 40.0 / 255.0, 40.0 / 255.0, 1.0} // #282828
GRUV_BG_SOFT :: gmath.Vector4{50.0 / 255.0, 48.0 / 255.0, 47.0 / 255.0, 1.0} // #32302f
GRUV_BG0 :: gmath.Vector4{60.0 / 255.0, 56.0 / 255.0, 54.0 / 255.0, 1.0} // #3c3836
GRUV_BG1 :: gmath.Vector4{80.0 / 255.0, 73.0 / 255.0, 69.0 / 255.0, 1.0} // #504945
GRUV_FG0 :: gmath.Vector4{212.0 / 255.0, 190.0 / 255.0, 152.0 / 255.0, 1.0} // #d4be98
GRUV_FG1 :: gmath.Vector4{221.0 / 255.0, 199.0 / 255.0, 161.0 / 255.0, 1.0} // #ddc7a1

GRUV_RED :: gmath.Vector4{234.0 / 255.0, 105.0 / 255.0, 98.0 / 255.0, 1.0} // #ea6962
GRUV_ORANGE :: gmath.Vector4{231.0 / 255.0, 138.0 / 255.0, 78.0 / 255.0, 1.0} // #e78a4e
GRUV_YELLOW :: gmath.Vector4{216.0 / 255.0, 166.0 / 255.0, 87.0 / 255.0, 1.0} // #d8a657
GRUV_GREEN :: gmath.Vector4{169.0 / 255.0, 182.0 / 255.0, 101.0 / 255.0, 1.0} // #a9b665
GRUV_AQUA :: gmath.Vector4{137.0 / 255.0, 180.0 / 255.0, 250.0 / 255.0, 1.0} // #89b482
GRUV_BLUE :: gmath.Vector4{125.0 / 255.0, 174.0 / 255.0, 163.0 / 255.0, 1.0} // #7daea3
GRUV_GREY :: gmath.Vector4{146.0 / 255.0, 131.0 / 255.0, 116.0 / 255.0, 1.0} // #928374

DEFAULT_WINDOW_CONFIG: WindowConfig = {
	// LAYOUT
	pivot                       = gmath.Pivot.centerCenter,
	maximumHeight               = 50,
	// WINDOW STYLE
	backgroundColor             = GRUV_BG_HARD,
	borderColor                 = GRUV_BG0,
	// HEADER STYLE
	headerMargin                = gmath.Vector4{1, 2, 1, 2},
	// HEADER BACKGROUND COLORS
	headerBackgroundNormalColor = GRUV_BG_SOFT,
	headerBackgroundHoverColor  = GRUV_BG0,
	headerBackgroundActiveColor = GRUV_BG1,
	// HEADER TEXT COLORS
	headerTextNormalColor       = GRUV_FG0,
	headerTextHoverColor        = GRUV_FG1,
	headerTextActiveColor       = GRUV_YELLOW,
	// CLOSE BUTTON STYLE
	closeNormalColor            = GRUV_FG0,
	closeHoverColor             = GRUV_RED,
	closeActiveColor            = GRUV_FG1,
	closeRune                   = '-',
	// TOGGLE BUTTON STYLE
	toggleNormalColor           = GRUV_FG0,
	toggleHoverColor            = GRUV_YELLOW,
	toggleActiveColor           = GRUV_FG1,
	toggleRune                  = '^',
	// SCROLLBAR STYLE
	scrollbarBackgroundColor    = GRUV_BG0,
	scrollbarThumbColor         = GRUV_GREY,
	scrollbarWidth              = 2,
	scrollbarSpeed              = 30,
}

DEFAULT_BUTTON_CONFIG: ButtonConfig = {
	// LAYOUT
	pivot                 = gmath.Pivot.centerCenter,
	padding               = gmath.Vector2{4, 2},
	margin                = gmath.Vector4{2, 2, 2, 2},
	// BACKGROUND COLORS
	backgroundNormalColor = GRUV_BG0,
	backgroundHoverColor  = GRUV_BG1,
	backgroundActiveColor = GRUV_GREY,
	// TEXT COLORS
	textNormalColor       = GRUV_FG0,
	textHoverColor        = GRUV_FG1,
	textActiveColor       = GRUV_BG_HARD,
}

DEFAULT_TEXT_CONFIG: TextConfig = {
	// LAYOUT
	pivot           = gmath.Pivot.centerLeft,
	padding         = gmath.Vector2{2, 2},
	margin          = gmath.Vector4{2, 2, 2, 2},
	// COLORS
	backgroundColor = gmath.Vector4{0, 0, 0, 0},
	textColor       = GRUV_FG0,
}

DEFAULT_CHECKBOX_CONFIG: CheckboxConfig = {
	// LAYOUT
	pivot                 = gmath.Pivot.centerRight,
	padding               = gmath.Vector2{0, 0},
	margin                = gmath.Vector4{2, 2, 2, 2},
	// BACKGROUND COLORS
	backgroundNormalColor = GRUV_BG0,
	backgroundHoverColor  = GRUV_BG1,
	backgroundActiveColor = GRUV_GREEN,
	// TEXT COLORS
	textNormalColor       = GRUV_GREY,
	textHoverColor        = GRUV_FG0,
	textActiveColor       = GRUV_BG_HARD,
	// TEXT STYLE
	checkboxRune          = 'x',
	checkboxRuneScale     = 0.8,
}

DEFAULT_SLIDER_CONFIG: SliderConfig = {
	// LAYOUT
	padding               = gmath.Vector2{0, 0},
	margin                = gmath.Vector4{1, 2, 1, 2},
	// BACKGROUND COLORS
	backgroundNormalColor = GRUV_BG0,
	backgroundHoverColor  = GRUV_BG1,
	backgroundActiveColor = GRUV_BG1,
	// BACKGROUND STYLE
	backgroundHeight      = 8,
	// FILL COLORS
	fillNormalColor       = GRUV_GREY,
	fillHoverColor        = GRUV_BLUE,
	fillActiveColor       = GRUV_AQUA,
	// THUMB COLORS
	thumbNormalColor      = GRUV_FG0,
	thumbHoverColor       = GRUV_FG1,
	thumbActiveColor      = GRUV_FG1,
	// THUMB STYLE
	thumbWidth            = 4,
	thumbPadding          = gmath.Vector2{0, 1},
}

WindowConfig :: struct {
	// LAYOUT
	pivot:                       Maybe(gmath.Pivot),
	maximumHeight:               Maybe(f32),
	// WINDOW STYLE
	backgroundColor:             Maybe(gmath.Vector4),
	borderColor:                 Maybe(gmath.Vector4),
	// HEADER STYLE
	headerMargin:                Maybe(gmath.Vector4),
	// HEADER BACKGROUND COLORS
	headerBackgroundNormalColor: Maybe(gmath.Vector4),
	headerBackgroundHoverColor:  Maybe(gmath.Vector4),
	headerBackgroundActiveColor: Maybe(gmath.Vector4),
	// HEADER TEXT COLORS
	headerTextNormalColor:       Maybe(gmath.Vector4),
	headerTextHoverColor:        Maybe(gmath.Vector4),
	headerTextActiveColor:       Maybe(gmath.Vector4),
	// CLOSE BUTTON STYLE
	closeNormalColor:            Maybe(gmath.Vector4),
	closeHoverColor:             Maybe(gmath.Vector4),
	closeActiveColor:            Maybe(gmath.Vector4),
	closeRune:                   Maybe(rune),
	// TOGGLE BUTTON STYLE
	toggleNormalColor:           Maybe(gmath.Vector4),
	toggleHoverColor:            Maybe(gmath.Vector4),
	toggleActiveColor:           Maybe(gmath.Vector4),
	toggleRune:                  Maybe(rune),
	// SCROLLBAR STYLE
	scrollbarBackgroundColor:    Maybe(gmath.Vector4),
	scrollbarThumbColor:         Maybe(gmath.Vector4),
	scrollbarWidth:              Maybe(f32),
	scrollbarSpeed:              Maybe(f32),
}

WindowStyle :: struct {
	// LAYOUT
	pivot:                       gmath.Pivot,
	maximumHeight:               f32,
	// WINDOW STYLE
	backgroundColor:             gmath.Vector4,
	borderColor:                 gmath.Vector4,
	// HEADER STYLE
	headerMargin:                gmath.Vector4,
	// HEADER BACKGROUND COLORS
	headerBackgroundNormalColor: gmath.Vector4,
	headerBackgroundHoverColor:  gmath.Vector4,
	headerBackgroundActiveColor: gmath.Vector4,
	// HEADER TEXT COLORS
	headerTextNormalColor:       gmath.Vector4,
	headerTextHoverColor:        gmath.Vector4,
	headerTextActiveColor:       gmath.Vector4,
	// CLOSE BUTTON STYLE
	closeNormalColor:            gmath.Vector4,
	closeHoverColor:             gmath.Vector4,
	closeActiveColor:            gmath.Vector4,
	closeRune:                   rune,
	// TOGGLE BUTTON STYLE
	toggleNormalColor:           gmath.Vector4,
	toggleHoverColor:            gmath.Vector4,
	toggleActiveColor:           gmath.Vector4,
	toggleRune:                  rune,
	// SCROLLBAR STYLE
	scrollbarBackgroundColor:    gmath.Vector4,
	scrollbarThumbColor:         gmath.Vector4,
	scrollbarWidth:              f32,
	scrollbarSpeed:              f32,
}

ButtonConfig :: struct {
	// LAYOUT
	pivot:                 Maybe(gmath.Pivot),
	padding:               Maybe(gmath.Vector2),
	margin:                Maybe(gmath.Vector4),
	// BACKGROUND COLORS
	backgroundNormalColor: Maybe(gmath.Vector4),
	backgroundHoverColor:  Maybe(gmath.Vector4),
	backgroundActiveColor: Maybe(gmath.Vector4),
	// TEXT COLORS
	textNormalColor:       Maybe(gmath.Vector4),
	textHoverColor:        Maybe(gmath.Vector4),
	textActiveColor:       Maybe(gmath.Vector4),
}

ButtonStyle :: struct {
	// LAYOUT
	pivot:                 gmath.Pivot,
	padding:               gmath.Vector2,
	margin:                gmath.Vector4,
	// BACKGROUND COLORS
	backgroundNormalColor: gmath.Vector4,
	backgroundHoverColor:  gmath.Vector4,
	backgroundActiveColor: gmath.Vector4,
	// TEXT COLORS
	textNormalColor:       gmath.Vector4,
	textHoverColor:        gmath.Vector4,
	textActiveColor:       gmath.Vector4,
}

TextConfig :: struct {
	// LAYOUT
	pivot:           Maybe(gmath.Pivot),
	padding:         Maybe(gmath.Vector2),
	margin:          Maybe(gmath.Vector4),
	// COLORS
	backgroundColor: Maybe(gmath.Vector4),
	textColor:       Maybe(gmath.Vector4),
}

TextStyle :: struct {
	// LAYOUT
	pivot:           gmath.Pivot,
	padding:         gmath.Vector2,
	margin:          gmath.Vector4,
	// COLORS
	backgroundColor: gmath.Vector4,
	textColor:       gmath.Vector4,
}

CheckboxConfig :: struct {
	// LAYOUT
	pivot:                 Maybe(gmath.Pivot),
	padding:               Maybe(gmath.Vector2),
	margin:                Maybe(gmath.Vector4),
	// BACKGROUND COLORS
	backgroundNormalColor: Maybe(gmath.Vector4),
	backgroundHoverColor:  Maybe(gmath.Vector4),
	backgroundActiveColor: Maybe(gmath.Vector4),
	// TEXT COLORS
	textNormalColor:       Maybe(gmath.Vector4),
	textHoverColor:        Maybe(gmath.Vector4),
	textActiveColor:       Maybe(gmath.Vector4),
	// TEXT STYLE
	checkboxRune:          Maybe(rune),
	checkboxRuneScale:     Maybe(f32),
}

CheckboxStyle :: struct {
	// LAYOUT
	pivot:                 gmath.Pivot,
	padding:               gmath.Vector2,
	margin:                gmath.Vector4,
	// BACKGROUND COLORS
	backgroundNormalColor: gmath.Vector4,
	backgroundHoverColor:  gmath.Vector4,
	backgroundActiveColor: gmath.Vector4,
	// TEXT COLORS
	textNormalColor:       gmath.Vector4,
	textHoverColor:        gmath.Vector4,
	textActiveColor:       gmath.Vector4,
	// TEXT STYLE
	checkboxRune:          rune,
	checkboxRuneScale:     f32,
}

SliderConfig :: struct {
	// LAYOUT
	padding:               Maybe(gmath.Vector2),
	margin:                Maybe(gmath.Vector4),
	// BACKGROUND COLORS
	backgroundNormalColor: Maybe(gmath.Vector4),
	backgroundHoverColor:  Maybe(gmath.Vector4),
	backgroundActiveColor: Maybe(gmath.Vector4),
	// BACKGROUND STYLE
	backgroundHeight:      Maybe(f32),
	// FILL COLORS
	fillNormalColor:       Maybe(gmath.Vector4),
	fillHoverColor:        Maybe(gmath.Vector4),
	fillActiveColor:       Maybe(gmath.Vector4),
	// THUMB COLORS
	thumbNormalColor:      Maybe(gmath.Vector4),
	thumbHoverColor:       Maybe(gmath.Vector4),
	thumbActiveColor:      Maybe(gmath.Vector4),
	// THUMB STYLE
	thumbWidth:            Maybe(f32),
	thumbPadding:          Maybe(gmath.Vector2),
}

SliderStyle :: struct {
	// LAYOUT
	padding:               gmath.Vector2,
	margin:                gmath.Vector4,
	// BACKGROUND COLORS
	backgroundNormalColor: gmath.Vector4,
	backgroundHoverColor:  gmath.Vector4,
	backgroundActiveColor: gmath.Vector4,
	// BACKGROUND STYLE
	backgroundHeight:      f32,
	// FILL COLORS
	fillNormalColor:       gmath.Vector4,
	fillHoverColor:        gmath.Vector4,
	fillActiveColor:       gmath.Vector4,
	// THUMB COLORS
	thumbNormalColor:      gmath.Vector4,
	thumbHoverColor:       gmath.Vector4,
	thumbActiveColor:      gmath.Vector4,
	// THUMB STYLE
	thumbWidth:            f32,
	thumbPadding:          gmath.Vector2,
}
