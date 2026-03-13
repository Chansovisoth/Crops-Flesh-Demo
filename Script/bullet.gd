# Script   : bullet.gd
# Function : Moves forward, damages zombies on hit, then disappears

extends Area2D

@export var SPEED: float = 550.0
@export var DAMAGE: int = 5
@export var LIFETIME: float = 2.0

var _direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_direction = Vector2.RIGHT.rotated(rotation)
	body_entered.connect(_on_body_entered)

	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("zombies") and body.has_method("hurt"):
		body.hurt(DAMAGE)
		queue_free()
