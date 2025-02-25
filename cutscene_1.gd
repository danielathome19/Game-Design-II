extends Node3D


func _ready() -> void:
	await get_tree().create_timer($AnimationPlayer.current_animation_length).timeout
	get_tree().quit()
	pass
