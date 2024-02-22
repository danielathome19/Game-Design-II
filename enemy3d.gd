extends CharacterBody3D

@onready var dmg_area = $DamageArea
@onready var atk_area = $AttackArea
@onready var nav_agent = $NavigationAgent3D

var SPEED = 3.0
var ACCEL = 20
var ATTACK = 10
var knockback = 16.0

func _physics_process(delta):
	for player in get_tree().get_nodes_in_group("Player"):
		if $AttackRange.overlaps_body(player):
			nav_agent.target_position = player.global_position
		if atk_area.overlaps_body(player):
			player.take_damage(ATTACK)
			player.inertia = (player.global_position-global_position).normalized() * knockback
	var dir = (nav_agent.target_position - global_position).normalized()
	velocity = velocity.lerp(dir * SPEED, ACCEL * delta)
	move_and_slide()
