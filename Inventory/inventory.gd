extends Resource

class_name Inventory

signal update

@export var slots: Array[InventorySlot]

func _ready() -> void:
	GameState.inventory = self # FOR BYPASS

func insert(item: InventoryItem):
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if not itemslots.is_empty():
		itemslots[0].amount += 1
	else:
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if not emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
	update.emit()

func clear() -> void:
	for slot in slots:
		slot.item = null
		slot.amount = 0
	update.emit()
