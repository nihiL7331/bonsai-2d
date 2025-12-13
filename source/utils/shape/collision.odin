package shape

import "core:math"
import "core:math/linalg"

import "../../types/gmath"

collide :: proc(a, b: gmath.Shape) -> (colliding: bool, depth: gmath.Vec2) {
	if a == {} || b == {} {
		return false, 0.0
	}

	switch aShape in a {
	case gmath.Rect:
		switch bShape in b {
		case gmath.Rect:
			return rectCollideRect(aShape, bShape)
		case gmath.Circle:
			return rectCollideCircle(aShape, bShape)
		}
	case gmath.Circle:
		#partial switch bShape in b {
		case gmath.Rect:
			return rectCollideCircle(bShape, aShape)
		}
	}

	assert(false, "unsupported shape collision")
	return false, {}
}

rectContains :: proc(rect: gmath.Vec4, point: gmath.Vec2) -> bool {
	return (point.x >= rect.x) && (point.x <= rect.z) && (point.y >= rect.y) && (point.y <= rect.w)
}

rectCollideCircle :: proc(aabb: gmath.Rect, circle: gmath.Circle) -> (bool, gmath.Vec2) {
	closestPoint := gmath.Vec2 {
		math.clamp(circle.pos.x, aabb.x, aabb.z),
		math.clamp(circle.pos.y, aabb.y, aabb.w),
	}

	distance := linalg.length(closestPoint - circle.pos)

	return distance <= circle.radius, {}
}

rectCollideRect :: proc(a: gmath.Rect, b: gmath.Rect) -> (bool, gmath.Vec2) {
	dx := (a.z + a.x) / 2 - (b.z + b.x) / 2
	dy := (a.w + a.y) / 2 - (b.w + b.y) / 2

	overlapX := (a.z - a.x) / 2 + (b.z - b.x) / 2 - abs(dx)
	overlapY := (a.w - a.y) / 2 + (b.w - b.y) / 2 - abs(dy)

	if overlapX <= 0 || overlapY <= 0 {
		return false, gmath.Vec2{}
	}

	penetration := gmath.Vec2{}
	if overlapX < overlapY {
		penetration.x = overlapX if dx > 0 else -overlapX
	} else {
		penetration.y = overlapY if dy > 0 else -overlapY
	}

	return true, penetration
}
