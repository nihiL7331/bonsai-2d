package platform

import "bonsai:core/platform/desktop"
import "bonsai:core/platform/web"
import "bonsai:generated"

_ :: web
_ :: desktop

PendingData :: struct {
	imageData:   [^]byte,
	imageWidth:  i32,
	imageHeight: i32,
	binData:     []u8,
	isPending:   bool,
}

// @ref
// Updates the sprite atlas data on file modification.
// Works only when the `ODIN_DEBUG` flag is `true`
// (so when the game is built in **debug** mode).
// Called every frame internally.
pollHotReloadSprites :: proc() -> PendingData {
	when IS_WEB {
		return cast(PendingData)web.pollHotReloadSprites()
	} else {
		return cast(PendingData)desktop.pollHotReloadSprites()
	}
}

// @ref
// Updates the font data on file modification.
// Works only when the `ODIN_DEBUG` flag is `true`
// (so when the game is built in **debug** mode).
// Called every frame internally.
pollHotReloadFonts :: proc() -> [generated.FontName]PendingData {
	when IS_WEB {
		return transmute([generated.FontName]PendingData)web.pollHotReloadFonts()
	} else {
		return transmute([generated.FontName]PendingData)desktop.pollHotReloadFonts()
	}
}
