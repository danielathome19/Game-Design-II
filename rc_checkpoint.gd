extends Area3D

@export var checkpoint_index: int = 0

func _on_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D and body.is_in_group("Player"):
		var i = checkpoint_index
		body.checkpoints[i] = true
		if i == len(body.checkpoints)-1 and \
		   body.checkpoints[len(body.checkpoints)-2] == true:
			body.do_lap()
