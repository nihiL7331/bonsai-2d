package gmath

import "core:strconv"

// @ref
// Converts a packed 32-bit integer (**0xRRGGBBAA**) into a normalized `Color`.
// Extracts bytes and divides by 255.0 to map to the 0.0-1.0 range.
hexToColor :: proc(value: u32) -> Color {
	return Color {
		cast(f32)((value & 0xff000000) >> 24) / 255.0,
		cast(f32)((value & 0x00ff0000) >> 16) / 255.0,
		cast(f32)((value & 0x0000ff00) >> 8) / 255.0,
		cast(f32)((value & 0x000000ff)) / 255.0,
	}
}

// @ref
// Parses a hex string (e.g. **"#FF0000"** or **"FF0000FF"**) into a normalized `Color`.
// Supports both 6-digit (assumes **alpha = 1.0**) and 8-digit formats.
// Handles optional leading '#'.
stringHexToColor :: proc(hexString: string) -> Color {
	if len(hexString) == 0 do return Color{1, 1, 1, 1}

	cleanString := hexString
	if cleanString[0] == '#' do cleanString = cleanString[1:]

	value, ok := strconv.parse_u64_of_base(cleanString, 16)
	if !ok do return Color{1, 1, 1, 1}

	colorInt := u32(value)

	if len(cleanString) == 6 {
		colorInt = (colorInt << 8) | 0xFF // add alpha
	}

	return hexToColor(colorInt)
}
