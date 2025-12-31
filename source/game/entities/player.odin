package entityData

import "bonsai:core/input"
import "bonsai:core/render"
import "bonsai:systems/entities"
import "bonsai:systems/physics"
import "bonsai:types/game"
import "bonsai:types/gmath"

import "game:globals"

import "core:log"

onColEnter :: proc(col: ^physics.Collider, other: ^physics.Collider) {
	log.infof("Collision between: %v, and %v", col.tag, other.tag)
}

spawnPlayer :: proc(data: entities.EntityData) -> ^entities.Entity {
	entity := entities.create(entities.EntityName.Player)
	entities.setPlayerHandle(entity.handle)
	entity.position = data.position

	physics.newCollider(
		globals.physicsWorld,
		&entity.position,
		&entity.velocity,
		gmath.Vec2{8, 16},
		tag = "Player",
		pivot = gmath.Pivot.bottomCenter,
		debugColor = gmath.Vec4{1, 1, 1, 0.2},
		onCollisionEnter = onColEnter,
	)
	entity.drawOffset = gmath.Vec2{0.5, 5} // this kinda just has to be hardcoded
	entity.drawPivot = gmath.Pivot.bottomCenter // recommended for y sort

	entity.updateProc = proc(entity: ^entities.Entity) {
		inputDir := input.getInputVector()
		entity.velocity = inputDir * 100.0 // with physics, just have to update the velocity

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

	entity.drawProc = proc(entity: ^entities.Entity) {
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
