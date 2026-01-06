package gmath

import "core:math"
import "core:math/linalg"

// @ref
// 2D Integer Vector (32-bit). **Useful for grid coordinates.**
Vector2Int :: [2]i32

// @ref
// 3D Integer Vector (32-bit).
Vector3Int :: [3]i32

// @ref
// 4D Integer Vector (32-bit).
Vector4Int :: [4]i32

// @ref
// Standard 2D Float Vector (compatible with Odin's **core:math/linalg** package)
Vector2 :: linalg.Vector2f32

// @ref
// Standard 3D Float Vector.
Vector3 :: linalg.Vector3f32

// @ref
// Standard 4D Float Vector.
Vector4 :: linalg.Vector4f32

// @ref
// 4x4 Float Matrix (Column-Major).
Matrix4 :: linalg.Matrix4f32

// @ref
// Enum representing the 9 cardinal points of a rectangle.
// Used for anchoring UI and aligning sprites.
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

// @ref
// Returns a normalized **Vector2** (0.0 -> +1.0) corresponding to the **Pivot** enum.
//
// **Example:**
// ```Odin
// // pivotOffset is equal to gmath.Vector2{0.5, 0.5}
// pivotOffset := gmath.scaleFromPivot(gmath.Pivot.centerCenter)
// ```
scaleFromPivot :: proc(pivot: Pivot) -> Vector2 {
	switch pivot {
	case .bottomLeft:
		return Vector2{0.0, 0.0}
	case .bottomCenter:
		return Vector2{0.5, 0.0}
	case .bottomRight:
		return Vector2{1.0, 0.0}
	case .centerLeft:
		return Vector2{0.0, 0.5}
	case .centerCenter:
		return Vector2{0.5, 0.5}
	case .centerRight:
		return Vector2{1.0, 0.5}
	case .topLeft:
		return Vector2{0.0, 1.0}
	case .topCenter:
		return Vector2{0.5, 1.0}
	case .topRight:
		return Vector2{1.0, 1.0}
	}
	return {}
}

// @ref
// Creates a translation matrix from a 2D position (Z is assumed to be 0).
matrixTranslate :: proc(position: Vector2) -> Matrix4 {
	return linalg.matrix4_translate(Vector3{position.x, position.y, 0})
}

// @ref
// Creates a rotation matrix (Z-axis) from an angle in degrees.
matrixRotate :: proc(angleDegrees: f32) -> Matrix4 {
	return linalg.matrix4_rotate(math.to_radians(angleDegrees), Vector3{0, 0, 1})
}

// @ref
// Creates a scaling matrix. Z-scale is locked to 1.0.
matrixScale :: proc(scale: Vector2) -> Matrix4 {
	return linalg.matrix4_scale(Vector3{scale.x, scale.y, 1})
}

// @ref
// Smoothly damps a float value towards a target.
// **Frame-rate independent**.
// Returns **true** if the target has been reached (within the **goodEnough** threshold).
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

// @ref
// Smoothly damps a **Vector2** towards a target.
// Returns **true** when both **x** and **y** are within the **goodEnough** threshold.
animateToTargetVector2 :: proc(
	value: ^Vector2,
	target: Vector2,
	deltaTime: f32,
	rate: f32 = 15.0,
	goodEnough: f32 = 0.001,
) -> bool {
	reachedX := animateToTargetF32(&value.x, target.x, deltaTime, rate, goodEnough)
	reachedY := animateToTargetF32(&value.y, target.y, deltaTime, rate, goodEnough)
	return reachedX && reachedY
}

// @ref
// Checks if two floats are equal within a small margin of error (**epsilon**).
almostEquals :: proc(a: f32, b: f32, epsilon: f32 = 0.001) -> bool {
	return abs(a - b) <= epsilon
}
