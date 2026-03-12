# Script   : text_mission.gd
# Function : display text for mission, also updates

extends MarginContainer

@onready var label: Label = $Label

func _ready() -> void:
	GameState.zombies_killed_changed.connect(_update_text)
	_update_text()

func _update_text() -> void:
	label.text = GameState.get_mission_text()
