extends Area3D

@export var next_level = ""
@onready var HUD = get_tree().get_first_node_in_group("HUD")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if next_level != "":
			var lvl = "res://" + next_level + ".tscn"
			HUD.popup.visible = true
			HUD.popup_label.text = "Loading..."
			await get_tree().create_timer(0.1).timeout
			get_tree().change_scene_to_file(lvl)
		else:
			OS.alert("No next level!")
	pass
