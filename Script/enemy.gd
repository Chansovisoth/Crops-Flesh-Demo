# enemy.gd
# Follows and hurt player

extends CharacterBody2D

@export var speed: float = 30.0
@export var hp_max: int = 20
@export var damage: int = 10
@export var attack_cooldown: float = 0.8
@export var death_fade_time: float = 0.5

@onready var target: Player = $"../Player"
@onready var attack_area: Area2D = $AttackArea
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var hp: int
var _player_in_range := false
var _attacking := false
var _dead := false

func _ready() -> void:
	hp = hp_max
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	_play_idle()

func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# If attacking, don't move (optional)
	if _attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Attack if player in range
	if _player_in_range:
		_start_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Chase
	if target == null:
		_play_idle()
		return

	var dir := (target.global_position - global_position)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	velocity = dir * speed
	move_and_slide()

	# Flip sprite: walk animation only left, so flip when moving right
	if velocity.x > 0.0:
		anim.flip_h = true
	elif velocity.x < 0.0:
		anim.flip_h = false

	if velocity.length_squared() > 0.1:
		_play_walk()
	else:
		_play_idle()

# ====================
# ATTACK RANGE
# ====================
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false

func _start_attack() -> void:
	if _attacking or _dead:
		return

	_attacking = true
	_play_attack()

	# Deal damage once per attack (simple)
	if target and _player_in_range:
		GameState.change_hp(-damage)

	# Wait for cooldown, then allow attacking again
	await get_tree().create_timer(attack_cooldown).timeout
	_attacking = false

# ====================
# HP / DEATH
# ====================
func take_damage(amount: int) -> void:
	if _dead:
		return
	hp = max(hp - amount, 0)
	if hp <= 0:
		_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	_attacking = false
	_player_in_range = false
	velocity = Vector2.ZERO

	_play_dying()

	# wait until dying animation ends
	await anim.animation_finished

	_play_dead()

	# fade out + remove
	await _fade_out_then_free()

func _fade_out_then_free() -> void:
	# Quick fade using modulate alpha
	var t := 0.0
	var start := modulate
	while t < death_fade_time:
		t += get_process_delta_time()
		var a := 1.0 - (t / death_fade_time)
		modulate = Color(start.r, start.g, start.b, a)
		await get_tree().process_frame

	queue_free()

# ====================
# ANIMATION HELPERS
# ====================
func _play_idle() -> void:
	if anim.animation != "idle":
		anim.play("idle")

func _play_walk() -> void:
	if anim.animation != "walk":
		anim.play("walk")

func _play_attack() -> void:
	if anim.animation != "attack":
		anim.play("attack")

func _play_dying() -> void:
	if anim.animation != "dying":
		anim.play("dying")

func _play_dead() -> void:
	if anim.animation != "dead":
		anim.play("dead")
