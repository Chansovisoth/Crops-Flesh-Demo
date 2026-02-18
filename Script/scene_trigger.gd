class_name SceneTrigger extends Node

@export var connected_scene: String
var scene_folder = "res://Scene/"

# ===== WORLD LIGHTING =====
@onready var world_environment := get_tree().current_scene.get_node("WorldEnvironment")

func _on_body_entered(body: Node2D) -> void:
	print("AREA: WALKED IN")
	
	world_environment.fade_out()
	await get_tree().create_timer(1).timeout
	
	var full_path = scene_folder + connected_scene + ".tscn"
	var scene_tree = get_tree()
	scene_tree.call_deferred("change_scene_to_file", full_path)
