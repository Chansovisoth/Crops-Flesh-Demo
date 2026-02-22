# Script   : button_mute.gd
# Function : Button for muting BackgroundMusic

extends TextureButton
class_name MuteBackgroundMusic

@export var unmuted_normal: Texture2D = preload("res://Asset/Texture/GUI/tres/unmuted_normal.tres")
@export var unmuted_pressed: Texture2D = preload("res://Asset/Texture/GUI/tres/unmuted_pressed.tres")
@export var muted_normal: Texture2D = preload("res://Asset/Texture/GUI/tres/muted_normal.tres")
@export var muted_pressed: Texture2D = preload("res://Asset/Texture/GUI/tres/muted_pressed.tres")

func _ready() -> void:
	GameState.mute_changed.connect(_apply_state)
	_apply_state()

func _on_pressed() -> void:
	GameState.toggle_muted()
	print("button_mute: _on_pressed()")

func _apply_state() -> void:
	var is_muted := GameState.muted
	
	if is_muted:
		texture_normal  = muted_normal
		texture_hover   = muted_normal
		texture_pressed = muted_pressed
	else:
		texture_normal  = unmuted_normal
		texture_hover   = unmuted_normal
		texture_pressed = unmuted_pressed
