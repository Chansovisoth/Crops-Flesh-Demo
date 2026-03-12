# Script   : flashlight.gd
# Function : All the neat flashlight functionalities

extends PointLight2D

# ===== OFFSET =====
@export_range(-180.0, 180.0, 1.0)
var offset_degree: float = -90

# ===== FLICKER =====
@export var flicker_min_energy: float = 0.2
@export var flicker_max_energy: float = 1.0
@export var flicker_speed: float = 0.05
@export var pre_flicker_duration: float = 0.35
@export var off_duration: float = 5.0
@export var post_flicker_duration: float = 0.45

# ===== RANDOM EVENTS =====
@export var random_event_enabled: bool = true
@export var random_event_min_wait: float = 8.0  # every x to y second, random event plays
@export var random_event_max_wait: float = 20.0
@export_range(0.0, 1.0, 0.01)
var random_event_chance: float = 0.45

var _is_flickering := false
var _flicker_timer := 0.0
var _flicker_duration := 0.0
var _base_energy: float
var _sequence_running := false
var _sequence_id := 0
var _random_event_running := false

# ====================
# INPUTS
# ====================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SEMICOLON:
				start_flicker(1.5) # debug flicker
			KEY_BACKSLASH:
				run_flicker_off_on_sequence()

# ====================
# MAIN FUNCTIONS
# ====================
func _ready() -> void:
	randomize()
	_base_energy = energy
	random_event()

func _process(delta: float) -> void:
	var can_rotate := enabled and not (GameState.player != null and GameState.player._is_dead)

	if can_rotate:
		var mouse_pos := get_global_mouse_position()
		var dir := mouse_pos - global_position
		if dir.length_squared() > 0.0001:
			global_rotation = dir.angle() + deg_to_rad(offset_degree)

	# Flicker update
	if _is_flickering:
		_flicker_timer -= delta
		if _flicker_timer <= 0.0:
			_flicker_timer = flicker_speed
			energy = randf_range(flicker_min_energy, flicker_max_energy)

		_flicker_duration -= delta
		if _flicker_duration <= 0.0:
			stop_flicker()

# ====================
# OTHER
# ====================

# ===== RANDOM EVENT LOOP =====
func random_event() -> void:
	if _random_event_running:
		return

	_random_event_running = true
	_random_event_loop()

func _random_event_loop() -> void:
	while is_inside_tree():
		if not random_event_enabled:
			await get_tree().create_timer(1.0).timeout
			continue

		var wait_time := randf_range(random_event_min_wait, random_event_max_wait)
		await get_tree().create_timer(wait_time).timeout

		if not is_inside_tree():
			return

		if GameState.player != null and GameState.player._is_dead:
			continue

		if _sequence_running:
			continue

		if randf() > random_event_chance:
			continue

		if randi() % 2 == 0:
			start_flicker(1.5)
		else:
			run_flicker_off_on_sequence()

# ===== FLICKER CONTROLS =====
func start_flicker(
	duration: float,
	min_energy: float = flicker_min_energy,
	max_energy: float = flicker_max_energy,
	speed: float = flicker_speed
) -> void:
	_is_flickering = true
	_flicker_duration = duration
	_flicker_timer = 0.0

	flicker_min_energy = min_energy
	flicker_max_energy = max_energy
	flicker_speed = speed

func stop_flicker() -> void:
	_is_flickering = false
	energy = _base_energy

# ===== FLICKER SEQUENCE =====
func run_flicker_off_on_sequence() -> void:
	if _sequence_running:
		return

	_sequence_running = true
	_sequence_id += 1
	var my_id := _sequence_id

	_run_sequence_async(my_id)

func _run_sequence_async(my_id: int) -> void:
	# Pre-flicker
	start_flicker(pre_flicker_duration)
	await get_tree().create_timer(pre_flicker_duration).timeout
	if my_id != _sequence_id:
		return

	# OFF
	stop_flicker()
	enabled = false
	await get_tree().create_timer(off_duration).timeout
	if my_id != _sequence_id:
		return

	# ON + post-flicker
	enabled = true
	start_flicker(post_flicker_duration)
	await get_tree().create_timer(post_flicker_duration).timeout
	if my_id != _sequence_id:
		return

	stop_flicker()
	_sequence_running = false
