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

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5

@onready var audio_player = $AudioStreamPlayer3D
var hit_sound = preload("res://assets/sounds/hitHurt.wav")
var dink_sound = preload("res://assets/sounds/hitHead.wav")


func is_player_in_sight(player):
	var from_pos = self.global_transform.origin  # Starting point of raycast
	var to_pos = player.global_transform.origin  # Target point
	var direction = to_pos - from_pos
	var distance = direction.length()  # Distance to player
	
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from_pos
	ray_query.to = from_pos + direction.normalized() * distance
	ray_query.exclude = [get_rid()]  # Exclude self from query to avoid self-col
	
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	return result.size() != 0 and result.collider == player


func _physics_process(delta):
	for player in get_tree().get_nodes_in_group("Player"):
		if $AttackRange.overlaps_body(player) or is_player_in_sight(player):
			nav_agent.target_position = player.global_position
			$HuntTimer.start()
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
	
	$lblHealth.text = str(int(HEALTH)) + "/" + str(MAX_HEALTH)
	$lblHealth.rotation.y = dir.x
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
		if spawn_origin != null:
			if randi_range(0, 100) > 66.6:
				nav_agent.target_position = spawn_origin
				$HuntTimer.start()
		if audio_player.playing:
			await audio_player.finished
		audio_player.stream = dink_sound if headshot else hit_sound
		audio_player.play()


func _on_hunt_timer_timeout():
	nav_agent.target_position = Vector3.ZERO  # Or a random 3d vector
