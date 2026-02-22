# Script   : player_name.gd
# Function : Adds player name to label from array

extends Label

func _ready() -> void:
	name = GameState.player_stats["display_name"]
	if name:
		text = name
