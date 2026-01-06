package gmath

// @ref
// Generic union for any **supported** geometric shape.
Shape :: union {
	Rectangle,
	Circle,
}

// @ref
// A circle defined by a **center position** and a **radius**.
Circle :: struct {
	position: Vector2,
	radius:   f32,
}

// @ref
// An Axis-Aligned Bounding Box (AABB) stored as a 4D vector.
// **Format: { minX, minY, maxX, maxY }**
// This corresponds to **(Left, Bottom, Right, Top)**.
Rectangle :: Vector4

// @ref
// Checks if two Axis-Aligned Bounding Boxes (AABB) intersect.
// Returns **true** if they overlap.
rectangleIntersects :: proc(a: Rectangle, b: Rectangle) -> bool {
	return a.x <= b.z && a.z >= b.x && a.y <= b.w && a.w >= b.y
}

// @ref
// Checks if a point lies inside the rectangle.
// Returns **true** if it does.
rectangleContains :: proc(rectangle: Rectangle, point: Vector2) -> bool {
	return(
		(point.x >= rectangle.x) &&
		(point.x <= rectangle.z) &&
		(point.y >= rectangle.y) &&
		(point.y <= rectangle.w) \
	)
}

// @ref
// Returns the **center point** of the rectangle.
getRectangleCenter :: proc(rectangle: Rectangle) -> Vector2 {
	minPoint := rectangle.xy
	maxPoint := rectangle.zw
	return {
		minPoint.x + 0.5 * (maxPoint.x - minPoint.x),
		minPoint.y + 0.5 * (maxPoint.y - minPoint.y),
	}
}

// @ref
// Returns the **width** and **height** of the rectangle.
getRectangleSize :: proc(rectangle: Rectangle) -> Vector2 {
	return {rectangle.z - rectangle.x, rectangle.w - rectangle.y}
}

// @ref
// Creates a rectangle from a specific anchor position (pivot) and total size.
//
// **Example:**
// ```Odin
// // creates a box centered at gmath.Vector2{10, 10} of size gmath.Vector2{100, 100}
// gmath.rectangleFromPositionSize(gmath.Vector2{10, 10}, gmath.Vector2{100, 100}, gmath.Pivot.centerCenter)
// ```
rectangleFromPositionSize :: proc(
	position: Vector2,
	size: Vector2,
	pivot := Pivot.bottomLeft,
) -> Rectangle {
	baseRectangle := Vector4{0, 0, size.x, size.y}

	pivotOffset := scaleFromPivot(pivot) * size
	finalPosition := position - pivotOffset

	return rectangleShift(baseRectangle, finalPosition)
}

// @ref
// Creates a rectangle at **(0,0)** with the given **size**, adjusted by **Pivot**.
rectangleFromSize :: proc(size: Vector2, pivot: Pivot) -> Rectangle {
	return rectangleFromPositionSize({}, size, pivot)
}

// @ref
// Overload group for creating rectangles.
rectangleMake :: proc {
	rectangleFromPositionSize,
	rectangleFromSize,
}

// @ref
// Moves a rectangle by the specific **delta** vector.
rectangleShift :: proc(rectangle: Rectangle, delta: Vector2) -> Rectangle {
	return {
		rectangle.x + delta.x,
		rectangle.y + delta.y,
		rectangle.z + delta.x,
		rectangle.w + delta.y,
	}
}

// @ref
// Scales a rectangle around its own center point by a uniform factor.
rectangleScale :: proc(rectangle: Rectangle, scale: f32) -> Rectangle {
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

// @ref
// Scales a rectangle around its own center point by separate **X/Y** factors.
rectangleScaleVector2 :: proc(rectangle: Rectangle, scale: Vector2) -> Rectangle {
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

// @ref
// Expands the rectangle boundaries outwards by **amount** on all sides.
// A negative amount **shrinks** the rectangle.
rectangleExpand :: proc(rectangle: Rectangle, amount: f32) -> Rectangle {
	return Rectangle {
		rectangle.x - amount,
		rectangle.y - amount,
		rectangle.z + amount,
		rectangle.w + amount,
	}
}

// @ref
// Moves a circle by the specified **delta** vector.
circleShift :: proc(circle: Circle, delta: Vector2) -> Circle {
	return Circle{position = circle.position + delta, radius = circle.radius}
}

// @ref
// Polymorphic shift for the **Shape** union.
// Moves any supported shape type by the **delta** vector.
shift :: proc(shape: Shape, delta: Vector2) -> Shape {
	if delta == {} {
		return shape
	}

	switch s in shape {
	case Rectangle:
		return rectangleShift(s, delta)
	case Circle:
		return circleShift(s, delta)
	}
	return shape
}
