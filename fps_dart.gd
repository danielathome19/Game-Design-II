extends RigidBody3D

var ATTACK = 5
var ATTACK_CRIT = 2 * ATTACK
var SPEED = 50
var DROP = 0.001
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * DROP
var spawn_origin: Vector3

# TODO: audio stuff

func _ready():
	$Timer.start()
	spawn_origin = self.global_position

func _on_timer_timeout() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	linear_velocity.y -= gravity * delta
	do_damage("Player")
	do_damage("Enemy")

func do_damage(group):
	var crit = max(0, randf_range(-ATTACK_CRIT, ATTACK_CRIT))
	for entity in get_tree().get_nodes_in_group(group):
		if entity != get_parent():
			if $Area3D.overlaps_area(entity.head):
				entity.take_damage(ATTACK*2.5 + crit, true, true, spawn_origin)
			if $Area3D.overlaps_body(entity):
				entity.take_damage(ATTACK + crit, true, false, spawn_origin)

func do_fire(camera, muzzle, spray_amount, attack=ATTACK):
	ATTACK = attack
	ATTACK_CRIT = 2*ATTACK
	var cam_forward = camera.global_transform.basis.z.normalized()
	var rnd_x = randf_range(-1, 1) * spray_amount
	var rnd_y = randf_range(-1, 1) * spray_amount
	var spray_dir = cam_forward + camera.global_transform.basis.x * rnd_x + \
								   camera.global_transform.basis.y * rnd_y
	self.global_transform.origin = muzzle.global_transform.origin
	self.linear_velocity = -spray_dir.normalized() * SPEED
