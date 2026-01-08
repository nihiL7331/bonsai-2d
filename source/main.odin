package main

import "base:runtime"
import "core:log"

import "bonsai:core"
import "bonsai:core/audio"
import "bonsai:core/clock"
import "bonsai:core/gmath"
import "bonsai:core/input"
import "bonsai:core/logger"
import "bonsai:core/platform/web"
import "bonsai:core/render"

import sokol_app "bonsai:libs/sokol/app"
import sokol_gfx "bonsai:libs/sokol/gfx"
import sokol_log "bonsai:libs/sokol/log"
import stb_image "bonsai:libs/stb/image"

import game_app "game"
import "game:scenes"

// force import of web package for non-web builds to prevent compilation errors
_ :: web

IS_WEB :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
ICON_DATA :: #load("../assets/icon.png")

odinContext: runtime.Context

main :: proc() {
	when IS_WEB { 	// via karl zylinski's odin-sokol-web
		// The WASM allocator doesn't seem to work properly in combination with
		// emscripten. There is some kind of conflict with how they manage
		// memory. So this sets up an allocator that uses emscripten's malloc.
		context.allocator = web.allocator()

		// Make temp allocator use new `context.allocator` by re-initing it.
		runtime.init_global_temporary_allocator(1 * runtime.Megabyte)
	}

	context.logger = logger.createInstance()
	context.assertion_failure_proc = logger.assertionFailureProc

	odinContext = context

	coreContext := core.initCoreContext(1280, 720)

	description: sokol_app.Desc
	description.init_cb = init
	description.frame_cb = frame
	description.event_cb = event
	description.cleanup_cb = cleanup

	description.width = coreContext.windowWidth
	description.height = coreContext.windowHeight
	description.sample_count = 4 //MSAA
	description.window_title = core.WINDOW_TITLE
	description.high_dpi = true
	description.html5_update_document_title = true
	description.logger.func = sokol_log.func

	_setupWindowIcon(&description)

	sokol_app.run(description)
}


init :: proc "c" () {
	context = odinContext

	coreContext := core.getCoreContext()

	// sync core window size
	// instantly update windowWidth and windowHeight to fix scale issues on web
	coreContext.windowWidth = sokol_app.width()
	coreContext.windowHeight = sokol_app.height()

	gmath.setRandomSeed(u64(clock.getApplicationInitTime()))
	scenes.initRegistry()
	input.init()
	audio.init()
	render.init()

	game_app.init()
}

@(private = "file")
lastFrameTime: f64

frame :: proc "c" () {
	context = odinContext

	if input.isKeyPressed(.ENTER) && input.isKeyDown(.LEFT_ALT) {
		sokol_app.toggle_fullscreen()
	}

	coreContext := core.getCoreContext()

	audio.setListenerPosition(coreContext.camera.position)

	clock.tick()

	render.coreRenderFrameStart()

	game_app.update()
	game_app.draw()

	render.coreRenderFrameEnd()

	input.resetInputState(input.getInputState())
	free_all(context.temp_allocator)
}

event :: proc "c" (e: ^sokol_app.Event) {
	context = odinContext

	if e.type == .RESIZED {
		coreContext := core.getCoreContext()
		coreContext.windowWidth = sokol_app.width()
		coreContext.windowHeight = sokol_app.height()
	}

	input.getInputEventCallback()(e)
}

cleanup :: proc "c" () {
	context = odinContext

	render.destroyFonts()
	game_app.shutdown()
	sokol_gfx.shutdown()
	audio.shutdown()

	when IS_WEB {
		runtime._cleanup_runtime()
	}
}

@(private = "file")
_setupWindowIcon :: proc(description: ^sokol_app.Desc) {
	width, height, channels: i32

	// decode png from memory
	imageData := render.getImageData(
		raw_data(ICON_DATA),
		i32(len(ICON_DATA)),
		&width,
		&height,
		&channels,
	)

	if imageData == nil {
		log.error("Failed to decode window icon. Using default Sokol icon.")
		description.icon.sokol_default = true
		return
	}
	defer stb_image.image_free(imageData)

	description.icon.sokol_default = false
	description.icon.images[0] = sokol_app.Image_Desc {
		width = width,
		height = height,
		pixels = {ptr = imageData, size = uint(width * height * 4)},
	}
}
