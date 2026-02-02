# Script   : filter.gd
# Function : Fade-in & fade-out

extends WorldEnvironment

var fade_speed := 10
var target_exposure := 1.0

func _process(delta: float) -> void:
	# Prevent crashes during scene reload 
	if environment == null:
		return
	
	var env := environment
	env.tonemap_exposure = lerp(
		env.tonemap_exposure,
		target_exposure,
		delta * fade_speed
	)

func fade_in() -> void:
	target_exposure = 1.0

func fade_out() -> void:
	target_exposure = 0.0
