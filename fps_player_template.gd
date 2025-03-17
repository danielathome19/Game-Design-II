extends CharacterBody3D


var SPEED = 7.0
var NORMAL_SPEED = SPEED
var WALK_SPEED = 4.0
var JUMP_VELOCITY = 7.0

var MAX_HEALTH = 100
var HEALTH = MAX_HEALTH
var damage_lock = 0.0  # Prevent infinite damage
var inertia = Vector3()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5


@onready var camera = $Head/Camera3D
var CAM_SENSITIVITY = 0.02
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0


var damage_shader = preload("res://assets/shaders/take_damage.tres")
@onready var head = $Head

var blaster
var muzzle
var old_blaster_y
var dart_scene = preload("res://fps_dart.tscn")

var spray_lock = 0.0  # Prevent infinite spray
var NORMAL_SPRAY_AMOUNT = 0.03
var CROUCH_SPRAY_AMOUNT = 0.01
var SPRAY_AMOUNT = NORMAL_SPRAY_AMOUNT
var FIRING_DELAY = 0.075
var ATTACK = 5.0

var CLIP_SIZE = 30
var AMMO = CLIP_SIZE
var TOTAL_AMMO = 150
var is_reloading = false

var NORMAL_HEIGHT = 2.0
var CROUCH_HEIGHT = 1.25
var NORMAL_COLLISION_RAD = 0.5
var CROUCH_COLLISION_RAD = 0.8
var NORMAL_HEAD = 0.8
var CROUCH_HEAD = 0.4


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("walk") or Input.is_action_pressed("crouch"):
		SPEED = WALK_SPEED
	else:
		SPEED = NORMAL_SPEED
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	var hbob = headbob(t_bob)
	camera.transform.origin = hbob
	
	damage_lock = max(damage_lock-delta, 0.0)
	velocity += inertia
	inertia = inertia.move_toward(Vector3(), delta * 1000.0)
	
	if Input.is_action_pressed("fire"):
		do_fire()
	spray_lock = max(spray_lock - delta, 0.0)
	
	if Input.is_action_just_pressed("reload") or \
	  (Input.is_action_just_pressed("fire") and AMMO == 0):
		if TOTAL_AMMO > 0 and not is_reloading and AMMO != CLIP_SIZE:
			is_reloading = true
			# TODO: play sound
			await get_tree().create_timer(2).timeout
			var ammo_needed = CLIP_SIZE - AMMO
			var new_ammo = min(ammo_needed, TOTAL_AMMO)
			AMMO += new_ammo
			TOTAL_AMMO -= new_ammo
			is_reloading = false
	
	# TODO: HUD stuff
	# TODO: aiming down sight
	
	if Input.is_action_pressed("crouch"):
		$CollisionShape3D.shape.height = CROUCH_HEIGHT + 0.05
		$CollisionShape3D.shape.radius = CROUCH_COLLISION_RAD
		$MeshInstance3D.scale.y = CROUCH_HEIGHT/NORMAL_HEIGHT
		$Head.position.y = lerp($Head.position.y, CROUCH_HEAD, delta*5.0)
		SPRAY_AMOUNT = CROUCH_SPRAY_AMOUNT
	if Input.is_action_just_released("crouch"):
		$CollisionShape3D.shape.height = NORMAL_HEIGHT
		$CollisionShape3D.shape.radius = NORMAL_COLLISION_RAD
		$MeshInstance3D.scale.y = 1.0
		$Head.position.y = lerp($Head.position.y, NORMAL_HEAD, delta*5.0)
		SPRAY_AMOUNT = NORMAL_SPRAY_AMOUNT
	
	move_and_slide()
	
	if int(HEALTH) <= 0:
		HEALTH = 0
		await get_tree().create_timer(0.25).timeout
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		OS.alert("You died!")
		get_tree().reload_current_scene()
	
	if len(get_tree().get_nodes_in_group("Enemy")) <= 0:
		await get_tree().create_timer(0.25).timeout
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		OS.alert("You win!")
		# TODO: change scene
		get_tree().quit()
	
	# Right Joystick
	var joystick_index = 0
	var deadzone = 0.1
	var rstick_h = Input.get_joy_axis(joystick_index, JOY_AXIS_RIGHT_X)
	var rstick_v = Input.get_joy_axis(joystick_index, JOY_AXIS_RIGHT_Y)
	
	if abs(rstick_h) > deadzone:
		self.rotate_y(-rstick_h * delta * (CAM_SENSITIVITY*75))
	if abs(rstick_v) > deadzone:
		camera.rotate_x(-rstick_v * delta * (CAM_SENSITIVITY*75))
	
	pass


func take_damage(dmg, override=false, headshot=false, _spawn_origin=null):
	if damage_lock == 0.0 or override:
		damage_lock = 0.5
		HEALTH -= dmg
		var dmg_intensity = clamp(1.0-((HEALTH+0.01)/MAX_HEALTH), 0.1, 0.8)
		# TODO: uncomment
		#$HUD/overlay.material = damage_shader.duplicate()
		#$HUD/overlay.material.set_shader_parameter("intensity", dmg_intensity)
		# TODO: play sound


func headbob(time):
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQ / 2) * (BOB_AMP/2.0)
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	blaster = $Head/Camera3D/blaster
	muzzle = $Head/Camera3D/blaster/muzzle
	old_blaster_y = blaster.position.y


func do_fire():
	if spray_lock == 0.0 and AMMO > 0:
		var dart = dart_scene.instantiate()
		add_child(dart)
		var spray = SPRAY_AMOUNT
		if not is_on_floor():
			spray *= randf_range(1.5, 5)
		dart.do_fire(camera, muzzle, spray, ATTACK)
		AMMO -= 1
		spray_lock = FIRING_DELAY


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * (CAM_SENSITIVITY / 10.0))
		camera.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-75), deg_to_rad(75))
