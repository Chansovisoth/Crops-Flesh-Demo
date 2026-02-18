# Script   : button_mute.gd
# Function : Button for toggling background music

extends TextureButton
@onready var background_music: AudioStreamPlayer2D = $"../../../../../Map/YSort/Player/Audio/BackgroundMusic"

@export var unmuted_normal: Texture2D = preload("res://Asset/Texture/GUI/tres/unmuted_normal.tres")
@export var unmuted_pressed: Texture2D = preload("res://Asset/Texture/GUI/tres/unmuted_pressed.tres")
@export var muted_normal: Texture2D = preload("res://Asset/Texture/GUI/tres/muted_normal.tres")
@export var muted_pressed: Texture2D = preload("res://Asset/Texture/GUI/tres/muted_pressed.tres")

var muted := false

func _on_pressed() -> void:
	muted = !muted
	background_music.volume_db = -80 if muted else 0
	_apply_visual(true if muted else false)
	print("BUTTON: Background Music Toggled")
	
func _apply_visual(muted: bool) -> void:
	if muted:
		texture_normal  = muted_normal
		texture_hover   = muted_normal
		texture_pressed = muted_pressed
	else:
		texture_normal  = unmuted_normal
		texture_hover   = unmuted_normal
		texture_pressed = unmuted_pressed
