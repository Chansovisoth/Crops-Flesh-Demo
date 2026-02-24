# Script   : player.gd
# Function : Most player mechanics

extends CharacterBody2D
class_name Player

# ===== PLAYER MOVEMENT =====
const SPEED := 50.0
const SPRINT_MULTIPLIER := 1.6

# ===== PLAYER ANIMATION =====
@onready var anim_player: AnimationPlayer = $AnimationPlayer # for walking & sfx
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D # for red modulate
var facing := "down"

# ===== FOOTSTEP SOUND SPEED =====
@export var footstep_multiplier_walk: float = 1.2
@export var footstep_multiplier_sprint: float = 1.6
var _was_sprinting: bool = false

# ===== CAMERA =====
@export var camera: PlayerCamera

# ===== WORLD LIGHTING =====
@onready var world_environment: WorldEnv = $"../../../WorldEnvironment"
#@export var world_environment: WorldEnv

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

# ===== AUDIOS =====
@onready var background_music: AudioStreamPlayer2D = $BackgroundMusic
@onready var sfx_footstep: AudioStreamPlayer2D = $Footstep
@onready var sfx_door_open: AudioStreamPlayer2D = $SFX/DoorOpen
@onready var sfx_door_close: AudioStreamPlayer2D = $SFX/DoorClose
@onready var sfx_gun_shoot: AudioStreamPlayer2D = $SFX/GunShoot
@onready var sfx_writing: AudioStreamPlayer2D = $SFX/Writing
@onready var sfx_hurt: AudioStreamPlayer2D = $SFX/Hurt
@onready var sfx_hungry: AudioStreamPlayer2D = $SFX/Hungry
@onready var sfx_death: AudioStreamPlayer2D = $SFX/Death

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
		restart()
	
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
		
	# DEBUGGING KEYS
	if event is InputEventKey and event.is_pressed() and not event.echo:
		if event.keycode == KEY_9:
			GameState.change_hp(-10)
		if event.keycode == KEY_0:
			GameState.change_hunger(-10)
		if event.keycode == KEY_O:
			GameState.reset_stats()
		if event.keycode == KEY_P:
			shake()

# ====================
# MAIN FUNCTIONS
# ====================
#region
func _ready() -> void:
	GameState.player = self # FOR BYPASS
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
		if sprinting != _was_sprinting and sfx_footstep.playing:
			sfx_footstep.stop()
		var base_multiplier: float = footstep_multiplier_sprint if sprinting else footstep_multiplier_walk
		var random_range_min: float = 0.7 if sprinting else 0.6
		var random_range_max: float = 1.5 if sprinting else 1.4
		if not sfx_footstep.playing:
			sfx_footstep.pitch_scale = base_multiplier * randf_range(random_range_min, random_range_max)
			sfx_footstep.play()
	else:
		if sfx_footstep.playing:
			sfx_footstep.stop()
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
	GameState.reset_stats()
	inventory.clear()
	world_environment.fade_out()
	await get_tree().create_timer(1.0).timeout
	sprite.modulate = Color(1, 1, 1, 1)
	get_tree().reload_current_scene()

func collect(item) -> void:
	inventory.insert(item)

func shake() -> void:
	camera.add_trauma(0.2)

func hurt() -> void:
	sfx("hurt")
	camera.add_trauma(0.2)
	sprite.modulate = Color(1.8, 0.3, 0.3, 1.0)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color(1, 1, 1, 1)

func death() -> void:
	sfx("death")
	background_music.volume_db = -80.0
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1.8, 0.3, 0.3, 1.0)
	await get_tree().create_timer(2).timeout
	restart()

func sleep() -> void:
	world_environment.fade_sleep()

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
	if not sfx_gun_shoot.playing:
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
			if sfx_door_open:
				sfx_door_open.pitch_scale = randf_range(0.8, 1.05)
				sfx_door_open.play()
		"door_close":
			if sfx_door_close:
				sfx_door_close.pitch_scale = randf_range(0.8, 1.05)
				sfx_door_close.play()
		"gun_shoot":
			if sfx_gun_shoot:
				sfx_gun_shoot.pitch_scale = randf_range(0.95, 1.0)
				sfx_gun_shoot.play()
		"writing":
			if sfx_writing:
				sfx_writing.pitch_scale = randf_range(0.98, 1.1)
				sfx_writing.play()
		"hurt":
			if sfx_hurt:
				sfx_hurt.pitch_scale = randf_range(0.98, 1.1)
				sfx_hurt.play()
		"hungry":
			if sfx_hungry:
				sfx_hungry.pitch_scale = randf_range(0.98, 1.1)
				sfx_hungry.play()
		"death":
			if sfx_death:
				sfx_death.pitch_scale = randf_range(0.95, 1)
				sfx_death.play()
		_:
			print("player: SFX()\n- Unknown sound -> ", name)
#endregion
