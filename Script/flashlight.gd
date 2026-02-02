# flashlight.gd
# Attach to PointLight2D (triangle flashlight)

extends PointLight2D

@export_range(-180.0, 180.0, 1.0)
var offset_degree: float = -90

# Flicker defaults
@export var flicker_min_energy: float = 0.2
@export var flicker_max_energy: float = 1.0
@export var flicker_speed: float = 0.05

# Sequence tuning
@export var pre_flicker_duration: float = 0.35
@export var off_duration: float = 5.0
@export var post_flicker_duration: float = 0.45

var _is_flickering := false
var _flicker_timer := 0.0
var _flicker_duration := 0.0
var _base_energy: float

var _sequence_running := false
var _sequence_id := 0

func _ready() -> void:
	randomize()
	_base_energy = energy

func _process(delta: float) -> void:
	# --- ROTATE TO MOUSE ---
	if enabled:
		var mouse_pos := get_global_mouse_position()
		var dir := mouse_pos - global_position
		if dir.length_squared() > 0.0001:
			global_rotation = dir.angle() + deg_to_rad(offset_degree)

	# --- FLICKER UPDATE ---
	if _is_flickering:
		_flicker_timer -= delta
		if _flicker_timer <= 0.0:
			_flicker_timer = flicker_speed
			energy = randf_range(flicker_min_energy, flicker_max_energy)

		_flicker_duration -= delta
		if _flicker_duration <= 0.0:
			stop_flicker()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER:
				start_flicker(1.5) # DEBUG flicker
			KEY_BACKSLASH:
				run_flicker_off_on_sequence()

# =========================
# PUBLIC FLICKER API
# =========================

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

# ======================================
# SEQUENCE: flicker -> OFF -> flicker ON
# ======================================

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
