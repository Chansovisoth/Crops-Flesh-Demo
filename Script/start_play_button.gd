extends TextureButton

@export var next_scene: PackedScene
@export var world_environment: WorldEnvironment
@export var fade_duration: float = 3.0

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	disabled = true

	if world_environment == null or world_environment.environment == null:
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
		return

	var env := world_environment.environment
	var start_brightness := env.adjustment_brightness

	var tween := create_tween()
	tween.tween_property(env, "adjustment_brightness", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	if next_scene:
		get_tree().change_scene_to_packed(next_scene)

	env.adjustment_brightness = start_brightness
