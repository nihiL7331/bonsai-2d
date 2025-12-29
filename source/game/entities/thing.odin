package entityData

import "../../core/render"
import "../../systems/entities"
import "../../systems/entities/type"
import "../../types/game"
import "../../types/gmath"

// generic boilerplate used to create entities using my entity system

spawnThing :: proc() -> ^type.Entity {
	entity := entities.create(type.EntityName.Thing)

	entity.drawOffset = gmath.Vec2{0.5, 5}
	entity.drawPivot = gmath.Pivot.bottomCenter

	entity.updateProc = proc(entity: ^type.Entity) {
		entities.setAnimation(entity, game.SpriteName.player_idle, 0.3)
	}

	entity.drawProc = proc(entity: ^type.Entity) {
		render.drawSprite(
			entity.pos,
			.shadow_medium,
			col = {1, 1, 1, 0.2},
			zLayer = game.ZLayer.shadow,
		)
		entities.drawEntityDefault(entity)
	}

	return entity
}
