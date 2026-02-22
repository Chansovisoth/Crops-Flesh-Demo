# Script   : scene_trigger.gd
# Function : For changing to another scene (also checks action_use or action_interacts)

class_name SceneTrigger
extends Area2D

@export var connected_scene: String
@export var scene_folder: String = "res://Scene/"

@export var world_environment: WorldEnv
@export var player: Player

func _on_body_entered(body: Node2D) -> void:
	world_environment.fade_out()

	player.sfx("door_open")
	await get_tree().create_timer(1).timeout
	player.sfx("door_close")
  
	await get_tree().create_timer(0.4).timeout
	var full_path := scene_folder + connected_scene + ".tscn"
	print("\nscene_trigger: _transition()\n- Changing scene to: ", full_path)
	get_tree().call_deferred("change_scene_to_file", full_path)
