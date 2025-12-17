package entityData

import "../../core/render"
import "../../systems/entities"
import "../../systems/entities/type"
import "../../types/game"
import "../../types/gmath"

spawnThing :: proc() -> ^type.Entity {
	e := entities.create(type.EntityName.thing)

	e.drawOffset = gmath.Vec2{0.5, 5}
	e.drawPivot = gmath.Pivot.bottomCenter

	e.updateProc = proc(e: ^type.Entity) {
		entities.setAnimation(e, game.SpriteName.player_idle, 0.3)
	}

	e.drawProc = proc(e: ^type.Entity) {
		render.drawSprite(e.pos, .shadow_medium, col = {1, 1, 1, 0.2}, zLayer = game.ZLayer.shadow)
		entities.drawEntityDefault(e)
	}

	return e
}
