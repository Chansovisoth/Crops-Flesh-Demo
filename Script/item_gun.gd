# Script   : item_gun.gd
# Function : Pickable gun item on ground

extends Node2D

@export var item: InventoryItem
@export var auto_equip_on_pickup: bool = false

@export var pickup_dialogue_resource: DialogueResource
@export var pickup_dialogue_start: String = "start"

@onready var pickable_area: Area2D = $PickableArea

var _picked := false

func _ready() -> void:
	if GameState.item_gun_taken:
		queue_free()
		return

	pickable_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _picked or GameState.item_gun_taken:
		return
	if not (body is Player):
		return
	if item == null:
		push_warning("ItemGun: 'item' is not assigned in Inspector.")
		return

	_picked = true
	GameState.item_gun_taken = true
	GameState.player_has_gun = true

	body.collect(item)

	if auto_equip_on_pickup and not body.gun_equipped:
		body.gun_toggle()

	await _play_pickup_dialogue(body)

	queue_free()

func _play_pickup_dialogue(player: Player) -> void:
	if pickup_dialogue_resource == null:
		return

	GameState.dialogue_active = true

	if player:
		player.sfx("writing")

	var balloon := DialogueManager.show_dialogue_balloon(
		pickup_dialogue_resource,
		pickup_dialogue_start
	)

	await balloon.tree_exited
	GameState.dialogue_active = false
