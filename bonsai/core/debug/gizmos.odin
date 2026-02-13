package debug

import "core:strings"

_ :: strings

import "bonsai:core/gmath"
import "bonsai:core/gmath/colors"
import "bonsai:core/render"

_ :: render

DebugSpace :: enum {
	World,
	Screen,
}

when ODIN_DEBUG {
	@(private = "file")
	_worldQueue: [dynamic]GizmoCommand

	@(private = "file")
	_screenQueue: [dynamic]GizmoCommand

	GizmoCommand :: union {
		GizmoLine,
		GizmoRectangleLines,
		GizmoRectangle,
		GizmoCircleLines,
		GizmoCircle,
		GizmoArrow,
		GizmoText,
		GizmoCross,
	}

	GizmoLine :: struct {
		start: gmath.Vector2,
		end:   gmath.Vector2,
		color: gmath.Color,
	}

	GizmoRectangleLines :: struct {
		rectangle: gmath.Rectangle,
		color:     gmath.Color,
	}

	GizmoRectangle :: struct {
		rectangle: gmath.Rectangle,
		color:     gmath.Color,
	}

	GizmoCircleLines :: struct {
		center: gmath.Vector2,
		radius: f32,
		color:  gmath.Color,
	}

	GizmoCircle :: struct {
		center: gmath.Vector2,
		radius: f32,
		color:  gmath.Color,
	}

	GizmoArrow :: struct {
		start: gmath.Vector2,
		end:   gmath.Vector2,
		color: gmath.Color,
	}

	GizmoText :: struct {
		position: gmath.Vector2,
		text:     string,
		color:    gmath.Color,
		size:     uint,
		pivot:    gmath.Pivot,
	}

	GizmoCross :: struct {
		position: gmath.Vector2,
		size:     f32,
		color:    gmath.Color,
	}
}

// @ref
// Draws a debug line between `start` and `end`.
// Only rendered in **debug** builds.
// Matches [`drawLine`](https://bonsai-framework.dev/reference/core/render/#drawline)
drawLine :: proc(start, end: gmath.Vector2, color := colors.RED, space := DebugSpace.World) {
	when ODIN_DEBUG {
		command := GizmoLine{start, end, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a debug rectangle outline.
// Only rendered in **debug** builds.
// Matches [`drawRectangleLines`](https://bonsai-framework.dev/reference/core/render/#drawrectanglelines)
drawRectangleLines :: proc(
	rectangle: gmath.Rectangle,
	color := colors.RED,
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		command := GizmoRectangleLines{rectangle, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a debug rectangle.
// Only rendered in **debug** builds.
// Matches [`drawRectangle`](https://bonsai-framework.dev/reference/core/render/#drawrectangle)
drawRectangle :: proc(
	rectangle: gmath.Rectangle,
	color := gmath.Color{1, 0, 0, 0.5},
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		command := GizmoRectangle{rectangle, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a debug circle outline.
// Only rendered in **debug** builds.
// Matches [`drawCircleLines`](https://bonsai-framework.dev/reference/core/render/#drawcirclelines)
drawCircleLines :: proc(
	center: gmath.Vector2,
	radius: f32,
	color := colors.GREEN,
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		command := GizmoCircleLines{center, radius, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a debug circle.
// Only rendered in **debug** builds.
// Matches [`drawCircle`](https://bonsai-framework.dev/reference/core/render/#drawcircle)
drawCircle :: proc(
	center: gmath.Vector2,
	radius: f32,
	color := gmath.Color{0, 1, 0, 0.5},
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		command := GizmoCircle{center, radius, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a debug arrow pointing from `start` to `end`.
// Only rendered in **debug** builds.
// Matches [`drawArrow`](https://bonsai-framework.dev/reference/core/render/#drawarrow)
drawArrow :: proc(start, end: gmath.Vector2, color := colors.BLUE, space := DebugSpace.World) {
	when ODIN_DEBUG {
		command := GizmoArrow{start, end, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws debug text at a specific `position`.
// Only rendered in **debug** builds.
drawText :: proc(
	position: gmath.Vector2,
	text: string,
	color := colors.WHITE,
	size: uint = 12,
	pivot := gmath.Pivot.bottomLeft,
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		clonedText := strings.clone(text, context.temp_allocator)
		command := GizmoText{position, clonedText, color, size, pivot}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a small cross at a specific `position` to mark a point.
// Only rendered in **debug** builds.
drawPoint :: proc(
	position: gmath.Vector2,
	size: f32 = 5.0,
	color := colors.GREEN,
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		command := GizmoCross{position, size, color}
		_pushGizmo(command, space)
	}
}

// @ref
// Draws a grid centered at (0, 0).
// Helpful for visualizing scale, alignment and spatial partitioning buckets.
drawGrid :: proc(
	cellSize: f32 = 32.0,
	lines: int = 10, // number of lines in each direction from center
	color := gmath.Color{1, 1, 1, 0.2},
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		totalSize := f32(lines) * cellSize

		for i in -lines ..= lines {
			x := f32(i) * cellSize
			start := gmath.Vector2{x, -totalSize}
			end := gmath.Vector2{x, totalSize}
			drawLine(start, end, color, space)
		}

		for i in -lines ..= lines {
			y := f32(i) * cellSize
			start := gmath.Vector2{-totalSize, y}
			end := gmath.Vector2{totalSize, y}
			drawLine(start, end, color, space)
		}
	}
}

// flushes all queued gizmos to the renderer
// called at the end of the frame internally in main.odin
flushGizmos :: proc() {
	when ODIN_DEBUG {
		if len(_worldQueue) > 0 {
			render.setWorldSpace()
			for command in _worldQueue {
				_drawGizmoCommand(command)
			}
			clear(&_worldQueue)
		}

		if len(_screenQueue) > 0 {
			render.setScreenSpace()
			for command in _screenQueue {
				_drawGizmoCommand(command)
			}
			clear(&_screenQueue)
		}
	}
}

when ODIN_DEBUG {
	@(private = "file")
	_drawGizmoCommand :: proc(command: GizmoCommand) {
		switch cmd in command {
		case GizmoLine:
			render.drawLine(cmd.start, cmd.end, cmd.color)
		case GizmoRectangleLines:
			render.drawRectangleLines(cmd.rectangle, cmd.color)
		case GizmoRectangle:
			render.drawRectangle(cmd.rectangle, color = cmd.color)
		case GizmoCircleLines:
			render.drawCircleLines(cmd.center, cmd.radius, cmd.color)
		case GizmoCircle:
			render.drawCircle(cmd.center, cmd.radius, cmd.color)
		case GizmoArrow:
			render.drawArrow(cmd.start, cmd.end, cmd.color)
		case GizmoText:
			render.drawText(
				cmd.position,
				cmd.text,
				color = cmd.color,
				fontSize = cmd.size,
				pivot = cmd.pivot,
			)
		case GizmoCross:
			render.drawLine(cmd.position - cmd.size, cmd.position + cmd.size, cmd.color)
			render.drawLine(
				{cmd.position.x - cmd.size, cmd.position.y + cmd.size},
				{cmd.position.x + cmd.size, cmd.position.y - cmd.size},
				cmd.color,
			)
		}
	}

	@(private = "file")
	_pushGizmo :: proc(command: GizmoCommand, space: DebugSpace) {
		switch space {
		case .World:
			if _worldQueue == nil {
				_worldQueue = make([dynamic]GizmoCommand)
			}
			append(&_worldQueue, command)
		case .Screen:
			if _screenQueue == nil {
				_screenQueue = make([dynamic]GizmoCommand)
			}
			append(&_screenQueue, command)
		}
	}
}
