# Script   : gun.gd
# Function : gun that follows user's cursor, can shoot out bullet.tscn

extends Node2D
 
 
const BULLET = preload("res://Scene/bullet.tscn")


@onready var muzzle: Marker2D = $Marker2D


func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1

func fire() -> void:
	if muzzle == null:
		return
	var bullet_instance = BULLET.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = rotation
