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
			# Connect hover signals to HBox handlers, to pass the button
			button.mouse_entered.connect(_on_btn_entered.bind(button))
			button.mouse_exited.connect(_on_btn_exited.bind(button))

func _on_btn_entered(button: TextureButton) -> void:
	button.self_modulate = HOVER_COLOR

func _on_btn_exited(button: TextureButton) -> void:
	button.self_modulate = NORMAL_COLOR
