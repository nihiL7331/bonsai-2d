// limitations:
// due to it being targeted for web, there are a few limitations/requirements for it to work.
// they are:
// |-> you have to link c libraries for external libs in build_web.*
// |-> you can't use #+feature dynamic-literals
// |-> you can't have global dynamic variables
// |-> avoid @(deferred_out) if possible, send pointers instead
// NOTE: you can also just disobey these limitations and have it not work on web:p
// but IMO this forces you to make cleaner code

package main

import "base:runtime"
import "core:log"

import "bonsai:core"
import "bonsai:core/audio"
import "bonsai:core/clock"
import "bonsai:core/input"
import "bonsai:core/logger"
import "bonsai:core/platform/web"
import "bonsai:core/render"
import sapp "bonsai:libs/sokol/app"
import sg "bonsai:libs/sokol/gfx"
import slog "bonsai:libs/sokol/log"
import stbi "bonsai:libs/stb/image"
import "bonsai:types/game"

import gameapp "game"
import "game:scenes"

_ :: web

IS_WEB :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
ICON_DATA :: #load("../assets/icon.png")

odinContext: runtime.Context

@(private)
_actualGameState: ^game.GameState

main :: proc() {
	when IS_WEB { 	// via karl zylinski's odin-sokol-web
		// The WASM allocator doesn't seem to work properly in combination with
		// emscripten. There is some kind of conflict with how they manage
		// memory. So this sets up an allocator that uses emscripten's malloc.
		context.allocator = web.emscripten_allocator()

		// Make temp allocator use new `context.allocator` by re-initing it.
		runtime.init_global_temporary_allocator(1 * runtime.Megabyte)
	}

	context.logger = logger.logger()
	context.assertion_failure_proc = logger.assertionFailureProc
	odinContext = context

	coreContext := core.initCoreContext()

	description: sapp.Desc
	description.init_cb = init
	description.frame_cb = frame
	description.event_cb = event
	description.cleanup_cb = cleanup
	description.width = coreContext.windowWidth
	description.height = coreContext.windowHeight
	description.sample_count = 4 //MSAA
	description.window_title = gameapp.WINDOW_TITLE
	_setupIcon(&description)
	description.logger.func = slog.func
	description.html5_update_document_title = true
	description.high_dpi = true

	sapp.run(description)
}


init :: proc "c" () {
	context = odinContext

	coreContext := core.getCoreContext()
	_actualGameState = new(game.GameState)
	_actualGameState.world = new(game.WorldState)
	coreContext.gameState = _actualGameState

	// we instantly update windowWidth and windowHeight to fix scale issues on web
	coreContext.windowWidth = sapp.width()
	coreContext.windowHeight = sapp.height()

	scenes.initRegistry()
	input.init()
	audio.init()
	render.init()
	gameapp.init()
}

frameTime: f64
lastFrameTime: f64

frame :: proc "c" () {
	context = odinContext

	{ 	// calculate the delta time
		currentTime := clock.secondsSinceInit()
		frameTime = currentTime - lastFrameTime
		lastFrameTime = currentTime

		MAX_FRAME_TIME :: 1.0 / 20.0
		if frameTime > MAX_FRAME_TIME {
			frameTime = MAX_FRAME_TIME
		}
	}

	coreContext := core.getCoreContext()

	coreContext.deltaTime = f32(frameTime)

	if input.keyPressed(.ENTER) && input.keyDown(.LEFT_ALT) {
		sapp.toggle_fullscreen()
	}

	coreContext.gameState.time.gameTimeElapsed += f64(coreContext.deltaTime)
	coreContext.gameState.time.ticks += 1

	audio.setListenerPosition(coreContext.gameState.world.cameraPosition)

	render.coreRenderFrameStart()
	gameapp.update()


	gameapp.draw()
	render.coreRenderFrameEnd()

	input.resetInputState(input.state)

	free_all(context.temp_allocator)
}

event :: proc "c" (e: ^sapp.Event) {
	context = odinContext

	if e.type == .RESIZED {
		coreContext := core.getCoreContext()
		coreContext.windowWidth = sapp.width()
		coreContext.windowHeight = sapp.height()
	}

	input.inputEventCallback(e)
}

cleanup :: proc "c" () {
	context = odinContext

	gameapp.shutdown()
	sg.shutdown()
	audio.shutdown()

	free(_actualGameState.world)
	free(_actualGameState)

	when IS_WEB {
		runtime._cleanup_runtime()
	}
}

@(private = "file")
_setupIcon :: proc(description: ^sapp.Desc) {
	width, height, channels: i32
	imageData := stbi.load_from_memory(
		raw_data(ICON_DATA),
		i32(len(ICON_DATA)),
		&width,
		&height,
		&channels,
		4,
	)

	if imageData == nil {
		log.error("STB image failed to load the icon image.")
		return
	}

	description.icon.sokol_default = false
	description.icon.images[0] = sapp.Image_Desc {
		width = width,
		height = height,
		pixels = {ptr = imageData, size = uint(width * height * 4)},
	}
}
