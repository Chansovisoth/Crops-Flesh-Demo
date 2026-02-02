# Script   : button_restart.gd
# Function : Button for restarting the game

extends Node
@onready var player := get_tree().current_scene.get_node("Map/YSort/Player")

func _on_pressed() -> void:
	player.restart()
	print("BUTTON: Restart Pressed")
