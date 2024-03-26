extends CharacterBody3D

@onready var dmg_area = $DamageArea
@onready var atk_area = $AttackArea
@onready var nav_agent = $NavigationAgent3D

var SPEED = 3.0
var ACCEL = 20
var ATTACK = 10
var knockback = 16.0

var MAX_HEALTH = 100
var HEALTH = MAX_HEALTH


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5


func _physics_process(delta):
	for player in get_tree().get_nodes_in_group("Player"):
		if $AttackRange.overlaps_body(player):  # TODO: player in sight
			nav_agent.target_position = player.global_position
			
	var dir = (nav_agent.target_position - global_position).normalized()
	velocity = velocity.lerp(dir * SPEED, ACCEL * delta)
	if nav_agent.target_position == Vector3.ZERO:
		velocity = Vector3.ZERO
	
	if dir != Vector3.ZERO:
		var angle_to_dir = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, angle_to_dir, 0.1)
	if not is_on_floor():
		velocity.y -= gravity * 100 * delta
	move_and_slide()
	
	if int(HEALTH) <= 0:
		self.queue_free()


func take_damage(dmg, override=false, headshot=false, spawn_origin=null):
	if override:
		HEALTH -= dmg
