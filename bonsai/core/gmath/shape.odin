package gmath

import "base:intrinsics"

// @ref
// A `Circle` defined by a **center** `position` and a `radius`.
Circle :: struct {
	position: Vector2,
	radius:   f32,
}

// @ref
// An Axis-Aligned Bounding Box (AABB) stored as a [`Vector4`](#vector4).
// **Format:** `{ minX, minY, maxX, maxY }`
// This corresponds to **(Left, Bottom, Right, Top)**.
Rectangle :: Vector4

// @ref
// Checks if two Axis-Aligned Bounding Boxes (AABB) intersect.
// Returns `true` if they overlap.
rectangleIntersects :: proc(a: Rectangle, b: Rectangle) -> bool {
	return a.x <= b.z && a.z >= b.x && a.y <= b.w && a.w >= b.y
}

// @ref
// Checks if a `point` lies inside the [`Rectangle`](#rectangle).
// Returns `true` if it does.
rectangleContains :: proc(rectangle: Rectangle, point: Vector2) -> bool {
	return(
		(point.x >= rectangle.x) &&
		(point.x <= rectangle.z) &&
		(point.y >= rectangle.y) &&
		(point.y <= rectangle.w) \
	)
}

// @ref
// Returns the **center point** of the [`Rectangle`](#rectangle).
getRectangleCenter :: proc(rectangle: Rectangle) -> Vector2 {
	minPoint := rectangle.xy
	maxPoint := rectangle.zw
	return {
		minPoint.x + 0.5 * (maxPoint.x - minPoint.x),
		minPoint.y + 0.5 * (maxPoint.y - minPoint.y),
	}
}

// @ref
// Returns the **width** and **height** of the [`Rectangle`](#rectangle) as a [`Vector2`](#vector2).
getRectangleSize :: proc(rectangle: Rectangle) -> Vector2 {
	return {rectangle.z - rectangle.x, rectangle.w - rectangle.y}
}


// @ref
// Overload group for creating a [`Rectangle`](#rectangle).
// Accepts arguments:
// - `position` as [`Vector2`](#vector2) (optional, default: `gmath.Vector2{0, 0}`).
// - `size` as [`Vector2`](#vector2).
// - `pivot` as [`Pivot`](#pivot) (optional, default: `gmath.Pivot.bottomLeft`).
rectangleMake :: proc {
	_rectangleFromPositionSize,
	_rectangleFromSize,
}


// @ref
// Scales a [`Rectangle`](#rectangle) around its own center point.
//
// Accepts a scalar or [`Vector2`](#vector2) as a `scale`.
rectangleScale :: proc {
	_rectangleScaleScalar,
	_rectangleScaleVector2,
}

// @ref
// Expands the [`Rectangle`](#rectangle) boundaries outwards by `amount` on all sides.
// A negative amount **shrinks** the [`Rectangle`](#rectangle).
//
// Accepts a scalar or [`Vector2`](#vector2) as an `amount` by which the rectangle is expanded.
//
// **Example:**
// ```Odin
// rectangle := gmath.rectangleMake(gmath.Vector2{10, 10}) // size is gmath.Vector2{10, 10}
// rectangle = gmath.rectangleExpand(rectangle, gmath.Vector2{5, 5}) // size is gmath.Vector2{20, 20}
// ```
rectangleExpand :: proc {
	_rectangleExpandScalar,
	_rectangleExpandVector2,
}


// @ref
// Moves [`Circle`](#circle) or [`Rectangle`](#rectangle) by the `delta` vector.
//
// **Example:**
// ```Odin
// rectangle := gmath.rectangleMake(gmath.Vector2{5, 5}, gmath.Vector2{10, 10}) // position is gmath.Vector2{5, 5}
// rectangle = gmath.shift(rectangle, gmath.Vector2{10, 10}) // position is gmath.Vector2{15, 15}
// ```
shift :: proc {
	_circleShift,
	_rectangleShift,
}

// Position/Size helper for rectangleMake function
@(private = "file")
_rectangleFromPositionSize :: proc(
	position: Vector2,
	size: Vector2,
	pivot := Pivot.bottomLeft,
) -> Rectangle {
	baseRectangle := Vector4{0, 0, size.x, size.y}

	pivotOffset := scaleFromPivot(pivot) * size
	finalPosition := position - pivotOffset

	return shift(baseRectangle, finalPosition)
}

// Size helper for rectangleMake function
@(private = "file")
_rectangleFromSize :: proc(size: Vector2, pivot: Pivot) -> Rectangle {
	return _rectangleFromPositionSize({}, size, pivot)
}

// Rectangle helper for shift function
@(private = "file")
_rectangleShift :: proc(rectangle: Rectangle, delta: Vector2) -> Rectangle {
	return Rectangle {
		rectangle.x + delta.x,
		rectangle.y + delta.y,
		rectangle.z + delta.x,
		rectangle.w + delta.y,
	}
}

// Circle helper for shift function
@(private = "file")
_circleShift :: proc(circle: Circle, delta: Vector2) -> Circle {
	return Circle{position = circle.position + delta, radius = circle.radius}
}

// Scalar helper for rectangleScale function
@(private = "file")
_rectangleScaleScalar :: proc(rectangle: Rectangle, scale: $T) -> Rectangle {
	center := getRectangleCenter(rectangle)
	size := getRectangleSize(rectangle)

	newSize := size * scale
	halfSize := newSize * 0.5

	return Rectangle {
		center.x - halfSize.x,
		center.y - halfSize.y,
		center.x + halfSize.x,
		center.y + halfSize.y,
	}
}

// Vector2 helper for rectangleScale function
@(private = "file")
_rectangleScaleVector2 :: proc(rectangle: Rectangle, scale: Vector2) -> Rectangle {
	center := getRectangleCenter(rectangle)
	size := getRectangleSize(rectangle)

	newSize := size * scale
	halfSize := newSize * 0.5

	return Rectangle {
		center.x - halfSize.x,
		center.y - halfSize.y,
		center.x + halfSize.x,
		center.y + halfSize.y,
	}
}


@(private = "file")
_rectangleExpandScalar :: proc(
	rectangle: Rectangle,
	amount: $T,
) -> Rectangle where intrinsics.type_is_float(T) {
	return Rectangle {
		rectangle.x - amount,
		rectangle.y - amount,
		rectangle.z + amount,
		rectangle.w + amount,
	}
}

@(private = "file")
_rectangleExpandVector2 :: proc(rectangle: Rectangle, amount: Vector2) -> Rectangle {
	return Rectangle {
		rectangle.x - amount.x,
		rectangle.y - amount.y,
		rectangle.z + amount.x,
		rectangle.w + amount.y,
	}
}
