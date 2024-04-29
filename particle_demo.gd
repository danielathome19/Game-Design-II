extends Node3D


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		$fire_particle.visible = not $fire_particle.visible
	pass
