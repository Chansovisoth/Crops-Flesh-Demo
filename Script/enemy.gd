# Script   : enemy.gd
# Function : Patrols or wanders, chases nearby player, and hurts player

extends CharacterBody2D

@export var target: Node2D
@onready var fallback_target: Node2D = $"../Player"

@export var patrol_speed: float = randf_range(10, 25)
@export var chase_speed: float = randf_range(20, 42)
@export var detect_radius: float = 200.0
@export var attack_distance: float = 18.0
@export var patrol_wait_time: float = 1.0

@export var hp_max: int = randf_range(20, 30)
@export var damage: int = 10
@export var attack_cooldown: float = 0.8
@export var death_fade_time: float = 3

@export var patrol_points: Array[NodePath] = []

# Wander settings
@export var wander_enabled: bool = true
@export var wander_radius: float = 96.0
@export var wander_min_distance: float = 24.0
@export var wander_wait_time: float = 1.5

@onready var attack_area: Area2D = $AttackArea
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var path_timer: Timer = $Timer
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var sfx_zombie: AudioStreamPlayer2D = $SFX/Zombie
@onready var sfx_punch: AudioStreamPlayer2D = $SFX/Punch
@onready var sfx_death1: AudioStreamPlayer2D = $SFX/Death1
@onready var sfx_death2: AudioStreamPlayer2D = $SFX/Death2

var _kill_counted: bool = false
var hp: int
var _player_in_range: bool = false
var _attacking: bool = false
var _dead: bool = false
var _patrol_index: int = 0
var _waiting: bool = false
var _hurt_flash_id: int = 0

var _wander_target: Vector2 = Vector2.ZERO
var _has_wander_target: bool = false

func _ready() -> void:
	if target == null:
		target = fallback_target
		
	randomize()

	add_to_group("zombies")

	sfx_death1.stop()
	sfx_death2.stop()
	sfx_punch.stop()

	sfx_zombie.pitch_scale = randf_range(0.65, 1.15)
	sfx_zombie.play()

	hp = hp_max

	if anim.sprite_frames != null:
		anim.sprite_frames.set_animation_loop("dying", false)
		anim.sprite_frames.set_animation_loop("dead", false)

	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)

	if path_timer:
		path_timer.timeout.connect(_on_timer_timeout)

	if nav_agent:
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = 6.0
		nav_agent.avoidance_enabled = false

	_play_idle()

func _physics_process(_delta: float) -> void:
	_handle_debug_damage()

	if _dead:
		velocity = Vector2.ZERO
		if sfx_zombie.playing:
			sfx_zombie.stop()
		move_and_slide()
		return

	if _attacking:
		velocity = Vector2.ZERO
		if not sfx_punch.playing:
			sfx_punch.pitch_scale = randf_range(0.9, 1.05)
			sfx_punch.play()
		move_and_slide()
		return

	if _can_attack_player():
		_start_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _can_chase_player():
		_chase_player()
	else:
		_idle_move()

	_update_visuals()

func _handle_debug_damage() -> void:
	if not Input.is_action_just_pressed("debug_kill_zombies"):
		return

	var zombies := get_tree().get_nodes_in_group("zombies")
	if zombies.is_empty() or zombies[0] != self:
		return

	if target == null:
		return

	for zombie in zombies:
		if zombie == null:
			continue
		if zombie._dead:
			continue
		if zombie.global_position.distance_to(target.global_position) <= detect_radius:
			zombie.hurt(10)

func _can_chase_player() -> bool:
	return target != null and global_position.distance_to(target.global_position) <= detect_radius

func _can_attack_player() -> bool:
	return target != null and _player_in_range and global_position.distance_to(target.global_position) <= attack_distance

func _chase_player() -> void:
	_waiting = false
	_has_wander_target = false
	_move_with_navigation(chase_speed, target.global_position)

func _idle_move() -> void:
	if not patrol_points.is_empty():
		_patrol()
	else:
		_wander()

func _patrol() -> void:
	if _waiting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var patrol_target := get_node_or_null(patrol_points[_patrol_index]) as Node2D
	if patrol_target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if global_position.distance_to(patrol_target.global_position) <= 6.0:
		_start_patrol_wait()
		return

	_move_with_navigation(patrol_speed, patrol_target.global_position)

func _wander() -> void:
	if not wander_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _waiting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not _has_wander_target:
		_pick_new_wander_target()
		return

	if global_position.distance_to(_wander_target) <= 8.0:
		_start_wander_wait()
		return

	_move_with_navigation(patrol_speed, _wander_target)

func _pick_new_wander_target() -> void:
	if nav_agent == null:
		return

	for _i in range(12):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(wander_min_distance, wander_radius)
		var offset := Vector2.RIGHT.rotated(angle) * dist
		var candidate := global_position + offset

		_wander_target = candidate
		_has_wander_target = true
		nav_agent.target_position = _wander_target
		return

	_has_wander_target = false

func _move_with_navigation(move_speed: float, destination: Vector2) -> void:
	if nav_agent == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	nav_agent.target_position = destination

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_pos := nav_agent.get_next_path_position()
	var dir := global_position.direction_to(next_pos)
	velocity = dir * move_speed
	move_and_slide()

func _on_timer_timeout() -> void:
	if _dead or _attacking or nav_agent == null:
		return

	if _can_chase_player() and target != null:
		nav_agent.target_position = target.global_position
	elif not patrol_points.is_empty():
		var patrol_target := get_node_or_null(patrol_points[_patrol_index]) as Node2D
		if patrol_target != null:
			nav_agent.target_position = patrol_target.global_position
	elif _has_wander_target:
		nav_agent.target_position = _wander_target

func _start_patrol_wait() -> void:
	if _waiting:
		return

	_waiting = true
	velocity = Vector2.ZERO
	_play_idle()
	_advance_patrol_after_wait()

func _advance_patrol_after_wait() -> void:
	await get_tree().create_timer(patrol_wait_time).timeout

	if _dead:
		return

	if patrol_points.is_empty():
		_waiting = false
		return

	_patrol_index = (_patrol_index + 1) % patrol_points.size()
	_waiting = false

func _start_wander_wait() -> void:
	if _waiting:
		return

	_waiting = true
	_has_wander_target = false
	velocity = Vector2.ZERO
	_play_idle()

	await get_tree().create_timer(wander_wait_time).timeout

	if _dead:
		return

	_waiting = false

func _update_visuals() -> void:
	if velocity.x > 0.0:
		anim.flip_h = true
	elif velocity.x < 0.0:
		anim.flip_h = false

	if velocity.length_squared() > 1.0:
		_play_walk()
	else:
		_play_idle()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == target:
		_player_in_range = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == target:
		_player_in_range = false

func _start_attack() -> void:
	if _attacking or _dead:
		return

	_attacking = true
	velocity = Vector2.ZERO
	_play_attack()

	if target != null and _can_attack_player():
		GameState.change_hp(-damage)

	await get_tree().create_timer(attack_cooldown).timeout

	if _dead:
		return

	_attacking = false

func hurt(amount: int) -> void:
	if _dead:
		return
	hp = max(hp - amount, 0)
	_play_hurt_flash()
	if not sfx_punch.playing:
			sfx_punch.pitch_scale = randf_range(0.9, 1.05)
			sfx_punch.play()
	if hp <= 0:
		_die()

func _play_hurt_flash() -> void:
	_hurt_flash_id += 1
	var my_flash_id := _hurt_flash_id
	anim.modulate = Color(1.8, 0.3, 0.3, 1.0)
	await get_tree().create_timer(0.2).timeout
	if my_flash_id != _hurt_flash_id:
		return
	anim.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _die() -> void:
	if _dead:
		return
		
	if not _kill_counted:
		_kill_counted = true
		GameState.add_zombie_kill()

	_dead = true
	_attacking = false
	_player_in_range = false
	_waiting = false
	_has_wander_target = false
	velocity = Vector2.ZERO

	if body_collision:
		body_collision.set_deferred("disabled", true)

	if sfx_zombie.playing:
		sfx_zombie.stop()

	_play_hurt_flash()
	_play_random_death_sfx()
	_play_dying()

	if anim.sprite_frames != null and anim.sprite_frames.has_animation("dying"):
		await anim.animation_finished

	if not is_inside_tree():
		return

	_play_dead()
	await get_tree().create_timer(3.0).timeout

	if not is_inside_tree():
		return

	await _fade_out_then_free()

func _play_random_death_sfx() -> void:
	var death_sounds: Array[AudioStreamPlayer2D] = [sfx_death1, sfx_death2]
	var chosen := death_sounds[randi() % death_sounds.size()]
	chosen.play()

func _fade_out_then_free() -> void:
	var t: float = 0.0
	var start: Color = modulate

	while t < death_fade_time:
		if not is_inside_tree():
			return

		t += get_process_delta_time()
		var a: float = 1.0 - (t / death_fade_time)
		modulate = Color(start.r, start.g, start.b, a)

		await get_tree().process_frame

	queue_free()

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
	else:
		anim.play()

func _play_dead() -> void:
	anim.play("dead")
	anim.frame = 0
	anim.pause()
