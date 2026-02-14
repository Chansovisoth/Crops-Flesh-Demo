# Script   : player.gd
# Function : Most player mechanics

extends CharacterBody2D

# ===== PLAYER MOVEMENT =====
const SPEED := 50.0
const SPRINT_MULTIPLIER := 1.6

# ===== PLAYER ANIMATION =====
@onready var anim := $AnimatedSprite2D
var facing := "down"

# ===== WORLD LIGHTING =====
@onready var world_environment := get_tree().current_scene.get_node("WorldEnvironment")

# ===== CURSOR GUN =====
@export var cursor_gun: Texture2D = preload("res://Asset/Texture/GUI/cursor_gun.png")
const CURSOR_GUN_OFFSET := Vector2(64, 64)
var gun_equipped := false
var _default_cursor_shape: Input.CursorShape
@onready var gun_shoot: AudioStreamPlayer2D = $Audio/GunShoot

# ===== GUN FLASH =====
@onready var gun_flash: PointLight2D = $"PointLight2D (Gun Flash)"
@export var gun_flash_duration: float = 0.04
var _gun_flash_id: int = 0

# ====================
# INPUTS
# ====================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_exit"):
		get_tree().quit()

	if event.is_action_pressed("menu_restart"):
		restart()

	if event.is_action_pressed("action_gun"):
		gun_toggle()

	if event.is_action_pressed("action_shoot") and gun_equipped:
		if _is_mouse_over_ui():
			return
		shoot()

# ====================
# MAIN FUNCTIONS
# ====================
func _ready() -> void:
	_default_cursor_shape = Input.get_current_cursor_shape()
	Input.set_custom_mouse_cursor(null)
	gun_flash.visible = false

func _physics_process(delta: float) -> void:
	# ===== MOVEMENT =====
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	var speed := SPEED
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	if sprinting:
		speed *= SPRINT_MULTIPLIER

	velocity = dir * speed
	move_and_slide()

	# ===== ANIMATION =====
	if dir == Vector2.ZERO:
		anim.speed_scale = 1.0
		anim.play("idle_" + facing)
		return

	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"

	anim.speed_scale = 1.5 if sprinting else 1.1
	anim.play("walk_" + facing)

# ====================
# OTHER
# ====================
func restart() -> void:
	world_environment.fade_out()
	await get_tree().create_timer(1).timeout
	get_tree().call_deferred("reload_current_scene")

func gun_toggle() -> void:
	gun_equipped = !gun_equipped

	if gun_equipped:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(
			cursor_gun,
			Input.CURSOR_ARROW,
			CURSOR_GUN_OFFSET
		)
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_default_cursor_shape(_default_cursor_shape)

func shoot() -> void:
	if not gun_shoot.playing:
		gun_shoot.pitch_scale = randf_range(0.95, 1.0)
		_flash_gun()
		gun_shoot.play()

func _flash_gun() -> void:
	# Can override previous flash if spamming
	_gun_flash_id += 1
	var current_id := _gun_flash_id

	# Flash appear
	gun_flash.visible = true

	await get_tree().create_timer(gun_flash_duration).timeout
	if current_id != _gun_flash_id:
		return

	gun_flash.visible = false

# Block shoot when clicking buttons when gun is enabled
func _is_mouse_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false

	# Block shoot when hovering HUD buttons
	var node: Node = hovered
	while node != null:
		if node is TextureButton:
			return true
		node = node.get_parent()

	return false
