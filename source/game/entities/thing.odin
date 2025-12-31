package entityData

import "bonsai:core/render"
import "bonsai:systems/entities"
import "bonsai:types/game"
import "bonsai:types/gmath"

// generic boilerplate used to create entities using my entity system

spawnThing :: proc(data: entities.EntityData) -> ^entities.Entity {
	entity := entities.create(entities.EntityName.Thing)
	entity.position = data.position

	entity.drawOffset = gmath.Vec2{0.5, 5}
	entity.drawPivot = gmath.Pivot.bottomCenter

	entity.updateProc = proc(entity: ^entities.Entity) {
		entities.setAnimation(entity, game.SpriteName.player_idle, 0.3)
	}

	entity.drawProc = proc(entity: ^entities.Entity) {
		render.drawSprite(
			entity.position,
			.shadow_medium,
			col = {1, 1, 1, 0.2},
			zLayer = game.ZLayer.shadow,
		)
		entities.drawEntityDefault(entity)
	}

	return entity
}
