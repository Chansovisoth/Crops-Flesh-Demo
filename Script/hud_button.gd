# Script   : hud_button.gd
# Function : For modulating buttons (children), turn them green

extends HBoxContainer

const HOVER_COLOR := Color(0.4, 1.0, 0.4)
const NORMAL_COLOR := Color.WHITE

func _ready() -> void:
	for child in get_children():
		
		if child is TextureButton:
			var button := child as TextureButton
			button.self_modulate = NORMAL_COLOR
			button.mouse_entered.connect(_on_btn_entered.bind(button))
			button.mouse_exited.connect(_on_btn_exited.bind(button))

func _on_btn_entered(button: TextureButton) -> void:
	print("hud_button: _on_btn_entered()")
	button.self_modulate = HOVER_COLOR

func _on_btn_exited(button: TextureButton) -> void:
	print("hud_button: _on_btn_exited()")
	button.self_modulate = NORMAL_COLOR
