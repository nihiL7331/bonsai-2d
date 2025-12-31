package color

import "core:strconv"

import "bonsai:types/gmath"

hexToRGBA :: proc(v: u32) -> gmath.Vec4 {
	return gmath.Vec4 {
		cast(f32)((v & 0xff000000) >> 24) / 255.0,
		cast(f32)((v & 0x00ff0000) >> 16) / 255.0,
		cast(f32)((v & 0x0000ff00) >> 8) / 255.0,
		cast(f32)((v & 0x000000ff)) / 255.0,
	}
}

stringHexToRGBA :: proc(hexStr: string) -> gmath.Vec4 {
	if len(hexStr) == 0 do return gmath.Vec4{1, 1, 1, 1}

	cleanStr := hexStr
	if cleanStr[0] == '#' do cleanStr = cleanStr[1:]

	val, ok := strconv.parse_u64_of_base(cleanStr, 16)
	if !ok do return gmath.Vec4{1, 1, 1, 1}

	colorInt := u32(val)

	if len(cleanStr) == 6 {
		colorInt = (colorInt << 8) | 0xFF // add alpha
	}

	return hexToRGBA(colorInt)
}

WHITE :: gmath.Vec4{1, 1, 1, 1}
BLACK :: gmath.Vec4{0, 0, 0, 1}
RED :: gmath.Vec4{1, 0, 0, 1}
GREEN :: gmath.Vec4{0, 1, 0, 1}
BLUE :: gmath.Vec4{0, 0, 1, 1}
GRAY :: gmath.Vec4{0.5, 0.5, 0.5, 1.0}
TRANSPARENT :: gmath.Vec4{0, 0, 0, 0}
