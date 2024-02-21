extends CharacterBody3D


const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.5
var SPEED = WALK_SPEED

const JUMP_VELOCITY = 7.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const CAM_SENSITIVITY = 0.03
@onready var camera = $Head/Camera3D
@onready var camera_arm = $SpringArm3D
@onready var camera_pos = camera.position
var first_person = true

@onready var BASE_FOV = camera.fov  # 75
var FOV_CHANGE = 1.0

@onready var model = $gobot
@onready var animator = $gobot/AnimationPlayer

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

var MAX_HEALTH = 50
var HEALTH = MAX_HEALTH
var damage_lock = 0.0  # Prevent infinite damage
var inertia = Vector3.ZERO

var dmg_shader = preload("res://assets/shaders/take_damage.tres")
@onready var HUD = get_tree().get_first_node_in_group("HUD")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("sprint"):
		SPEED = SPRINT_SPEED
		FOV_CHANGE = 2.0
	else:
		SPEED = WALK_SPEED
		FOV_CHANGE = 1.0
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if SPEED == WALK_SPEED:
			animator.play("Walk")
		else:
			animator.play("Run")
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		animator.play("Idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("change_camera"):
		toggle_camera_parent()  # V
	
	var rotate_dir = Input.get_vector("rot_left", "rot_right", 
									  "rot_up", "rot_down").normalized()
	if rotate_dir:
		self.rotation.x += rotate_dir.x / 100.0
		self.rotation.z += rotate_dir.y / 100.0
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if $Feet.overlaps_area(enemy.dmg_area):
			enemy.queue_free()
	damage_lock = max(damage_lock-delta, 0.0)
	velocity += inertia
	inertia = inertia.move_toward(Vector3(), delta*1000.0)
	
	if damage_lock == 0.0:
		HUD.dmg_overlay.material = null
	HUD.healthbar.max_value = MAX_HEALTH
	HUD.healthbar.value = int(HEALTH)
	
	move_and_slide()
	

func take_damage(dmg):
	if damage_lock == 0.0:
		damage_lock = 0.5
		HEALTH -= dmg
		var dmg_intensity = clamp(1.0-((HEALTH+0.01)/MAX_HEALTH), 0.1, 0.8)
		HUD.dmg_overlay.material = dmg_shader.duplicate()
		HUD.dmg_overlay.material.set_shader_parameter("intensity", dmg_intensity)
		if HEALTH <= 0:
			await get_tree().create_timer(0.25).timeout
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			OS.alert("You died!")
			get_tree().reload_current_scene()

func headbob(time):
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos

func toggle_camera_parent():
	var parent = "Head"
	if first_person:
		parent = "SpringArm3D"
		model.visible = true
	var child = camera
	child.get_parent().remove_child(child)
	get_node(parent).add_child(child)
	camera = child
	if not first_person:
		camera.position = camera_pos
		model.visible = false
	first_person = not first_person
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	model.visible = false

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if first_person:
			self.rotate_y(-event.relative.x * (CAM_SENSITIVITY / 10.0))
			camera.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		else:
			self.rotate_y(-event.relative.x * (CAM_SENSITIVITY / 10.0))
			camera_arm.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
			camera_arm.rotation.x = clamp(camera_arm.rotation.x, deg_to_rad(-75), deg_to_rad(75))


