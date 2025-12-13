package shape

import utils "../"
import "../../types/gmath"

rectGetCenter :: proc(rect: gmath.Vec4) -> gmath.Vec2 {
	min := rect.xy
	max := rect.zw
	return {min.x + 0.5 * (max.x - min.x), min.y + 0.5 * (max.y - min.y)}
}

rectMakeWithPos :: proc(
	pos: gmath.Vec2,
	size: gmath.Vec2,
	pivot := gmath.Pivot.bottomLeft,
) -> gmath.Vec4 {
	rect := gmath.Vec4{0, 0, size.x, size.y}
	rect = rectShift(rect, pos - utils.scaleFromPivot(pivot) * size)
	return rect
}

rectMakeWithSize :: proc(size: gmath.Vec2, pivot: gmath.Pivot) -> gmath.Vec4 {
	return rectMake({}, size, pivot)
}

rectMake :: proc {
	rectMakeWithPos,
	rectMakeWithSize,
}

rectShift :: proc(rect: gmath.Vec4, amount: gmath.Vec2) -> gmath.Vec4 {
	return {rect.x + amount.x, rect.y + amount.y, rect.z + amount.x, rect.w + amount.y}
}

rectSize :: proc(rect: gmath.Rect) -> gmath.Vec2 {
	return {abs(rect.x - rect.z), abs(rect.y - rect.w)}
}

rectScale :: proc(rect: gmath.Rect, scale: f32) -> gmath.Rect {
	rect := rect
	origin := rect.xy
	rect = rectShift(rect, -origin)
	scaleAmount := (rect.zw * scale) - rect.zw
	rect.xy -= scaleAmount / 2
	rect.zw += scaleAmount / 2
	rect = rectShift(rect, origin)
	return rect
}

rectScaleVec2 :: proc(rect: gmath.Rect, scale: gmath.Vec2) -> gmath.Rect {
	rect := rect
	origin := rect.xy
	rect = rectShift(rect, -origin)

	scaleAmount := (rect.zw * scale) - rect.zw

	rect.xy -= scaleAmount / 2
	rect.zw += scaleAmount / 2

	rect = rectShift(rect, origin)
	return rect
}

rectExpand :: proc(rect: gmath.Rect, amount: f32) -> gmath.Rect {
	rect := rect
	rect.xy -= amount
	rect.zw += amount
	return rect
}

circleShift :: proc(circle: gmath.Circle, amount: gmath.Vec2) -> gmath.Circle {
	circle := circle
	circle.pos += amount
	return circle
}

shift :: proc(s: gmath.Shape, amount: gmath.Vec2) -> gmath.Shape {
	if s == {} || amount == {} {
		return s
	}

	switch shape in s {
	case gmath.Rect:
		return rectShift(shape, amount)
	case gmath.Circle:
		return circleShift(shape, amount)
	case:
		{
			assert(false, "Unsupported shape shift")
			return {}
		}}
}
