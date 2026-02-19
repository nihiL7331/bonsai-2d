package platform

import "bonsai:core/platform/desktop"
import "bonsai:core/platform/web"

_ :: web
_ :: desktop

pollHotReload :: proc(
) -> (
	imageData: [^]byte,
	imageWidth: i32,
	imageHeight: i32,
	jsonData: []u8,
	pending: bool,
) {
	when IS_WEB {
		pendingData := web.pollHotReload()
		imageData = pendingData.imageData
		imageWidth = pendingData.imageWidth
		imageHeight = pendingData.imageHeight
		jsonData = pendingData.jsonData
		pending = pendingData.pending
		return
	} else {
		pendingData := desktop.pollHotReload()
		imageData = pendingData.imageData
		imageWidth = pendingData.imageWidth
		imageHeight = pendingData.imageHeight
		jsonData = pendingData.jsonData
		pending = pendingData.pending
		return
	}
}
