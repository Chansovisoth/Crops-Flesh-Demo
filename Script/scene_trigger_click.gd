# Script   : scene_trigger_click.gd
# Function : For changing to another scene (also checks action_use or action_interacts)

class_name SceneTriggerClick
extends Area2D

@export var connected_scene: String
@export var scene_folder: String = "res://Scene/"

@export var world_environment: WorldEnv
@export var player: Player

var _player_inside := false
var _transitioning := false

#region - Player Detection
func _is_player(body: Node) -> bool:
	return body is CharacterBody2D and body.name == "Player"

func _set_player_inside(is_inside: bool, body_name: String, source_fn: String) -> void:
	print("scene_trigger: ", source_fn, "\n- Detecting: ", body_name)
	if _player_inside == is_inside:
		return
	_player_inside = is_inside
	print("- _player_inside = ", _player_inside)

func _on_body_entered(body: Node) -> void:
	if _is_player(body):
		_set_player_inside(true, body.name, "_on_body_entered()")

func _on_body_exited(body: Node) -> void:
	if _is_player(body):
		_set_player_inside(false, body.name, "_on_body_exited()")
#endregion - Player Detection

func _input(event: InputEvent) -> void:
	if _transitioning or not _player_inside:
		return
	if event.is_action_pressed("action_use") or event.is_action_pressed("action_interact"):
		print("scene_trigger: event.is_action_pressed()")
		_transition()

func _transition() -> void:
	_transitioning = true
	world_environment.fade_out()

	player.sfx("door_open")
	await get_tree().create_timer(1).timeout
	player.sfx("door_close")

	await get_tree().create_timer(0.4).timeout
	var full_path := scene_folder + connected_scene + ".tscn"
	print("\nscene_trigger: _transition()\n- Changing scene to: ", full_path)
	get_tree().call_deferred("change_scene_to_file", full_path)
