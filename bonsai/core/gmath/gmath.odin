package gmath

// @overview
// This package contains all of the most important math functions used for game development purposes.
// It provides a comprehensive library of mathematical primitives and utilities.
// Contains linear algebra, geometry and random number generation.
//
// **Features:**
// - **Linear algebra:** Robust support for vectors ([`Vector2/Int`](#vector2) -> [`Vector4/Int`](#vector4)) and matrices ([`Matrix4`](#matrix4))
//   including the most important operations like [`dot`](#dot), [`normalize`](#normalize), [`direction`](#direction).
// - **Geometry:** Contains tools for manipulating shapes, including [`Rectangle`](#rectangle) and [`Circle`](#circle). Allows to position,
//   scale, pivot, and check collision between shapes.
// - **Randomness:** Utilities for generating random numbers ([`randomRange`](#randomrange)), normalized floats ([`randomFloatNormalized`](#randomfloatnormalized))
//   and picking random array elements via [`randomElement`](#randomelement).
// - **Math utilities:** Essential game math functions including [`lerp`](#lerp), [`ease`](#ease), [`remap`](#remap) and [`clamp`](#clamp).
// - **Color handling:** Helpers to convert hex strings or values into [`Color`](#color) structs ([`hexToColor`](#hextocolor)). Contains generic
//   color constants in `bonsai:core/gmath/colors`.
//
// :::note[Usage]
// ```Odin
// update :: proc() {
//   direction := gmath.direction(enemy.position, pot.position)
//   enemy.position += direction * enemy.speed * deltaTime
//
//   if gmath.rectangleIntersects(pot.collider, enemy.collider) {
//     potDead()
//   }
//
//   spawnPosition := gmath.randomCircleNormalized() * spawnRange
//   // ...
// }
// ```
// :::

import "base:intrinsics"
import "core:math"
import "core:math/linalg"

// @ref
// 2D Integer Vector (32-bit).
// :::tip
// Useful for grid coordinates.
// :::
Vector2Int :: [2]i32

// @ref
// 3D Integer Vector (32-bit).
Vector3Int :: [3]i32

// @ref
// 4D Integer Vector (32-bit).
Vector4Int :: [4]i32

// @ref
// Standard 2D Float Vector (compatible with Odin's `core:math/linalg` package)
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
// Constant e value. Approximately 2.718281828.
E :: math.E

// @ref
// Enum representing the 9 cardinal points of a rectangle.
// :::note
// Used for anchoring UI and aligning sprites.
// :::
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
// Returns a normalized [`Vector2`](#vector2) (0.0 -> +1.0) corresponding to the [`Pivot`](#pivot) enum.
//
// :::note[Example]
// ```Odin
// // pivotOffset is equal to gmath.Vector2{0.5, 0.5}
// pivotOffset := gmath.scaleFromPivot(gmath.Pivot.centerCenter)
// ```
// :::
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
// Returns the dot product between two vectors.
//
// :::note[Example]
// ```Odin
// directionA := gmath.Vector2{1, 1}
// directionB := gmath.Vector2{-1, 1}
// product := gmath.dot(directionA, directionB)
// ```
// :::
dot :: proc(a, b: [$N]$T) -> T where intrinsics.type_is_float(T) || intrinsics.type_is_integer(T) {
	result: T = 0
	for i in 0 ..< N {
		result += a[i] * b[i]
	}
	return result
}

// @ref
// Returns the length (**magnitude**) of the vector `input`.
//
// :::note[Example]
// ```Odin
// point := gmath.Vector2{2, 2}
// pointLength := gmath.length(point) // Returns distance from {0, 0} = 4√2
// ```
// :::
length :: proc(
	input: [$N]$T,
) -> T where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return sqrt(lengthSquared(input))
}

// @ref
// Returns the squared length of the vector `input`.
// **Faster** than [`length`](#length) because it doesn't use the square root operation.
//
// :::tip
// Useful for distance comparisons.
// :::
//
// :::note[Example]
// ```Odin
// pointA := gmath.Vector2{100, 100}
// pointB := gmath.Vector2{5, 5}
// result := gmath.lengthSquared(pointA) > gmath.lengthSquared(pointB) // result is true
// ```
// :::
lengthSquared :: proc(
	input: [$N]$T,
) -> T where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return dot(input, input)
}

// @ref
// Returns the normalized direction of the vector `input` (with length of 1).
//
// Returns `{0, 0}` if the `input` vector is zero to prevent `nil` errors.
//
// :::note[Example]
// ```Odin
// direction := gmath.Vector2{100, 0}
// directionNormalized := gmath.normalize(direction) // directionNormalized is gmath.Vector2{1, 0}
// ```
// :::
normalize :: proc(input: $T) -> T where intrinsics.type_is_array(T) {
	vectorLength := length(input)
	if vectorLength == 0 do return T{}
	return input / vectorLength
}

// @ref
// Returns the distance between points `a` and `b`.
//
// :::note[Example]
// ```Odin
// pointA := gmath.Vector2{3, 0}
// pointB := gmath.Vector2{3, 4}
// dist := gmath.distance(pointA, pointB) // dist is 4
// ```
// :::
distance :: proc(
	a, b: [$N]$T,
) -> T where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return length(a - b)
}

// @ref
// Returns a normalized direction vector pointing from `start` to `end`.
//
// :::note[Example]
// ```Odin
// start := gmath.Vector2{4, 0}
// end := gmath.Vector2{4, -9}
// dir := gmath.direction(start, end) // dir is gmath.Vector2{0, -1}
// ```
// :::
direction :: proc(start, end: $T) -> T where intrinsics.type_is_array(T) {
	return normalize(end - start)
}

// @ref
// Creates a translation matrix from a 2D position (Z is assumed to be 0).
matrixTranslate :: proc(position: Vector2) -> Matrix4 {
	return linalg.matrix4_translate(Vector3{position.x, position.y, 0})
}

// @ref
// Creates a rotation matrix from a `rotation` [`Vector3`](#vector3).
//
// :::note
// This function applies the multiplication in the following order:
//
// X (pitch) -> Y (yaw) -> Z (roll).
// :::
matrixRotate :: proc(rotation: Vector3) -> Matrix4 {
	rotatedMatrixX := matrixRotateX(rotation.x)
	rotatedMatrixY := matrixRotateY(rotation.y)
	rotatedMatrixZ := matrixRotateZ(rotation.z)

	return rotatedMatrixZ * rotatedMatrixY * rotatedMatrixX
}

// @ref
// Creates a rotation matrix (X-axis) from an angle **in radians**.
matrixRotateX :: proc(radians: f32) -> Matrix4 {
	return linalg.matrix4_rotate(radians, Vector3{1, 0, 0})
}

// @ref
// Creates a rotation matrix (Y-axis) from an angle **in radians**.
matrixRotateY :: proc(radians: f32) -> Matrix4 {
	return linalg.matrix4_rotate(radians, Vector3{0, 1, 0})
}

// @ref
// Creates a rotation matrix (Z-axis) from an angle **in radians**.
matrixRotateZ :: proc(radians: f32) -> Matrix4 {
	return linalg.matrix4_rotate(radians, Vector3{0, 0, 1})
}

// @ref
// Multiplies a vector by a matrix, effectively transforming the point.
// Assumes z = 0 and w = 1.
transformPoint :: proc(mat: Matrix4, point: Vector2) -> Vector2 {
	res := mat * Vector4{point.x, point.y, 0, 1}
	return res.xy
}

// @ref
// Returns the inverse of the 4x4 matrix.
// Useful for creating view matrices and converting world space to screen space.
// :::note
// Matrix inversion is computationally expensive.
// :::
matrixInverse :: proc(mat: Matrix4) -> Matrix4 {
	return linalg.matrix4_inverse(mat)
}

// @ref
// Creates an orthographic projection matrix.
// This defines the viewing volume as a rectangular box.
// Objects inside this box are visible, objects outside are clipped.
matrixOrtho3d :: proc(
	left, right, bottom, top, near, far: $T,
) -> Matrix4 where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_float(T) {
		return Matrix4(linalg.matrix_ortho3d(left, right, bottom, top, near, far))
	} else {
		return Matrix4(
			linalg.matrix_ortho3d_f32(
				f32(left),
				f32(right),
				f32(bottom),
				f32(top),
				f32(near),
				f32(far),
			),
		)
	}
}

// @ref
// Creates a scaling matrix. Z-scale is locked to 1.0.
matrixScale :: proc(scale: Vector2) -> Matrix4 {
	return linalg.matrix4_scale(Vector3{scale.x, scale.y, 1})
}

// @ref
// Checks if two floats are equal within a small margin of error (`epsilon`).
almostEquals :: proc(
	a, b: $T,
	epsilon: $E,
) -> bool where (intrinsics.type_is_float(T) || intrinsics.type_is_integer(T)) &&
	intrinsics.type_is_float(E) {
	return abs(a - b) <= epsilon
}

// @ref
// Converts degrees to radians.
toRadians :: proc(
	degrees: $T,
) -> T where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return degrees * (PI / 180.0)
}

// @ref
// Converts radians to degrees.
toDegrees :: proc(
	radians: $T,
) -> T where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return radians * (180.0 / PI)
}

// @ref
// Clamps `input` between `minimum` and `maximum`.
clamp :: proc(
	input: $T,
	minimum, maximum: $E,
) -> T where (intrinsics.type_is_array(T) &&
		(intrinsics.type_is_array(E) ||
				intrinsics.type_is_float(E) ||
				intrinsics.type_is_integer(E))) ||
	((intrinsics.type_is_float(T) || intrinsics.type_is_integer(T)) &&
			(intrinsics.type_is_float(E) || intrinsics.type_is_integer(E))) {
	when intrinsics.type_is_array(T) {
		result: T
		when intrinsics.type_is_array(E) { 	// vector-vector clamp
			#assert(len(input) == len(minimum), "Dimension mismatch in clamp(input, min, max)")
			for i in 0 ..< len(input) {
				result[i] = clamp(input[i], minimum[i], maximum[i])
			}
		} else { 	// vector-scalar clamp
			for i in 0 ..< len(input) {
				result[i] = clamp(input[i], minimum, maximum)
			}
		}
		return result
	} else {
		return math.clamp(input, T(minimum), T(maximum))
	}
}

// @ref
// Rounds the float `input` vector to the nearest integer **vector**, changing its type.
//
// :::note[Example]
// ```Odin
// value := gmath.Vector3{5.1, 7.6, 6.9}
// roundedValue := gmath.roundToInt(value) // roundedValue is gmath.Vector3Int{5, 8, 7}
// ```
// :::
roundToInt :: proc(input: [$N]$T) -> [N]int where intrinsics.type_is_float(T) {
	result: [N]int
	for i in 0 ..< N {
		result[i] = int(math.round(input[i]))
	}
	return result
}

// @ref
// Rounds the value to the nearest whole number.
// Accepts scalar and vector values as an argument.
round :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = round(input[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.round(input)
	} else {
		return input
	}
}

// @ref
// Returns the largest whole number less than or equal to the `input`.
// Accepts scalar and vector values as an argument.
floor :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = floor(input[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.floor(input)
	} else {
		return input
	}
}

// @ref
// Returns the smallest whole number greater than or equal to the `input`.
// Accepts scalar and vector values as an argument.
ceil :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = ceil(input[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.ceil(input)
	} else {
		return input
	}
}

// @ref
// Linearly interpolates between `a` and `b` by the fraction `t`.
// Useful for smooth transitions, animations, or mixing colors.
// Accepts scalar arguments, as well as [`Vector2`](#vector2), [`Vector3`](#vector3), [`Vector4`](#vector4) and [`Color`](#color).
//
// :::note
// The value of `t` is **not clamped** to the 0-1 range.
// :::
//
// :::note[Example]
// ```Odin
// start := gmath.Vector2{4, 4}
// finish := gmath.Vector2{16, 16}
// result := gmath.lerp(start, finish, 0.5) // result is gmath.Vector2{10, 10}
// ```
// :::
lerp :: proc(a, b: $T, t: $E) -> T {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(a) {
			result[i] = lerp(a[i], b[i], t)
		}
		return result
	} else {
		return math.lerp(a, b, T(t))
	}
}

// @ref
// Returns the value of `base` raised to `power`.
// Accepts scalars, [`Vectors`](#vector2), and [`Color`](#color) as an argument.
pow :: proc(
	base: $B,
	power: $P,
) -> B where (intrinsics.type_is_array(B) &&
		(intrinsics.type_is_array(P) ||
				intrinsics.type_is_float(P) ||
				intrinsics.type_is_integer(P))) ||
	((intrinsics.type_is_float(B) || intrinsics.type_is_integer(B)) &&
				intrinsics.type_is_float(P) ||
			intrinsics.type_is_integer(P)) {
	when intrinsics.type_is_array(B) {
		result := base

		when intrinsics.type_is_array(P) { 	// vector^vector
			#assert(len(base) == len(power), "Dimension mismatch in pow(vector, vector)")
			for i in 0 ..< len(base) {
				result[i] = pow(base[i], power[i])
			}
		} else { 	// vector^scalar
			for i in 0 ..< len(base) {
				result[i] = pow(base[i], power)
			}
		}
		return result
	} else { 	// scalar^scalar
		when intrinsics.type_is_float(B) {
			return math.pow(base, B(power))
		} else {
			return B(math.round(math.pow_f64(f64(base), f64(power))))
		}
	}
}

// @ref
// Remaps `input` from the `[inMin, inMax]` range to the `[outMin, outMax]` range.
//
// :::note[Example]
// ```Odin
// remapped := gmath.remap(50.0, 0.0, 100.0, 0.0, 1.0) // remapped is 0.5
// ```
// :::
remap :: proc(
	input, inMin, inMax, outMin, outMax: $T,
) -> T where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return outMin + (input - inMin) * (outMax - outMin) / (inMax - inMin)
}

// @ref
// Returns [`e`](#e) raised to the power of `input`.
exp :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = exp(input[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.exp(input)
	} else {
		return T(math.round(math.exp_f64(f64(input))))
	}
}

// @ref
// **Returns**:
// - +1, if `input` is greater than zero.
// - 0, if `input` is equal to zero.
// - -1, if `input` is smaller than zero.
// **For vectors** returns a component-wise sign vector.
sign :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = sign(input[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.sign(input)
	} else {
		return T(math.sign(f64(input)))
	}
}

// @ref
// Returns the square root of `input` value.
// Works with [`Vectors`](#vector2), [`Matrices`](#matrix4) and scalars.
// If an integer is passed as an argument, it's rounded on return.
sqrt :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = sqrt(input[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.sqrt(input)
	} else {
		return T(math.round(math.sqrt(f64(input))))
	}
}

// @ref
// Returns the smallest value among all arguments.
// If arguments are vectors, returns a component-wise minimum vector.
// Accepts any number of arguments (minimum 2).
//
// :::note[Example]
// ```Odin
// minimum := gmath.min(10, 5, 20) // minimum is 5
// vectorMinimum := gmath.min(vectorA, vectorB) // vectorMinimum is a component-wise minimum vector
// ```
// :::
min :: proc(
	a, b: $T,
	rest: ..T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result := a
		for i in 0 ..< len(result) {
			if b[i] < result[i] {
				result[i] = b[i]
			}
		}
		for i in 0 ..< len(rest) {
			for j in 0 ..< len(result) {
				if rest[i][j] < result[j] {
					result[j] = rest[i][j]
				}
			}
		}
		return result
	} else {
		result := a < b ? a : b
		for input in rest {
			if input < result do result = input
		}
		return result
	}
}

// @ref
// Returns the largest value among all arguments.
// If arguments are vectors, returns a component-wise maximum vector.
// Accepts any number of arguments (minimum 2).
//
// :::note[Example]
// ```Odin
// maximum := gmath.max(10, 30, 20) // maximum is 30
// vectorMaximum := gmath.max(vectorA, vectorB) // vectorMaximum is a component-wise maximum vector
// ```
// :::
max :: proc(
	a, b: $T,
	rest: ..T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result := a
		for i in 0 ..< len(result) {
			if b[i] > result[i] {
				result[i] = b[i]
			}
		}
		for i in 0 ..< len(rest) {
			for j in 0 ..< len(result) {
				if rest[i][j] > result[j] {
					result[j] = rest[i][j]
				}
			}
		}
		return result
	} else {
		result := a > b ? a : b
		for input in rest {
			if input > result do result = input
		}
		return result
	}
}

// @ref
// Returns the absolute value of `input`.
// - For **scalars**: Returns the non-negative value.
// - For **vectors**: Returns a new vector where every component is positive.
//
// :::note[Example]
// ```Odin
// direction := gmath.Vector2{-1, -1}
// result := gmath.abs(direction) // result is gmath.Vector2{1, 1}
// ```
// :::
abs :: proc(
	input: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(input) {
			result[i] = abs(input[i])
		}
		return result
	} else {
		return math.abs(input)
	}
}

// @ref
// Retuns the sine of `angle` **(in radians)**.
// - For **scalars**: Standard trigonometric sin function.
// - For **vectors**: Component-wise sine.
//
// :::note[Example]
// ```Odin
// wave := gmath.Vector2{ -gmath.PI / 2, gmath.PI / 2 }
// result := gmath.sin(wave) // result is gmath.Vector2{ -1, 1 }
// ```
// :::
sin :: proc(
	angle: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(angle) {
			result[i] = sin(angle[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.sin(angle)
	} else {
		return T(math.round(f64(math.sin_f64(f64(angle)))))
	}
}

// @ref
// Returns the cosine of `angle` **(in radians)**.
// - For **scalars**: Standard trigonometric cos function.
// - For **vectors**: Component-wise cosine.
//
// :::note[Example]
// ```Odin
// wave := gmath.Vector2{ 0, gmath.PI / 2 }
// result := gmath.cos(wave) // result is gmath.Vector2{ 1, 0 }
// ```
// :::
cos :: proc(
	angle: $T,
) -> T where intrinsics.type_is_array(T) ||
	intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	when intrinsics.type_is_array(T) {
		result: T
		for i in 0 ..< len(angle) {
			result[i] = cos(angle[i])
		}
		return result
	} else when intrinsics.type_is_float(T) {
		return math.cos(angle)
	} else {
		return T(math.round(f64(math.cos_f64(f64(angle)))))
	}
}

// @ref
// Returns the angle in radians between the x-axis and the ray from `{0,0}` to `{y,x}`.
// :::tip
// **Crucial for rotation**: To make an object at `position` look at `target`, use:
//
// `angle := gmath.atan2(target.y - position.y, target.x - position.x)`
// :::
atan2 :: proc(y, x: $T) -> T where intrinsics.type_is_float(T) || intrinsics.type_is_integer(T) {
	when intrinsics.type_is_float(T) {
		return math.atan2(y, x)
	} else {
		return T(math.round(math.atan2_f64(f64(y), f64(x))))
	}
}

// @ref
// An alias for the [`atan2`](#atan2) function.
vectorToAngle :: atan2

// @ref
// Returns a normalized direction vector from an angle **(in radians)**.
angleToVector :: proc(
	radians: $T,
) -> Vector2 where intrinsics.type_is_float(T) ||
	intrinsics.type_is_integer(T) {
	return Vector2{f32(cos(radians)), f32(sin(radians))}
}
