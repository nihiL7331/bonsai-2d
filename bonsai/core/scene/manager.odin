package scene_manager

// @overview
// This package implements a lightweight scene manager.
// It streamlines the game loop by mapping directory names to scene enums.
//
// **Features:**
// - **Auto-generated enums:** The `SceneName` enum from the `bonsai:generated` package
//   is generated automatically based on directories found in **source/game/scenes**.
// - **Lifecycle management:** Standardized hooks for `init`, `update`, `draw` and `exit`.
// - **State persistence:** Data is passed between procedures via a `rawptr` to a state array.
// - **Simple navigation:** Specific `change` function to handle transitions, changing on the
//   next frame to allow cleanup within the `exit` function.
//
// **Usage:**
// To create a new scene, create a directory in **source/game/sources** and include the following code:
//
// ```Odin
// package scene_name // Name the package accordingly
//
// // Cast the rawptr to your specific Data state struct
// init :: proc(data: rawptr) {
//   // state := (^Data)(data)
// }
//
// update :: proc(data: rawptr) {
//   // state := (^Data)(data)
// }
//
// draw :: proc(data: rawptr) {
//   // state := (^Data)(data)
// }
//
// exit :: proc(data: rawptr) {
//   // state := (^Data)(data)
// }
// ```
//
// Then, in your main **game.odin** file:
// ```Odin
// init :: proc() {
//   // Initialize with the starting scene enum
//   scene.init(.mainmenu)
// }
//
// update :: proc() {
//   scene.update()
// }
//
// draw :: proc() {
//   scene.draw()
// }
// ```

import "bonsai:core"
import "bonsai:core/scene/type"
import "bonsai:generated"

import "core:log"


// internal lookup table for all scenes, indexed by the SceneName enum
@(private = "file")
_scenes: [generated.SceneName]type.Scene

// @ref
// Bootstraps the **Scene Manager** with the starting scene.
// Immediately initializes and **sets the current scene**.
init :: proc(sceneName: generated.SceneName) {
	if sceneName == generated.SceneName.nil {
		log.error("Initializing with an empty/nil scene is not supported.")
		return
	}

	startScene := &_scenes[sceneName]
	core.getCoreContext().currentScene = startScene

	if startScene.init != nil {
		startScene.init(startScene.data)
	}
}

// Registers a scene implementation to the internal registry.
// Called by the auto-generated code in generated_registry.odin.
register :: proc(sceneName: generated.SceneName, scene: type.Scene) {
	_scenes[sceneName] = scene
}

// @ref
// Queues a transition to a new scene.
// The actual transition occurs at the start of the **next frame**.
change :: proc(sceneName: generated.SceneName) {
	if sceneName == generated.SceneName.nil {
		log.error("Cannot change to .nil scene.")
		return
	}

	nextScene := &_scenes[sceneName]

	if nextScene.init == nil && nextScene.update == nil && nextScene.draw == nil {
		log.errorf("Attempted to load an unregistered scene: %v.", sceneName)
		return
	}

	core.getCoreContext().nextScene = nextScene
}

// @ref
// Main update loop for the active scene.
// Handles the lifecycle of scene transitions **automatically**.
update :: proc() {
	coreContext := core.getCoreContext()
	currentScene := coreContext.currentScene
	nextScene := coreContext.nextScene

	if nextScene != nil {
		// exit previous scene
		if currentScene != nil && currentScene.exit != nil {
			currentScene.exit(currentScene.data)
		}

		// swap references
		coreContext.currentScene = nextScene
		coreContext.nextScene = nil

		// update local reference
		currentScene = coreContext.currentScene

		// init new scene
		if currentScene.init != nil {
			currentScene.init(currentScene.data)
		}
	}

	// standard update
	if currentScene != nil && currentScene.update != nil {
		currentScene.update(currentScene.data)
	}
}

// @ref
// Calls the draw procedure of the **currently active** scene.
draw :: proc() {
	currentScene := core.getCoreContext().currentScene
	if currentScene != nil && currentScene.draw != nil {
		currentScene.draw(currentScene.data)
	}
}
