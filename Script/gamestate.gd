# Script   : gamestate.gd (autoload)
# Function : Global script for all game states

extends Node

var player: Player
var inventory: Inventory

var item_gun_taken := false
var player_has_gun := false

var dialogue_active := false
var muted := false
var player_dead := false
var current_scene := ""

var zombies_killed: int = 0
var zombies_goal: int = 20
var _mission_complete_handled := false

var player_stats := {
	"display_name": "Klaude",
	"hp_max": 100,
	"hp": 100,
	"hunger_max": 100,
	"hunger": 100,
}

signal stats_update
signal mute_changed
signal zombies_killed_changed

# ====================
# ALL GET NODES
# ====================
#region
func _get_world_environment() -> Node:
	return get_tree().current_scene.get_node_or_null("WorldEnvironment")
#endregion


# ====================
# PLAYER STATS
# ====================
#region
#region - Current Scene
func update_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene:
		current_scene = scene.name
#endregion - Scene

#region - Player Stats
func set_display_name(value: String) -> void:
	player_stats["display_name"] = value
	stats_update.emit()

func set_hp(value: int) -> void:
	if player_dead:
		return

	var hp_max: int = player_stats["hp_max"]
	player_stats["hp"] = clampi(value, 0, hp_max)
	stats_update.emit()

	if player_stats["hp"] <= 0 and player and not player_dead:
		player_dead = true
		player.death()

func set_hunger(value: int) -> void:
	var hunger_max: int = player_stats["hunger_max"]
	player_stats["hunger"] = clampi(value, 0, hunger_max)
	stats_update.emit()

func change_hp(delta: int) -> void:
	if delta == 0:
		return

	if delta < 0 and player:
		if player._is_dead:
			return
		if player._is_invincible:
			return

	var old_hp: int = player_stats["hp"]
	set_hp(old_hp + delta)

	if delta < 0 and player and player_stats["hp"] > 0 and not player_dead:
		player.hurt()

func change_hunger(delta: int) -> void:
	var old_hunger: int = player_stats["hunger"]
	set_hunger(old_hunger + delta)

	if delta < 0 and player:
		player.sfx("hungry")

func reset_stats() -> void:
	player_dead = false
	set_hp(player_stats["hp_max"])
	set_hunger(player_stats["hunger_max"])
	reset_zombie_kills()
#endregion - Player Stats
#endregion


# ====================
# ZOMBIE MISSION
# ====================
#region
func add_zombie_kill() -> void:
	zombies_killed += 1
	zombies_killed_changed.emit()

	if is_zombie_mission_complete() and not _mission_complete_handled:
		_mission_complete_handled = true
		_handle_zombie_mission_complete()

func reset_zombie_kills() -> void:
	zombies_killed = 0
	_mission_complete_handled = false
	zombies_killed_changed.emit()

func is_zombie_mission_complete() -> bool:
	return zombies_killed >= zombies_goal

func get_mission_text() -> String:
	var shown_kills := mini(zombies_killed, zombies_goal)
	return "MISSION:\nDefeat %d Zombies (%d/%d)" % [zombies_goal, shown_kills, zombies_goal]

func _handle_zombie_mission_complete() -> void:
	var world_environment := _get_world_environment()

	if world_environment and world_environment.has_method("fade_out"):
		world_environment.call("fade_out")

	await get_tree().create_timer(2.0).timeout

	get_tree().change_scene_to_file("res://Scene/win.tscn")
#endregion


# ====================
# BACKGROUND MUSIC
# ====================
#region
func set_muted(value: bool) -> void:
	muted = value
	_apply_mute()
	mute_changed.emit()

func toggle_muted() -> void:
	set_muted(!muted)

func _apply_mute() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var music := scene.get_node_or_null("Map/YSort/Player/BackgroundMusic") as AudioStreamPlayer2D
	if music == null:
		return

	if not music.has_meta("original_volume_db"):
		music.set_meta("original_volume_db", music.volume_db)

	var original_volume: float = music.get_meta("original_volume_db")
	music.volume_db = -80.0 if muted else original_volume
#endregion


# ====================
# OTHER
# ====================
#region
#func restart() -> void:
#	reset_stats()
#	inventory.clear()
#	var world_environment := _get_world_environment()
#	world_environment.call("fade_out")
#	await get_tree().create_timer(1.0).timeout
#	get_tree().reload_current_scene()

func sleep() -> void:
	var world_environment := _get_world_environment()
	world_environment.call("fade_sleep")
#endregion
