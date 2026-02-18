# filter.gd
extends WorldEnvironment

@export var fade_speed: float = 10.0
@export var black_exposure: float = 0.0

# If left at -INF, we read the current (inspector) exposure on startup.
@export var normal_exposure: float = -INF

var _default_exposure: float
var target_exposure: float

func _ready() -> void:
	if environment == null:
		return

	# IMPORTANT: avoid editing a shared Environment resource (prevents "stays black after restart")
	environment = environment.duplicate(true)

	# Capture the "normal" exposure from the duplicated resource (or override via export)
	_default_exposure = environment.tonemap_exposure if normal_exposure == -INF else normal_exposure

	# Start from black, then fade in
	set_black()
	await get_tree().create_timer(0.4).timeout
	fade_in()

func _process(delta: float) -> void:
	if environment == null:
		return

	environment.tonemap_exposure = lerp(
		environment.tonemap_exposure,
		target_exposure,
		delta * fade_speed
	)

func fade_in() -> void:
	target_exposure = _default_exposure

func fade_out() -> void:
	target_exposure = black_exposure

func set_black() -> void:
	environment.tonemap_exposure = black_exposure
	target_exposure = black_exposure
