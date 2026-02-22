# Script   : player.gd
# Function : Most player mechanics

extends CharacterBody2D
class_name Player

# ===== PLAYER MOVEMENT =====
const SPEED := 50.0
const SPRINT_MULTIPLIER := 1.6

# ===== PLAYER ANIMATION =====
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var facing := "down"

# ===== FOOTSTEP SOUND SPEED =====
@export var footstep_multiplier_walk: float = 1.2
@export var footstep_multiplier_sprint: float = 1.6
var _was_sprinting: bool = false

# ===== WORLD LIGHTING =====
@export var world_environment: WorldEnv

# ===== CURSOR GUN =====
@export var cursor_gun: Texture2D = preload("res://Asset/Texture/GUI/cursor_gun.png")
const CURSOR_GUN_OFFSET := Vector2(64, 64)
var gun_equipped := false
var _default_cursor_shape: Input.CursorShape

# ===== GUN FLASH =====
@onready var gun_flash: PointLight2D = $"PointLight2D (Gun Flash)"
@export var gun_flash_duration: float = 0.04
var _gun_flash_id: int = 0

# ===== ACTIONABLE FINDER =====
@onready var actionable_finder: Area2D = $Direction/ActionableFinder

# ===== AUDIO =====
@onready var background_music: AudioStreamPlayer2D = $Audio/BackgroundMusic
@onready var door_open: AudioStreamPlayer2D = $Audio/DoorOpen
@onready var door_close: AudioStreamPlayer2D = $Audio/DoorClose
@onready var gun_shoot: AudioStreamPlayer2D = $Audio/GunShoot
@onready var footstep: AudioStreamPlayer2D = $Footstep

# ===== INVENTORY =====
@export var inventory: Inventory
@export var inventort_ui: InventoryUI

# ====================
# INPUTS
# ====================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_exit"):
		print("player: get_tree().quit()")
		get_tree().quit()

	if event.is_action_pressed("menu_restart"):
		GameState.restart()
		return
	
	if event.is_action_pressed("action_gun"):
		gun_toggle()

	if event.is_action_pressed("action_use") and gun_equipped:
		if _is_mouse_over_ui():
			return
		shoot()
	elif event.is_action_pressed("action_use"):
		dialogue()

	if event.is_action_pressed("action_interact"):
		dialogue()

	if event.is_action_pressed("toggle_mute"):
		GameState.toggle_muted()
	
	if event.is_action_pressed("toggle_inventory"):
		inventort_ui.toggle()

# ====================
# MAIN FUNCTIONS
# ====================
#region
func _ready() -> void:
	GameState.update_current_scene()
	print("\nYou are in ", GameState.current_scene)
	print(GameState.player_stats)
	_default_cursor_shape = Input.get_current_cursor_shape()
	Input.set_custom_mouse_cursor(null)
	gun_flash.visible = false
	GameState.set_muted(GameState.muted)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	# ===== MOVEMENT =====
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	var speed := SPEED * (SPRINT_MULTIPLIER if sprinting else 1.0)

	velocity = dir * speed
	move_and_slide()

	# ===== ANIMATION =====
	var is_moving: bool = dir != Vector2.ZERO

	if is_moving:
		if abs(dir.x) > abs(dir.y):
			facing = "right" if dir.x > 0.0 else "left"
		else:
			facing = "down" if dir.y > 0.0 else "up"

	_update_animation(is_moving, sprinting)

	# ===== FOOTSTEP SOUND LOOP =====
	if is_moving:
		if sprinting != _was_sprinting and footstep.playing:
			footstep.stop()

		var base_multiplier: float = footstep_multiplier_sprint if sprinting else footstep_multiplier_walk
		var random_range_min: float = 0.7 if sprinting else 0.6
		var random_range_max: float = 1.5 if sprinting else 1.4

		if not footstep.playing:
			footstep.pitch_scale = base_multiplier * randf_range(random_range_min, random_range_max)
			footstep.play()
	else:
		if footstep.playing:
			footstep.stop()

	_was_sprinting = sprinting


func _update_animation(is_moving: bool, sprinting: bool) -> void:
	var anim_name := ("walk_" if is_moving else "idle_") + facing
	anim_player.speed_scale = 1.2 if sprinting else 1.0
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
#endregion

# ====================
# OTHER
# ====================
#region
func restart() -> void:
	# Keep this for compatibility, but route to GameState
	GameState.restart()

func gun_toggle() -> void:
	gun_equipped = !gun_equipped
	print("player: gun_toggle()\n- ", gun_equipped)

	if gun_equipped:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(cursor_gun, Input.CURSOR_ARROW, CURSOR_GUN_OFFSET)
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_default_cursor_shape(_default_cursor_shape)

func shoot() -> void:
	if not gun_shoot.playing:
		_flash_gun()
		sfx("gun_shoot")

func _flash_gun() -> void:
	_gun_flash_id += 1
	var current_id := _gun_flash_id
	gun_flash.visible = true
	await get_tree().create_timer(gun_flash_duration).timeout
	if current_id != _gun_flash_id:
		return
	gun_flash.visible = false

func _is_mouse_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	var node: Node = hovered
	while node != null:
		if node is TextureButton:
			return true
		node = node.get_parent()
	return false

func dialogue() -> void:
	# Use GameState.dialogue_active (rolled back name)
	if GameState.dialogue_active:
		return

	var actionables = actionable_finder.get_overlapping_areas()
	if actionables.size() > 0:
		GameState.dialogue_active = true
		print("player: dialogue()")
		actionables[0].action()

func sfx(sfx_name: String) -> void:
	match sfx_name:
		"door_open":
			if door_open:
				door_open.pitch_scale = randf_range(0.8, 1.05)
				door_open.play()
		"door_close":
			if door_close:
				door_close.pitch_scale = randf_range(0.8, 1.05)
				door_close.play()
		"gun_shoot":
			if gun_shoot:
				gun_shoot.pitch_scale = randf_range(0.95, 1.0)
				gun_shoot.play()
		_:
			print("player: SFX()\n- Unknown sound -> ", name)
#endregion
