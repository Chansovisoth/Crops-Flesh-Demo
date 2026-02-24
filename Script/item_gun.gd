# Script   : item_gun.gd
# Function : Pickable gun item on ground

extends Node2D

@export var item: InventoryItem
@export var auto_equip_on_pickup: bool = true

@onready var pickable_area: Area2D = $PickableArea

var _picked := false

func _ready() -> void:
	# If already taken in this save/state, remove it immediately
	if GameState.item_gun_taken:
		queue_free()
		return

	pickable_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Prevent double pickup + prevent pickup if GameState already says taken
	if _picked or GameState.item_gun_taken:
		return
	if not (body is Player):
		return
	if item == null:
		push_warning("ItemGun: 'item' is not assigned in Inspector.")
		return

	_picked = true
	GameState.item_gun_taken = true

	body.collect(item)

	if auto_equip_on_pickup and body.gun_equipped == false:
		body.gun_toggle()

	queue_free()
