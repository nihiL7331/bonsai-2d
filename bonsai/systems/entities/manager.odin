package entities

import "core:fmt"

import "bonsai:core/clock"
import "bonsai:core/render"
import "bonsai:types/color"
import "bonsai:types/game"
import "bonsai:types/gmath"

@(private)
_zeroEntity: Entity
@(private)
_noopUpdate :: proc(e: ^Entity) {}
@(private)
_noopDraw :: proc(e: ^Entity) {}
@(private)
_entityStorage: ^EntityStorage
@(private)
_allEntities: []EntityHandle

getPlayer :: proc() -> ^Entity {
	if _entityStorage == nil do return &_zeroEntity
	return entityFromHandle(_entityStorage.playerHandle)
}

setPlayerHandle :: proc(playerHandle: EntityHandle) {
	_entityStorage.playerHandle = playerHandle
}

isValid :: proc {
	entityIsValid,
	entityIsValidPtr,
}
entityIsValid :: proc(entity: Entity) -> bool {
	return entity.handle.id != 0
}
entityIsValidPtr :: proc(entity: ^Entity) -> bool {
	return entity != nil && entityIsValid(entity^)
}

entityInitCore :: proc() {
	_zeroEntity.name = .nil
	_zeroEntity.updateProc = _noopUpdate
	_zeroEntity.drawProc = _noopDraw
	_entityStorage = new(EntityStorage)
}

updateAll :: proc() {
	rebuildScratchHelpers()

	for handle in _allEntities {
		e := entityFromHandle(handle)

		updateAnimation(e)

		if e.updateProc == nil do continue
		e.updateProc(e)
	}
}

drawAll :: proc() {
	for handle in _allEntities {
		e, ok := entityFromHandle(handle)
		if !ok do continue

		if e.drawProc == nil do continue
		e.drawProc(e)
	}
}

cleanup :: proc() {
	free(_entityStorage)
}

entityFromHandle :: proc(handle: EntityHandle) -> (entity: ^Entity, ok: bool) #optional_ok {
	if handle.index <= 0 || handle.index > _entityStorage.topCount {
		return &_zeroEntity, false
	}

	returnEntity := &_entityStorage.data[handle.index]
	if returnEntity.handle.id != handle.id {
		return &_zeroEntity, false
	}

	return returnEntity, true
}

rebuildScratchHelpers :: proc() {
	allEntities := make(
		[dynamic]EntityHandle,
		0,
		len(_entityStorage.data),
		allocator = context.temp_allocator,
	)
	for &entity in _entityStorage.data {
		if !isValid(entity) do continue
		append(&allEntities, entity.handle)
	}
	_allEntities = allEntities[:]
}


create :: proc(name: EntityName) -> ^Entity {
	index := -1
	if len(_entityStorage.freeList) > 0 {
		index = pop(&_entityStorage.freeList)
	}

	if index == -1 {
		assert(_entityStorage.topCount + 1 < MAX_ENTITIES, "Ran out of entities.")
		_entityStorage.topCount += 1
		index = _entityStorage.topCount
	}

	entity := &_entityStorage.data[index]
	entity.handle.index = index
	entity.handle.id = _entityStorage.latestId + 1
	_entityStorage.latestId = entity.handle.id

	entity.name = name
	entity.drawPivot = gmath.Pivot.bottomCenter
	entity.drawProc = drawEntityDefault

	fmt.assertf(entity.name != nil, "Entity %v needs to define a name during setup", name)

	return entity
}

destroy :: proc(e: ^Entity) {
	append(&_entityStorage.freeList, e.handle.index)
	e^ = {}
}

drawEntityDefault :: proc(e: ^Entity) {
	if e.sprite == nil {
		return
	}

	xForm := gmath.xFormRotate(e.rotation)

	drawSpriteEntity(
		e,
		e.position,
		e.sprite,
		xForm = xForm,
		animIndex = e.animationIndex,
		drawOffset = e.drawOffset,
		flipX = e.flipX,
		pivot = e.drawPivot,
		zLayer = game.ZLayer.playspace,
	)
}

drawSpriteEntity :: proc(
	entity: ^Entity,
	position: gmath.Vec2,
	sprite: game.SpriteName,
	pivot := gmath.Pivot.centerCenter,
	flipX := false,
	drawOffset := gmath.Vec2{},
	xForm := gmath.Mat4(1),
	animIndex := 0,
	col := color.WHITE,
	colorOverride := gmath.Vec4{},
	zLayer := game.ZLayer{},
	flags := game.QuadFlags{},
	parameters := gmath.Vec4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	zLayerQueue := -1,
) {
	colorOverride := colorOverride

	colorOverride = entity.scratch.colorOverride
	if entity.hitFlash.a != 0 {
		colorOverride.xyz = entity.hitFlash.xyz
		colorOverride.a = max(colorOverride.a, entity.hitFlash.a)
	}

	render.drawSprite(
		position,
		sprite,
		pivot,
		flipX,
		drawOffset,
		xForm,
		animIndex,
		col,
		colorOverride,
		zLayer,
		flags,
		parameters,
		cropTop,
		cropLeft,
		cropBottom,
		cropRight,
		culling = true,
	)
}

setAnimation :: proc(e: ^Entity, sprite: game.SpriteName, frameDuration: f32, looping := true) {
	if e.sprite != sprite {
		e.sprite = sprite
		e.looping = looping
		e.frameDuration = frameDuration
		e.animationIndex = 0
		e.nextFrameEndTime = 0
	}
}

updateAnimation :: proc(e: ^Entity) {
	if e.frameDuration == 0 do return

	frameCount := game.getFrameCount(e.sprite)

	isPlaying := true
	if !e.looping {
		isPlaying = e.animationIndex + 1 <= frameCount
	}

	if isPlaying {
		if e.nextFrameEndTime == 0 {
			e.nextFrameEndTime = clock.now() + f64(e.frameDuration)
		}

		if clock.endTimeUp(e.nextFrameEndTime) {
			e.animationIndex += 1
			e.nextFrameEndTime = 0

			if e.animationIndex >= frameCount && e.looping {
				e.animationIndex = 0
			}
		}
	}
}
