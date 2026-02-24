extends Panel

@onready var item_display: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var item_display_amount: Label = $CenterContainer/Panel/Label

func update(slot: InventorySlot):
	if !slot.item:
		item_display.visible = false
		item_display_amount.visible = false
	else:
		item_display.visible = true
		item_display.texture = slot.item.texture
		item_display_amount.visible = true
		item_display_amount.text = str(slot.amount)
