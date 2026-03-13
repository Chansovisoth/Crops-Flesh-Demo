extends Node2D

@export var float_distance: float = 700.0
@export var float_duration: float = 4.0

@export var fade_duration: float = 3.0
@export var fade_delay: float = 0.5

@export var bob_distance: float = 20.0
@export var bob_duration: float = 2.0

@export var world_environment: WorldEnvironment

var _target_position: Vector2
var _target_brightness: float = 1.0

func _ready() -> void:
	_target_position = position
	position.y += float_distance

	if world_environment and world_environment.environment:
		_target_brightness = world_environment.environment.adjustment_brightness
		world_environment.environment.adjustment_brightness = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position", _target_position, float_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	if world_environment and world_environment.environment:
		tween.tween_property(
			world_environment.environment,
			"adjustment_brightness",
			_target_brightness,
			fade_duration
		)\
		.set_delay(fade_delay)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished
	_start_idle_float()

func _process(_delta: float) -> void:
	position = position.round()

func _start_idle_float() -> void:
	var base_pos := position

	var bob := create_tween()
	bob.set_loops()

	bob.tween_property(self, "position:y", base_pos.y + bob_distance, bob_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	bob.tween_property(self, "position:y", base_pos.y - bob_distance, bob_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
