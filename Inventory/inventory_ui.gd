extends Control

class_name InventoryUI 

@onready var inventory: Inventory = preload("res://Inventory/inventory_player1.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()

var is_open = false

func _ready():
	inventory.update.connect(update_slots) # will call update_slots() everytime inventory gets updated
	update_slots()
	close()

func update_slots():
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].update(inventory.slots[i])

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
