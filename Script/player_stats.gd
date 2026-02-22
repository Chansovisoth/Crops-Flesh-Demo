# Script   : player_stats.gd (!!!UNUSED, FOR LATER!!!)
# Function : Per-player persistent data (multiplayer-ready)

extends Resource
class_name PlayerStats

signal updated

@export var player_id: int = 1
@export var display_name: String = "Player"
@export var hp_max: int = 100
@export var hp: int = 100	
@export var hunger_max: int = 100
@export var hunger: int = 100
@export var current_scene: String = ""

# ===== DISPLAY NAME =====
func set_display_name(value: String) -> void:
	display_name = value
	updated.emit()

# ===== HP =====
func set_hp(value: int) -> void:
	hp = clampi(value, 0, hp_max)
	updated.emit()

func change_hp(delta: int) -> void:
	set_hp(hp + delta)

# ===== HUNGER =====
func set_hunger(value: int) -> void:
	hunger = clampi(value, 0, hunger_max)
	updated.emit()

func change_hunger(delta: int) -> void:
	set_hunger(hunger + delta)

# ===== CURRENT SCENE =====
func set_current_scene(scene_path: String) -> void:
	current_scene = scene_path
	updated.emit()
