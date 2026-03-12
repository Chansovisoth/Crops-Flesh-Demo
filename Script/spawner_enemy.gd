# Script   : spawner_enemy.gd
# Function : spawns selected enemies (can be selected from Inspector panel)

extends Node2D

#@export var enemy_scene: PackedScene = preload("res://Scene/enemy.tscn")
@export var enemy_scene: PackedScene

@export var spawn_radius: float = 100.0
@export var spawn_interval: float = 2.0

# Set to 0 or less for unlimited spawning
@export var max_spawn_count: int = 10

# Optional: auto start spawning
@export var auto_start: bool = true

var _spawned_count: int = 0
var _timer: Timer


func _ready() -> void:
	randomize()

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_timer)

	if auto_start:
		start_spawning()


func start_spawning() -> void:
	if _has_reached_max():
		return

	_timer.wait_time = spawn_interval
	_timer.start()


func stop_spawning() -> void:
	if _timer:
		_timer.stop()


func spawn_enemy() -> Node2D:
	if enemy_scene == null:
		push_warning("Spawner: enemy_scene is not assigned.")
		return null

	if _has_reached_max():
		stop_spawning()
		return null

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		push_warning("Spawner: instantiated scene is not a Node2D.")
		return null

	var spawn_position := global_position + _get_random_point_in_radius()

	# Add to parent (../)
	get_parent().add_child(enemy)

	# Set position AFTER adding (safer with YSort)
	enemy.global_position = spawn_position

	_spawned_count += 1

	if _has_reached_max():
		stop_spawning()

	return enemy


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()


func _get_random_point_in_radius() -> Vector2:
	var angle := randf() * TAU
	var distance := sqrt(randf()) * spawn_radius
	return Vector2(cos(angle), sin(angle)) * distance


func _has_reached_max() -> bool:
	return max_spawn_count > 0 and _spawned_count >= max_spawn_count
