package gmath

//
// This file contains all of the most important math functions used for game development purposes.
//

import "base:intrinsics"
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
// `Color` is an alias for a standard 4D Float Vector.
Color :: Vector4

// @ref
// Constant π value.
PI :: math.PI

// @ref
// Constant τ value. Equal to 2π.
TAU :: math.TAU

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
// Returns a normalized `Vector2` (0.0 -> +1.0) corresponding to the `Pivot` enum.
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
// Returns the length (**magnitude**) of the vector `input`.
//
// **Example:**
// ```Odin
// point := gmath.Vector2{2, 2}
// pointLength := gmath.length(point) // Returns distance from {0, 0} = 4√2
// ```
length :: proc {
	_lengthVector2,
	_lengthVector3,
	_lengthVector4,
}

// @ref
// Returns the squared length of the vector `input`.
// **Faster** than `length()` because it doesn't use the square root operation.
// Useful for distance comparisons.
//
// **Example**:
// ```Odin
// pointA := gmath.Vector2{100, 100}
// pointB := gmath.Vector2{5, 5}
// result := gmath.lengthSquared(pointA) > gmath.lengthSquared(pointB) // result is true
// ```
lengthSquared :: proc {
	_lengthSquaredVector2,
	_lengthSquaredVector3,
	_lengthSquaredVector4,
}

// @ref
// Returns the normalized direction of the vector `input` (with length of 1).
//
// Returns `{0, 0}` if the `input` vector is zero to prevent `nil` errors.
//
// **Example**:
// ```Odin
// direction := gmath.Vector2{100, 0}
// directionNormalized := gmath.normalize(direction) // directionNormalized is gmath.Vector2{1, 0}
// ```
normalize :: proc {
	_normalizeVector2,
	_normalizeVector3,
	_normalizeVector4,
}

// @ref
// Returns the distance between points `a` and `b`.
//
// **Example:**
// ```Odin
// pointA := gmath.Vector2{3, 0}
// pointB := gmath.Vector2{3, 4}
// dist := gmath.distance(pointA, pointB) // dist is 4
// ```
distance :: proc {
	_distanceVector2,
	_distanceVector3,
	_distanceVector4,
}

// @ref
// Returns a normalized direction vector pointing from `start` to `end`.
//
// **Example:**
// ```Odin
// start := gmath.Vector2{4, 0}
// end := gmath.Vector2{4, -9}
// dir := gmath.direction(start, end) // dir is gmath.Vector2{0, -1}
// ```
direction :: proc {
	_directionVector2,
	_directionVector3,
	_directionVector4,
}

// @ref
// Creates a translation matrix from a 2D position (Z is assumed to be 0).
matrixTranslate :: proc(position: Vector2) -> Matrix4 {
	return linalg.matrix4_translate(Vector3{position.x, position.y, 0})
}

// @ref
// Creates a rotation matrix (Z-axis) from an angle **in radians**.
matrixRotate :: proc(radians: f32) -> Matrix4 {
	return linalg.matrix4_rotate(radians, Vector3{0, 0, 1})
}

// @ref
// Creates a scaling matrix. Z-scale is locked to 1.0.
matrixScale :: proc(scale: Vector2) -> Matrix4 {
	return linalg.matrix4_scale(Vector3{scale.x, scale.y, 1})
}

// @ref
// Checks if two floats are equal within a small margin of error (`epsilon`).
almostEquals :: proc(a: f32, b: f32, epsilon: f32 = 0.001) -> bool {
	return abs(a - b) <= epsilon
}

// @ref
// Converts degrees to radians.
toRadians :: proc(degrees: $T) -> T {
	return degrees * (PI / 180.0)
}

// @ref
// Converts radians to degrees.
toDegrees :: proc(radians: $T) -> T {
	return radians * (180.0 / PI)
}

// @ref
// Clamps `input` between `min` and `max`.
clamp :: proc {
	_clampScalar,
	_clampVector2,
	_clampVector3,
	_clampVector4,
	_clampVector2Int,
	_clampVector3Int,
	_clampVector4Int,
}

// @ref
// Rounds the float `input` vector to the nearest integer vector.
//
// **Example:**
// ```Odin
// value := gmath.Vector3{5.1, 7.6, 6.9}
// roundedValue := gmath.roundToInt(value) // roundedValue is gmath.Vector3Int{5, 8, 7}
// ```
roundToInt :: proc {
	_roundToIntVector2,
	_roundToIntVector3,
	_roundToIntVector4,
}

// @ref
// Linearly interpolates between `a` and `b` by the fraction `t`.
// Useful for smooth transitions, animations, or mixing colors.
// Accepts scalar arguments, as well as `Vector2`, `Vector3`, `Vector4` and `Color`.
//
// **Note:** The value of `t` is **not clamped** to the 0-1 range.
//
// **Example:**
// ```Odin
// start := gmath.Vector2{4, 4}
// finish := gmath.Vector2{16, 16}
// result := gmath.lerp(start, finish, 0.5) // result is gmath.Vector2{10, 10}
// ```
lerp :: proc {
	_lerpScalar,
	_lerpVector2,
	_lerpVector3,
	_lerpVector4,
}

// @ref
// Remaps `input` from the `[inMin, inMax]` range to the `[outMin, outMax]` range.
//
// **Example:**
// ```Odin
// remapped := gmath.remap(50, 0, 100, 0, 1.0) // remapped is 0.5
// ```
remap :: proc(input, inMin, inMax, outMin, outMax: $T) -> T {
	return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
}

// @ref
// **Returns**:
// - +1, if `input` is greater than zero.
// - 0, if `input` is equal to zero.
// - -1, if `input` is smaller than zero.
sign :: proc(input: $T) -> T {
	return math.sign(input)
}

// @ref
// Returns the smallest value among all arguments.
// If arguments are vectors, returns a component-wise minimum vector.
// Accepts any number of arguments (minimum 1).
// If no arguments are provided, returns `0`.
//
// **Example:**
// ```Odin
// minimum := gmath.min(10, 5, 20) // minimum is 5
// vectorMinimum := gmath.min(vectorA, vectorB) // vectorMinimum is a component-wise minimum vector
// ```
min :: proc {
	_minScalar,
	_minVector2,
	_minVector3,
	_minVector4,
	_minVector2Int,
	_minVector3Int,
	_minVector4Int,
}

// @ref
// Returns the largest value among all arguments.
// If arguments are vectors, returns a component-wise maximum vector.
// Accepts any number of arguments (minimum 1).
// If no arguments are provided, returns `0`.
//
// **Example:**
// ```Odin
// maximum := gmath.max(10, 30, 20) // maximum is 30
// vectorMaximum := gmath.max(vectorA, vectorB) // vectorMaximum is a component-wise maximum vector
// ```
max :: proc {
	_maxScalar,
	_maxVector2,
	_maxVector3,
	_maxVector4,
	_maxVector2Int,
	_maxVector3Int,
	_maxVector4Int,
}

// @ref
// Returns the absolute value of `input`.
// - For **scalars**: Returns the non-negative value.
// - For **vectors**: Returns a new vector where every component is positive.
//
// **Example:**
// ```Odin
// direction := gmath.Vector2{-1, -1}
// result := gmath.abs(direction) // result is gmath.Vector2{1, 1}
// ```
abs :: proc {
	_absScalar,
	_absVector2,
	_absVector3,
	_absVector4,
	_absVector2Int,
	_absVector3Int,
	_absVector4Int,
}

// @ref
// Retuns the sine of the angle **(in radians)**.
// - For **scalars**: Standard trigonometric sin function.
// - For **vectors**: Component-wise sine.
//
// **Example:**
// ```Odin
// wave := gmath.Vector2{ -gmath.PI / 2, gmath.PI / 2 }
// result := gmath.sin(wave) // result is gmath.Vector2{ -1, 1 }
// ```
sin :: proc {
	_sinScalar,
	_sinVector2,
	_sinVector3,
	_sinVector4,
}

// @ref
// Returns the cosine of the angle **(in radians)**.
// - For **scalars**: Standard trigonometric cos function.
// - For **vectors**: Component-wise cosine.
//
// **Example:**
// ```Odin
// wave := gmath.Vector2{ 0, gmath.PI / 2 }
// result := gmath.cos(wave) // result is gmath.Vector2{ 1, 0 }
// ```
cos :: proc {
	_cosScalar,
	_cosVector2,
	_cosVector3,
	_cosVector4,
}

// @ref
// Returns the angle in radians between the x-axis and the ray from (0,0) to (y,x).
//
// **Crucial for rotation**: To make an object at `position` look at `target`, use:
//
// `angle := gmath.atan2(target.y - position.y, target.x - position.x)`
atan2 :: proc(y, x: $T) -> T {
	return math.atan2(y, x)
}

// @ref
// An alias for the `atan2` function. Might be more descriptive to some.
vectorToAngle :: atan2

// @ref
// Returns a normalized direction vector from an angle **(in radians)**.
angleToVector :: proc(radians: f32) -> Vector2 {
	return Vector2{math.cos(radians), math.sin(radians)}
}

// Scalar helper for the lerp function.
@(private = "file")
_lerpScalar :: proc(a, b: $T, t: f32) -> T {
	return math.lerp(a, b, t)
}

// Vector2 helper for the lerp function.
@(private = "file")
_lerpVector2 :: proc(a, b: Vector2, t: f32) -> Vector2 {
	return a + (b - a) * t
}

// Vector3 helper for the lerp function.
@(private = "file")
_lerpVector3 :: proc(a, b: Vector3, t: f32) -> Vector3 {
	return a + (b - a) * t
}

// Vector4 helper for the lerp function.
@(private = "file")
_lerpVector4 :: proc(a, b: Vector4, t: f32) -> Vector4 {
	return a + (b - a) * t
}

// Scalar helper for the abs function.
@(private = "file")
_absScalar :: proc(input: $T) -> T {
	return math.abs(input)
}

// Vector2 helper for the abs function.
@(private = "file")
_absVector2 :: proc(input: Vector2) -> Vector2 {
	return Vector2{math.abs(input.x), math.abs(input.y)}
}

// Vector3 helper for the abs function.
@(private = "file")
_absVector3 :: proc(input: Vector3) -> Vector3 {
	return Vector3{math.abs(input.x), math.abs(input.y), math.abs(input.z)}
}

// Vector4 helper for the abs function.
@(private = "file")
_absVector4 :: proc(input: Vector4) -> Vector4 {
	return Vector4{math.abs(input.x), math.abs(input.y), math.abs(input.z), math.abs(input.w)}
}

// Vector2Int helper for the abs function.
@(private = "file")
_absVector2Int :: proc(input: Vector2Int) -> Vector2Int {
	return Vector2Int{math.abs(input.x), math.abs(input.y)}
}

// Vector3Int helper for the abs function.
@(private = "file")
_absVector3Int :: proc(input: Vector3Int) -> Vector3Int {
	return Vector3Int{math.abs(input.x), math.abs(input.y), math.abs(input.z)}
}

// Vector4Int helper for the abs function.
@(private = "file")
_absVector4Int :: proc(input: Vector4Int) -> Vector4Int {
	return Vector4Int{math.abs(input.x), math.abs(input.y), math.abs(input.z), math.abs(input.w)}
}

// Scalar helper for the sin function.
@(private = "file")
_sinScalar :: proc(radians: $T) -> T where intrinsics.type_is_float(T) {
	return math.sin(radians)
}

// Scalar helper for the cos function.
@(private = "file")
_cosScalar :: proc(radians: $T) -> T where intrinsics.type_is_float(T) {
	return math.cos(radians)
}

// Vector2 helper for the sin function.
@(private = "file")
_sinVector2 :: proc(radians: Vector2) -> Vector2 {
	return Vector2{math.sin(radians.x), math.sin(radians.y)}
}

// Vector2 helper for the cos function.
@(private = "file")
_cosVector2 :: proc(radians: Vector2) -> Vector2 {
	return Vector2{math.cos(radians.x), math.cos(radians.y)}
}

// Vector3 helper for the sin function.
@(private = "file")
_sinVector3 :: proc(radians: Vector3) -> Vector3 {
	return Vector3{math.sin(radians.x), math.sin(radians.y), math.sin(radians.z)}
}

// Vector3 helper for the cos function.
@(private = "file")
_cosVector3 :: proc(radians: Vector3) -> Vector3 {
	return Vector3{math.cos(radians.x), math.cos(radians.y), math.cos(radians.z)}
}

// Vector4 helper for the sin function.
@(private = "file")
_sinVector4 :: proc(radians: Vector4) -> Vector4 {
	return Vector4 {
		math.sin(radians.x),
		math.sin(radians.y),
		math.sin(radians.z),
		math.sin(radians.w),
	}
}

// Vector4 helper for the cos function.
@(private = "file")
_cosVector4 :: proc(radians: Vector4) -> Vector4 {
	return Vector4 {
		math.cos(radians.x),
		math.cos(radians.y),
		math.cos(radians.z),
		math.cos(radians.w),
	}
}

// Vector2 helper for the lengthSquared function.
@(private = "file")
_lengthSquaredVector2 :: proc(input: Vector2) -> f32 {
	return input.x * input.x + input.y * input.y
}

// Vector3 helper for the lengthSquared function.
@(private = "file")
_lengthSquaredVector3 :: proc(input: Vector3) -> f32 {
	return input.x * input.x + input.y * input.y + input.z * input.z
}

// Vector4 helper for the lengthSquared function.
@(private = "file")
_lengthSquaredVector4 :: proc(input: Vector4) -> f32 {
	return input.x * input.x + input.y * input.y + input.z * input.z + input.w * input.w
}

// Vector2 helper for the length function.
@(private = "file")
_lengthVector2 :: proc(input: Vector2) -> f32 {
	return math.sqrt(_lengthSquaredVector2(input))
}

// Vector3 helper for the length function.
@(private = "file")
_lengthVector3 :: proc(input: Vector3) -> f32 {
	return math.sqrt(_lengthSquaredVector3(input))
}

// Vector4 helper for the length function.
@(private = "file")
_lengthVector4 :: proc(input: Vector4) -> f32 {
	return math.sqrt(_lengthSquaredVector4(input))
}

// Vector2 helper for the normalize function.
@(private = "file")
_normalizeVector2 :: proc(input: Vector2) -> Vector2 {
	vectorLength := length(input)
	if vectorLength == 0 do return Vector2{0, 0}
	return input / vectorLength
}

// Vector3 helper for the normalize function.
@(private = "file")
_normalizeVector3 :: proc(input: Vector3) -> Vector3 {
	vectorLength := length(input)
	if vectorLength == 0 do return Vector3{0, 0, 0}
	return input / vectorLength
}

// Vector4 helper for the normalize function.
@(private = "file")
_normalizeVector4 :: proc(input: Vector4) -> Vector4 {
	vectorLength := length(input)
	if vectorLength == 0 do return Vector4{0, 0, 0, 0}
	return input / vectorLength
}

// Vector2 helper for the distance function.
@(private = "file")
_distanceVector2 :: proc(a, b: Vector2) -> f32 {
	return length(a - b)
}

// Vector3 helper for the distance function.
@(private = "file")
_distanceVector3 :: proc(a, b: Vector3) -> f32 {
	return length(a - b)
}

// Vector4 helper for the distance function.
@(private = "file")
_distanceVector4 :: proc(a, b: Vector4) -> f32 {
	return length(a - b)
}

// Vector2 helper for the direction function.
@(private = "file")
_directionVector2 :: proc(start, end: Vector2) -> Vector2 {
	return normalize(end - start)
}

// Vector3 helper for the direction function.
@(private = "file")
_directionVector3 :: proc(start, end: Vector3) -> Vector3 {
	return normalize(end - start)
}

// Vector4 helper for the direction function.
@(private = "file")
_directionVector4 :: proc(start, end: Vector4) -> Vector4 {
	return normalize(end - start)
}

// Scalar helper for the clamp function.
@(private = "file")
_clampScalar :: proc(input, min, max: $T) -> T {
	return math.clamp(input, min, max)
}

// Vector2 helper for the clamp function.
@(private = "file")
_clampVector2 :: proc(input: Vector2, min: Vector2, max: Vector2) -> Vector2 {
	return Vector2{math.clamp(input.x, min.x, max.x), math.clamp(input.y, min.y, max.y)}
}

// Vector3 helper for the clamp function.
@(private = "file")
_clampVector3 :: proc(input: Vector3, min: Vector3, max: Vector3) -> Vector3 {
	return Vector3 {
		math.clamp(input.x, min.x, max.x),
		math.clamp(input.y, min.y, max.y),
		math.clamp(input.z, min.z, max.z),
	}
}

// Vector4 helper for the clamp function.
@(private = "file")
_clampVector4 :: proc(input: Vector4, min: Vector4, max: Vector4) -> Vector4 {
	return Vector4 {
		math.clamp(input.x, min.x, max.x),
		math.clamp(input.y, min.y, max.y),
		math.clamp(input.z, min.z, max.z),
		math.clamp(input.w, min.w, max.w),
	}
}

// Vector2Int helper for the clamp function.
@(private = "file")
_clampVector2Int :: proc(input: Vector2Int, min: Vector2Int, max: Vector2Int) -> Vector2Int {
	return Vector2Int{math.clamp(input.x, min.x, max.x), math.clamp(input.y, min.y, max.y)}
}

// Vector3Int helper for the clamp function.
@(private = "file")
_clampVector3Int :: proc(input: Vector3Int, min: Vector3Int, max: Vector3Int) -> Vector3Int {
	return Vector3Int {
		math.clamp(input.x, min.x, max.x),
		math.clamp(input.y, min.y, max.y),
		math.clamp(input.z, min.z, max.z),
	}
}

// Vector4Int helper for the clamp function.
@(private = "file")
_clampVector4Int :: proc(input: Vector4Int, min: Vector4Int, max: Vector4Int) -> Vector4Int {
	return Vector4Int {
		math.clamp(input.x, min.x, max.x),
		math.clamp(input.y, min.y, max.y),
		math.clamp(input.z, min.z, max.z),
		math.clamp(input.w, min.w, max.w),
	}
}

// Vector2 helper for the roundToInt function.
@(private = "file")
_roundToIntVector2 :: proc(input: Vector2) -> Vector2Int {
	return Vector2Int{i32(math.round(input.x)), i32(math.round(input.y))}
}

// Vector3 helper for the roundToInt function.
@(private = "file")
_roundToIntVector3 :: proc(input: Vector3) -> Vector3Int {
	return Vector3Int{i32(math.round(input.x)), i32(math.round(input.y)), i32(math.round(input.z))}
}

// Vector4 helper for the roundToInt function.
@(private = "file")
_roundToIntVector4 :: proc(input: Vector4) -> Vector4Int {
	return Vector4Int {
		i32(math.round(input.x)),
		i32(math.round(input.y)),
		i32(math.round(input.z)),
		i32(math.round(input.w)),
	}
}

// Scalar helper for the min function.
@(private = "file")
_minScalar :: proc(inputs: ..$T) -> T {
	if len(inputs) == 0 do return 0

	result := inputs[0]
	for input in inputs[1:] {
		if input < result do result = input
	}
	return result
}

// Vector2 helper for the min function.
// This finds the minimum x and minimum y across all vectors passed in.
@(private = "file")
_minVector2 :: proc(inputs: ..Vector2) -> Vector2 {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x < result.x do result.x = input.x
		if input.y < result.y do result.y = input.y
	}
	return result
}

// Vector3 helper for the min function.
@(private = "file")
_minVector3 :: proc(inputs: ..Vector3) -> Vector3 {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x < result.x do result.x = input.x
		if input.y < result.y do result.y = input.y
		if input.z < result.z do result.z = input.z
	}
	return result
}

// Vector4 helper for the min function.
@(private = "file")
_minVector4 :: proc(inputs: ..Vector4) -> Vector4 {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x < result.x do result.x = input.x
		if input.y < result.y do result.y = input.y
		if input.z < result.z do result.z = input.z
		if input.w < result.w do result.w = input.w
	}
	return result
}

// Vector2Int helper for the min function.
// This finds the minimum x and minimum y across all vectors passed in.
@(private = "file")
_minVector2Int :: proc(inputs: ..Vector2Int) -> Vector2Int {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x < result.x do result.x = input.x
		if input.y < result.y do result.y = input.y
	}
	return result
}

// Vector3Int helper for the min function.
@(private = "file")
_minVector3Int :: proc(inputs: ..Vector3Int) -> Vector3Int {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x < result.x do result.x = input.x
		if input.y < result.y do result.y = input.y
		if input.z < result.z do result.z = input.z
	}
	return result
}

// Vector4Int helper for the min function.
@(private = "file")
_minVector4Int :: proc(inputs: ..Vector4Int) -> Vector4Int {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x < result.x do result.x = input.x
		if input.y < result.y do result.y = input.y

		if input.z < result.z do result.z = input.z
		if input.w < result.w do result.w = input.w
	}
	return result
}

// Scalar helper for the max function.
@(private = "file")
_maxScalar :: proc(inputs: ..$T) -> T {
	if len(inputs) == 0 do return 0

	result := inputs[0]
	for input in inputs[1:] {
		if input > result do result = input
	}
	return result
}

// Vector2 helper for the min function.
// This finds the minimum x and minimum y across all vectors passed in.
@(private = "file")
_maxVector2 :: proc(inputs: ..Vector2) -> Vector2 {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x > result.x do result.x = input.x
		if input.y > result.y do result.y = input.y
	}
	return result
}

// Vector3 helper for the min function.
@(private = "file")
_maxVector3 :: proc(inputs: ..Vector3) -> Vector3 {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x > result.x do result.x = input.x
		if input.y > result.y do result.y = input.y
		if input.z > result.z do result.z = input.z
	}
	return result
}

// Vector4 helper for the min function.
@(private = "file")
_maxVector4 :: proc(inputs: ..Vector4) -> Vector4 {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x > result.x do result.x = input.x
		if input.y > result.y do result.y = input.y
		if input.z > result.z do result.z = input.z
		if input.w > result.w do result.w = input.w
	}
	return result
}

// Vector2Int helper for the min function.
// This finds the minimum x and minimum y across all vectors passed in.
@(private = "file")
_maxVector2Int :: proc(inputs: ..Vector2Int) -> Vector2Int {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x > result.x do result.x = input.x
		if input.y > result.y do result.y = input.y
	}
	return result
}

// Vector3Int helper for the min function.
@(private = "file")
_maxVector3Int :: proc(inputs: ..Vector3Int) -> Vector3Int {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x > result.x do result.x = input.x
		if input.y > result.y do result.y = input.y
		if input.z > result.z do result.z = input.z
	}
	return result
}

// Vector4Int helper for the min function.
@(private = "file")
_maxVector4Int :: proc(inputs: ..Vector4Int) -> Vector4Int {
	if len(inputs) == 0 do return {}

	result := inputs[0]
	for input in inputs[1:] {
		if input.x > result.x do result.x = input.x
		if input.y > result.y do result.y = input.y
		if input.z > result.z do result.z = input.z
		if input.w > result.w do result.w = input.w
	}
	return result
}
