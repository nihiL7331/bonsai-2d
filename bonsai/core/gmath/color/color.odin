package color

import "core:strconv"

import "bonsai:core/gmath"

// @ref
// Converts a packed 32-bit integer (**0xRRGGBBAA**) into a normalized Vector4 color.
// Extracts bytes and divides by 255.0 to map to the 0.0-1.0 range.
hexToRgba :: proc(v: u32) -> gmath.Vector4 {
	return gmath.Vector4 {
		cast(f32)((v & 0xff000000) >> 24) / 255.0,
		cast(f32)((v & 0x00ff0000) >> 16) / 255.0,
		cast(f32)((v & 0x0000ff00) >> 8) / 255.0,
		cast(f32)((v & 0x000000ff)) / 255.0,
	}
}

// @ref
// Parses a hex string (e.g. **"#FF0000"** or **"FF0000FF"**) into a normalized **Vector4** color.
// Supports both 6-digit (assumes **alpha = 1.0**) and 8-digit formats.
// Handles optional leading '#'.
stringHexToRgba :: proc(hexStr: string) -> gmath.Vector4 {
	if len(hexStr) == 0 do return gmath.Vector4{1, 1, 1, 1}

	cleanStr := hexStr
	if cleanStr[0] == '#' do cleanStr = cleanStr[1:]

	val, ok := strconv.parse_u64_of_base(cleanStr, 16)
	if !ok do return gmath.Vector4{1, 1, 1, 1}

	colorInt := u32(val)

	if len(cleanStr) == 6 {
		colorInt = (colorInt << 8) | 0xFF // add alpha
	}

	return hexToRgba(colorInt)
}

WHITE :: gmath.Vector4{1, 1, 1, 1}
BLACK :: gmath.Vector4{0, 0, 0, 1}
RED :: gmath.Vector4{1, 0, 0, 1}
GREEN :: gmath.Vector4{0, 1, 0, 1}
BLUE :: gmath.Vector4{0, 0, 1, 1}
GRAY :: gmath.Vector4{0.5, 0.5, 0.5, 1.0}
TRANSPARENT :: gmath.Vector4{0, 0, 0, 0}
