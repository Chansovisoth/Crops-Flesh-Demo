extends WorldEnvironment

class_name WorldEnv

@export var fade_speed: float = 10.0
@export var black_exposure: float = 0.0

# -INF means we get the current exposure from inspector value.
@export var normal_exposure: float = -INF

var _default_exposure: float
var target_exposure: float


func _ready() -> void:
	if environment == null:
		return
	# Avoid editing a shared Environment resource
	environment = environment.duplicate(true)
	_default_exposure = environment.tonemap_exposure if normal_exposure == -INF else normal_exposure
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


func fade_sleep() -> void:
	if environment == null:
		return

	# ===== Local var =====
	var blink_low_exposure: float = 0.25
	var blink_pause: float = 0.06
	var between_blinks_pause: float = 0.08
	var fall_sleep_hold: float = 0.10
	var fall_sleep_speed_mult: float = 0.45
	var threshold: float = 0.02
	var normal_expo := _default_exposure
	var old_speed := fade_speed

	# Blink 1: current -> low
	target_exposure = blink_low_exposure
	while absf(environment.tonemap_exposure - target_exposure) > threshold:
		await get_tree().process_frame
	await get_tree().create_timer(blink_pause).timeout

	# Blink open: low -> normal
	target_exposure = normal_expo
	while absf(environment.tonemap_exposure - target_exposure) > threshold:
		await get_tree().process_frame
	await get_tree().create_timer(fall_sleep_hold).timeout

	# Fall asleep: normal -> black (slow)
	fade_speed = old_speed * fall_sleep_speed_mult
	target_exposure = black_exposure
	while absf(environment.tonemap_exposure - target_exposure) > threshold:
		await get_tree().process_frame
	fade_speed = old_speed

	# Stay black for 3 seconds
	await get_tree().create_timer(3.0).timeout

	# Wake up: black -> normal
	target_exposure = normal_expo
	while absf(environment.tonemap_exposure - target_exposure) > threshold:
		await get_tree().process_frame
