#+feature dynamic-literals
package main

import "types/color"
import "types/game"
import "types/gmath"
import "utils"

import "core:fmt"
import "core:math/linalg"

VERSION: string : "v0.0.0"
WINDOW_TITLE :: "Blueprint"
GAME_WIDTH :: 480
GAME_HEIGHT :: 270
windowWidth := 1280
windowHeight := 720


actionMap: [InputAction]KeyCode = {
	.left     = .A,
	.right    = .D,
	.up       = .W,
	.down     = .S,
	.click    = .LEFT_MOUSE,
	.use      = .RIGHT_MOUSE,
	.interact = .E,
}

InputAction :: enum u8 {
	left,
	right,
	up,
	down,
	click,
	use,
	interact,
}

entitySetup :: proc(e: ^game.Entity, kind: game.EntityKind) {
	e.drawProc = drawEntityDefault
	e.drawPivot = gmath.Pivot.bottomCenter

	switch kind {
	case .nil:
		assert(false, "tried to setup .nil kind entity")
	case game.EntityKind.player:
		setupPlayer(e)
	case game.EntityKind.thing1:
		setupThing1(e)
	}
}

spriteData: [game.SpriteName]game.SpriteData = #partial {
	game.SpriteName.player_idle = {frameCount = 2},
	game.SpriteName.player_run = {frameCount = 3},
}


getSpriteOffset :: proc(sprite: game.SpriteName) -> (offset: gmath.Vec2, pivot: gmath.Pivot) {
	data := spriteData[sprite]
	offset = data.offset
	pivot = data.pivot
	return
}

getFrameCount :: proc(sprite: game.SpriteName) -> int {
	frameCount := spriteData[sprite].frameCount
	if frameCount == 0 {
		frameCount = 1
	}
	return frameCount
}

getSpriteCenterMass :: proc(sprite: game.SpriteName) -> gmath.Vec2 {
	size := getSpriteSize(sprite)
	offset, pivot := getSpriteOffset(sprite)

	center := size * utils.scaleFromPivot(pivot)
	center -= offset

	return center
}

appFrame :: proc() {
	coreContext := utils.getCoreContext()
	drawFrame := getDrawFrame()

	// right now we are just calling the game update, but in future this is where you'd do a big
	// "UX" switch for startup splash, main menu, settings, in-game, etc

	{
		// ui space example
		drawFrame.reset.coordSpace = getScreenSpace()

		x, y := screenPivot(gmath.Pivot.topRight)
		x -= 2
		y -= 2
		fpsText := fmt.tprintf("FPS: %.2f", 1.0 / coreContext.deltaTime)

		drawText(
			{x, y},
			fpsText,
			zLayer = game.ZLayer.ui,
			pivot = gmath.Pivot.topRight,
			scale = 0.5,
		)
	}

	gameUpdate()
	gameDraw()
}

gameUpdate :: proc() {
	coreContext := utils.getCoreContext()
	drawFrame := getDrawFrame()

	coreContext.gameState.scratch = {}
	defer {
		coreContext.gameState.gameTimeElapsed += f64(coreContext.deltaTime)
		coreContext.gameState.ticks += 1
	}

	drawFrame.reset.coordSpace = getWorldSpace()

	if coreContext.gameState.ticks == 0 {
		player := entityCreate(.player)
		coreContext.gameState.playerHandle = player.handle
	}

	rebuildScratchHelpers()

	for handle in getAllEnts() {
		e := entityFromHandle(handle)

		updateEntityAnimation(e)

		if e.updateProc == nil do continue
		e.updateProc(e)
	}

	utils.animateToTargetVec2(
		&coreContext.gameState.camPos,
		getPlayer().pos,
		coreContext.deltaTime,
		rate = 10,
	)
}

rebuildScratchHelpers :: proc() {
	coreContext := utils.getCoreContext()

	allEnts := make(
		[dynamic]game.EntityHandle,
		0,
		len(coreContext.gameState.entities),
		allocator = context.temp_allocator,
	)
	for &e in coreContext.gameState.entities {
		if !isValid(e) do continue
		append(&allEnts, e.handle)
	}
	coreContext.gameState.scratch.allEntities = allEnts[:]
}

gameDraw :: proc() {
	drawFrame := getDrawFrame()

	drawFrame.reset.shaderData.ndcToWorldXForm =
		getWorldSpaceCamera() * linalg.inverse(getWorldSpaceProj())
	drawFrame.reset.shaderData.bgRepeatTexAtlasUv = atlasUvFromSprite(.bg_repeat_tex0)

	{
		drawFrame.reset.coordSpace = {
			proj   = gmath.Mat4(1),
			camera = gmath.Mat4(1),
		}

		drawRect(
			gmath.Rect{-1, -1, 1, 1},
			flags = game.QuadFlags.backgroundPixels,
			zLayer = game.ZLayer.background,
		)
	}

	{
		drawFrame.reset.coordSpace = getWorldSpace()

		drawSprite({10, 10}, game.SpriteName.player_still)

		drawText({0, -50}, "odin on the web", pivot = gmath.Pivot.bottomCenter, dropShadowCol = {})

		for handle in getAllEnts() {
			e := entityFromHandle(handle)
			if e.drawProc == nil do continue
			e.drawProc(e)
		}
	}
}

drawEntityDefault :: proc(e: ^game.Entity) {
	if e.sprite == nil {
		return
	}

	xForm := utils.xFormRotate(e.rotation)

	drawSpriteEntity(
		e,
		e.pos,
		e.sprite,
		xForm = xForm,
		animIndex = e.animIndex,
		drawOffset = e.drawOffset,
		flipX = e.flipX,
		pivot = e.drawPivot,
	)
}

drawSpriteEntity :: proc(
	entity: ^game.Entity,
	pos: gmath.Vec2,
	sprite: game.SpriteName,
	pivot := gmath.Pivot.centerCenter,
	flipX := false,
	drawOffset := gmath.Vec2{},
	xForm := gmath.Mat4(1),
	animIndex := 0,
	col := color.WHITE,
	colOverride := gmath.Vec4{},
	zLayer := game.ZLayer{},
	flags := game.QuadFlags{},
	params := gmath.Vec4{},
	cropTop: f32 = 0.0,
	cropLeft: f32 = 0.0,
	cropBottom: f32 = 0.0,
	cropRight: f32 = 0.0,
	zLayerQueue := -1,
) {
	colOverride := colOverride

	colOverride = entity.scratch.colOverride
	if entity.hitFlash.a != 0 {
		colOverride.xyz = entity.hitFlash.xyz
		colOverride.a = max(colOverride.a, entity.hitFlash.a)
	}

	drawSprite(
		pos,
		sprite,
		pivot,
		flipX,
		drawOffset,
		xForm,
		animIndex,
		col,
		colOverride,
		zLayer,
		flags,
		params,
		cropTop,
		cropLeft,
		cropBottom,
		cropRight,
	)
}

// gameplay stuff

getPlayer :: proc() -> ^game.Entity {
	coreContext := utils.getCoreContext()
	return entityFromHandle(coreContext.gameState.playerHandle)
}

setupPlayer :: proc(e: ^game.Entity) {
	e.kind = game.EntityKind.player

	e.drawOffset = gmath.Vec2{0.5, 5}
	e.drawPivot = gmath.Pivot.bottomCenter

	e.updateProc = proc(e: ^game.Entity) {
		coreContext := utils.getCoreContext()

		inputDir := getInputVector()
		e.pos += inputDir * 100.0 * coreContext.deltaTime

		if inputDir.x != 0 {
			e.lastKnownXDir = inputDir.x
		}

		e.flipX = e.lastKnownXDir < 0

		if inputDir == {} {
			entitySetAnimation(e, .player_idle, 0.3)
		} else {
			entitySetAnimation(e, .player_run, 0.1)
		}

		e.scratch.colOverride = gmath.Vec4{0, 0, 1, 0.2}
	}

	e.drawProc = proc(e: ^game.Entity) {
		drawSprite(e.pos, .shadow_medium, col = {1, 1, 1, 0.2})
		drawEntityDefault(e)
	}
}

setupThing1 :: proc(using e: ^game.Entity) {
	e.kind = game.EntityKind.thing1
}

entitySetAnimation :: proc(
	e: ^game.Entity,
	sprite: game.SpriteName,
	frameDuration: f32,
	looping := true,
) {
	if e.sprite != sprite {
		e.sprite = sprite
		e.loop = looping
		e.frameDuration = frameDuration
		e.animIndex = 0
		e.nextFrameEndTime = 0
	}
}

updateEntityAnimation :: proc(e: ^game.Entity) {
	if e.frameDuration == 0 do return

	frameCount := getFrameCount(e.sprite)

	isPlaying := true
	if !e.loop {
		isPlaying = e.animIndex + 1 <= frameCount
	}

	if isPlaying {
		if e.nextFrameEndTime == 0 {
			e.nextFrameEndTime = now() + f64(e.frameDuration)
		}

		if endTimeUp(e.nextFrameEndTime) {
			e.animIndex += 1
			e.nextFrameEndTime = 0

			if e.animIndex >= frameCount && e.loop {
				e.animIndex = 0
			}
		}
	}
}
