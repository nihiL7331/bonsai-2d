package gmath

import "core:math"
import "core:math/linalg"

Vec2 :: linalg.Vector2f32
Vec3 :: linalg.Vector3f32
Vec4 :: linalg.Vector4f32
Mat4 :: linalg.Matrix4f32

Pivot :: enum {
	bottomLeft,
	bottomCenter,
	bottomRight,
	centerLeft,
	centerCenter,
	centerRight,
	topLeft,
	topCenter,
	topRight,
}

scaleFromPivot :: proc(pivot: Pivot) -> Vec2 {
	switch pivot {
	case .bottomLeft:
		return Vec2{0.0, 0.0}
	case .bottomCenter:
		return Vec2{0.5, 0.0}
	case .bottomRight:
		return Vec2{1.0, 0.0}
	case .centerLeft:
		return Vec2{0.0, 0.5}
	case .centerCenter:
		return Vec2{0.5, 0.5}
	case .centerRight:
		return Vec2{1.0, 0.5}
	case .topLeft:
		return Vec2{0.0, 1.0}
	case .topCenter:
		return Vec2{0.5, 1.0}
	case .topRight:
		return Vec2{1.0, 1.0}
	}
	return {}
}

xFormTranslate :: proc(pos: Vec2) -> Mat4 {
	return linalg.matrix4_translate(Vec3{pos.x, pos.y, 0})
}
xFormRotate :: proc(angle: f32) -> Mat4 {
	return linalg.matrix4_rotate(math.to_radians(angle), Vec3{0, 0, 1})
}
xFormScale :: proc(scale: Vec2) -> Mat4 {
	return linalg.matrix4_scale(Vec3{scale.x, scale.y, 1})
}

animateToTargetF32 :: proc(
	value: ^f32,
	target: f32,
	deltaTime: f32,
	rate: f32 = 15.0,
	goodEnough: f32 = 0.001,
) -> bool {
	value^ += (target - value^) * (1.0 - math.pow_f32(2.0, -rate * deltaTime))
	if almostEquals(value^, target, goodEnough) {
		value^ = target
		return true
	}
	return false
}

animateToTargetVec2 :: proc(
	value: ^Vec2,
	target: Vec2,
	deltaTime: f32,
	rate: f32 = 15.0,
	goodEnough: f32 = 0.001,
) -> bool {
	reachedX := animateToTargetF32(&value.x, target.x, deltaTime, rate, goodEnough)
	reachedY := animateToTargetF32(&value.y, target.y, deltaTime, rate, goodEnough)
	return reachedX && reachedY
}

almostEquals :: proc(a: f32, b: f32, epsilon: f32 = 0.001) -> bool {
	return abs(a - b) <= epsilon
}
