# Script   : dialogue.gd
# Function : Reusable dialogue script

extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var player: Player

func action() -> void:
	if GameState.has_method("set_dialogue_active"):
		GameState.call("set_dialogue_active", true)
	else:
		GameState.dialogue_active = true
	if player:
		player.sfx("writing")
	var balloon := DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
	await balloon.tree_exited
	# Dialogue inactive
	if GameState.has_method("set_dialogue_active"):
		GameState.call("set_dialogue_active", false)
	else:
		GameState.dialogue_active = false
