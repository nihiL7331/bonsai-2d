package scene_manager

import "bonsai:core"
import "bonsai:types/game"

import "core:log"

// internal lookup table for all scenes, indexed by the SceneName enum
@(private = "file")
_scenes: [game.SceneName]game.Scene

// helper to access the global world state
@(private = "file")
_getWorldState :: proc() -> ^game.WorldState {
	return core.getCoreContext().gameState.world
}

// @ref
// Bootstraps the **Scene Manager** with the starting scene.
// Immediately initializes and **sets the current scene**.
init :: proc(sceneName: game.SceneName) {
	if sceneName == game.SceneName.nil {
		log.error("Initializing with an empty/nil scene is not supported.")
		return
	}

	startScene := &_scenes[sceneName]
	_getWorldState().currentScene = startScene

	if startScene.init != nil {
		startScene.init(startScene.data)
	}
}

// @ref
// Registers a scene implementation to the internal registry.
// Called by the auto-generated code in **generated_registry.odin**.
register :: proc(sceneName: game.SceneName, scene: game.Scene) {
	_scenes[sceneName] = scene
}

// @ref
// Queues a transition to a new scene.
// The actual transition occurs at the start of the **next frame**.
change :: proc(sceneName: game.SceneName) {
	if sceneName == game.SceneName.nil {
		log.error("Cannot change to .nil scene.")
		return
	}

	nextScene := &_scenes[sceneName]

	if nextScene.init == nil && nextScene.update == nil && nextScene.draw == nil {
		log.errorf("Attempted to load an unregistered scene: %v.", sceneName)
		return
	}

	_getWorldState().nextScene = nextScene
}

// @ref
// Main update loop for the active scene.
// Handles the lifecycle of scene transitions **automatically**.
update :: proc() {
	world := _getWorldState()
	currentScene := world.currentScene
	nextScene := world.nextScene

	if nextScene != nil {
		// exit previous scene
		if currentScene != nil && currentScene.exit != nil {
			currentScene.exit(currentScene.data)
		}

		// swap references
		world.currentScene = nextScene
		world.nextScene = nil

		// update local reference
		currentScene = world.currentScene

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
	currentScene := _getWorldState().currentScene
	if currentScene != nil && currentScene.draw != nil {
		currentScene.draw(currentScene.data)
	}
}
