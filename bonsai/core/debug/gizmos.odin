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
		GizmoRectangle,
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

	GizmoRectangle :: struct {
		rectangle: gmath.Rectangle,
		color:     gmath.Color,
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
	}

	GizmoCross :: struct {
		position: gmath.Vector2,
		size:     f32,
		color:    gmath.Color,
	}
}

drawLine :: proc(start, end: gmath.Vector2, color := colors.RED, space := DebugSpace.World) {
	when ODIN_DEBUG {
		command := GizmoLine{start, end, color}
		_pushGizmo(command, space)
	}
}

drawRectangle :: proc(rectangle: gmath.Rectangle, color := colors.RED, space := DebugSpace.World) {
	when ODIN_DEBUG {
		command := GizmoRectangle{rectangle, color}
		_pushGizmo(command, space)
	}
}

drawCircle :: proc(
	center: gmath.Vector2,
	radius: f32,
	color := colors.GREEN,
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		command := GizmoCircle{center, radius, color}
		_pushGizmo(command, space)
	}
}

drawArrow :: proc(start, end: gmath.Vector2, color := colors.BLUE, space := DebugSpace.World) {
	when ODIN_DEBUG {
		command := GizmoArrow{start, end, color}
		_pushGizmo(command, space)
	}
}

drawText :: proc(
	position: gmath.Vector2,
	text: string,
	color := colors.WHITE,
	space := DebugSpace.World,
) {
	when ODIN_DEBUG {
		clonedText := strings.clone(text, context.temp_allocator)
		command := GizmoText{position, clonedText, color}
		_pushGizmo(command, space)
	}
}

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
		case GizmoRectangle:
			render.drawRectangleLines(cmd.rectangle, cmd.color)
		case GizmoCircle:
			render.drawCircleLines(cmd.center, cmd.radius, cmd.color)
		case GizmoArrow:
			render.drawArrow(cmd.start, cmd.end, cmd.color)
		case GizmoText:
			render.drawText(cmd.position, cmd.text, color = cmd.color)
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
