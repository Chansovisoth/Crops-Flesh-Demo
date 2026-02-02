# Script   : player.gd
# Function : Most player mechanics

extends CharacterBody2D

const SPEED := 50.0
const SPRINT_MULTIPLIER := 1.6

@onready var anim := $AnimatedSprite2D
@onready var world_environment := get_tree().current_scene.get_node("WorldEnvironment")

var facing := "down"

@export var cursor_gun: Texture2D = preload("res://Asset/Texture/GUI/cursor_gun.png")
const CURSOR_GUN_OFFSET := Vector2(64, 64)
var cursor_is_gun := false
var _default_cursor_shape: Input.CursorShape
@onready var gun_shoot: AudioStreamPlayer2D = $Audio/GunShoot

# --- Gun flash light (PointLight2D) ---
@onready var gun_flash: PointLight2D = $"PointLight2D (Gun Flash)"
@export var gun_flash_duration: float = 0.04
var _gun_flash_token: int = 0

# ====================
# INPUTS
# ====================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_exit"):
		get_tree().quit()

	if event.is_action_pressed("menu_restart"):
		restart()

	if event.is_action_pressed("action_gun"):
		toggle_cursor_gun()

	if event.is_action_pressed("action_shoot") and cursor_is_gun:
		shoot()

# ====================
# MAIN FUNCTIONS
# ====================
func _ready() -> void:
	_default_cursor_shape = Input.get_current_cursor_shape()
	Input.set_custom_mouse_cursor(null) # Ensure we start clean

	# Make sure the flash starts hidden
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

func toggle_cursor_gun() -> void:
	cursor_is_gun = !cursor_is_gun

	if cursor_is_gun:
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
		gun_shoot.play()
		_flash_gun()

func _flash_gun() -> void:
	# Cancel/override previous flash if spamming
	_gun_flash_token += 1
	var my_token := _gun_flash_token

	# Show the flash briefly
	gun_flash.visible = true

	await get_tree().create_timer(gun_flash_duration).timeout
	if my_token != _gun_flash_token:
		return

	gun_flash.visible = false
