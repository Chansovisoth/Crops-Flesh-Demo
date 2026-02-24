# Script   : bar_hp.gd
# Function : Update Hungr Bar UI

extends TextureProgressBar

func _ready() -> void:
	GameState.stats_update.connect(update)
	update()
	pass

func update():
	value = GameState.player_stats["hunger"]
