extends CharacterBody3D

@onready var dmg_area = $DamageArea
@onready var atk_area = $AttackArea
@onready var nav_agent = $NavigationAgent3D
@onready var head = $DamageArea

var SPEED = 3.0
var ACCEL = 20
var ATTACK = 10
var knockback = 16.0

var MAX_HEALTH = 100
var HEALTH = MAX_HEALTH

@onready var muzzle = $blaster/muzzle
var dart_scene = preload("res://fps_dart.tscn")
var spray_lock = 0.0
var SPRAY_AMOUNT = 0.08  # 0.03

# TODO: audio

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5

func is_player_in_sight(player):
	# TODO
	return true

func _physics_process(delta):
	for player in get_tree().get_nodes_in_group("Player"):
		if $AttackRange.overlaps_body(player) or is_player_in_sight(player):
			nav_agent.target_position = player.global_position
			# TODO: hunt timer
			if spray_lock == 0.0 and is_player_in_sight(player):
				var dart = dart_scene.instantiate()
				add_child(dart)
				dart.do_fire($Camera3D, muzzle, SPRAY_AMOUNT, ATTACK)
				spray_lock = 0.2
	spray_lock = max(spray_lock - delta, 0.0)
	var dir = (nav_agent.target_position - global_position).normalized()
	velocity = velocity.lerp(dir * SPEED, ACCEL * delta)
	if nav_agent.target_position == Vector3.ZERO:
		velocity = Vector3.ZERO
	
	# TODO: health label
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
		# TODO: nav
		# TODO: sound
