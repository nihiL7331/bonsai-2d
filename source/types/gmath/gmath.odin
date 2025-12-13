package gmath

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

Shape :: union {
	Rect,
	Circle,
}

Circle :: struct {
	pos:    Vec2,
	radius: f32,
}

Rect :: Vec4
