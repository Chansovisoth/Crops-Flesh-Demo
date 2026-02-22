extends Control

class_name InventoryUI

var is_open = false

func _ready():
	close()
	
func toggle() -> void:
	if is_open:
		close()
	else:
		open()
	print("inventoryui: is_open = ", is_open)
	return

func open():
	visible = true
	is_open = true

func close():
	visible = false
	is_open = false
