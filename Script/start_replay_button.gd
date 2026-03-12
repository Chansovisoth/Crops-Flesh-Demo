extends TextureButton

@export var next_scene: PackedScene
@onready var canvas_modulate: CanvasModulate = $"../../../../../CanvasModulate"

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	disabled = true

	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color.BLACK, 1)

	await tween.finished

	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
