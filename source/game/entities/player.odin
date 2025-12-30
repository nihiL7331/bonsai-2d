package entityData

import "../../core"
import "../../core/input"
import "../../core/render"
import "../../systems/entities"
import "../../systems/entities/type"
import "../../types/game"
import "../../types/gmath"

spawnPlayer :: proc(data: type.EntityData) -> ^type.Entity {
	entity := entities.create(type.EntityName.Player)
	entities.setPlayerHandle(entity.handle)
	entity.position = data.position

	entity.drawOffset = gmath.Vec2{0.5, 5} // this kinda just has to be hardcoded
	entity.drawPivot = gmath.Pivot.bottomCenter // recommended for y sort

	entity.updateProc = proc(entity: ^type.Entity) {
		coreContext := core.getCoreContext()

		inputDir := input.getInputVector()
		entity.position += inputDir * 100.0 * coreContext.deltaTime

		if inputDir.x != 0 {
			entity.lastKnownXDir = inputDir.x
		}

		entity.flipX = entity.lastKnownXDir < 0

		if inputDir == {} {
			entities.setAnimation(entity, game.SpriteName.player_idle, 0.3)
		} else {
			entities.setAnimation(entity, game.SpriteName.player_run, 0.1)
		}
	}

	entity.drawProc = proc(entity: ^type.Entity) {
		render.drawSprite(
			entity.position,
			game.SpriteName.shadow_medium,
			col = {1, 1, 1, 0.2},
			zLayer = game.ZLayer.shadow,
		)
		entities.drawEntityDefault(entity)
	}

	return entity
}
