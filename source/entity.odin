package main

import "core:fmt"

import "types/game"
import "utils"

_zeroEntity: game.Entity

getAllEnts :: proc() -> []game.EntityHandle {
	return utils.getCoreContext().gameState.scratch.allEntities
}

isValid :: proc {
	entityIsValid,
	entityIsValidPtr,
}
entityIsValid :: proc(entity: game.Entity) -> bool {
	return entity.handle.id != 0
}
entityIsValidPtr :: proc(entity: ^game.Entity) -> bool {
	return entity != nil && entityIsValid(entity^)
}

entityInitCore :: proc() {
	entitySetup(&_zeroEntity, .nil)
}

entityFromHandle :: proc(
	handle: game.EntityHandle,
) -> (
	entity: ^game.Entity,
	ok: bool,
) #optional_ok {
	coreContext := utils.getCoreContext()

	if handle.index <= 0 || handle.index > coreContext.gameState.entityTopCount {
		return &_zeroEntity, false
	}

	ent := &coreContext.gameState.entities[handle.index]
	if ent.handle.id != handle.id {
		return &_zeroEntity, false
	}

	return ent, true
}

entityCreate :: proc(kind: game.EntityKind) -> ^game.Entity {
	coreContext := utils.getCoreContext()
	index := -1
	if len(coreContext.gameState.entityFreeList) > 0 {
		index = pop(&coreContext.gameState.entityFreeList)
	}

	if index == -1 {
		assert(
			coreContext.gameState.entityTopCount + 1 < game.MAX_ENTITIES,
			"Ran out of entities.",
		)
		coreContext.gameState.entityTopCount += 1
		index = coreContext.gameState.entityTopCount
	}

	ent := &coreContext.gameState.entities[index]
	ent.handle.index = index
	ent.handle.id = coreContext.gameState.latestEntityId + 1
	coreContext.gameState.latestEntityId = ent.handle.id

	entitySetup(ent, kind)
	fmt.assertf(ent.kind != nil, "Entity %v needs to define a kind during setup", kind)

	return ent
}

entityDestroy :: proc(e: ^game.Entity) {
	coreContext := utils.getCoreContext()

	append(&coreContext.gameState.entityFreeList, e.handle.index)
	e^ = {}
}
