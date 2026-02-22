# Script   : button_restart.gd
# Function : Button for restarting the game

extends Node

func _on_pressed() -> void:
	print("button_restart: _on_pressed()")
	GameState.restart()
