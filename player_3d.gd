extends CharacterBody3D


const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.5
var SPEED = WALK_SPEED
const JUMP_VELOCITY = 7.0

const CAM_SENSITIVITY = 0.03
@onready var camera = $Head/Camera3D
@onready var camera_arm = $SpringArm3D
@onready var camera_pos = camera.position
var first_person = true

@onready var BASE_FOV = camera.fov
var FOV_CHANGE = 1.0

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and \
	   Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * (CAM_SENSITIVITY / 10.0))
		if first_person == true:
			camera.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
			camera.rotation.x = clamp(camera.rotation.x, 
									  deg_to_rad(-40), 
									  deg_to_rad(60))
		else:
			camera_arm.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
			camera_arm.rotation.x = clamp(camera_arm.rotation.x, 
										  deg_to_rad(-75), 
										  deg_to_rad(75))
	pass


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("change_camera"):  # V
		toggle_camera_parent()
	
	if Input.is_action_pressed("sprint"):
		SPEED = SPRINT_SPEED
		FOV_CHANGE = 2.0
	else:
		SPEED = WALK_SPEED
		FOV_CHANGE = 1.0
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		# TODO: walk/run animation
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	move_and_slide()


func toggle_camera_parent():
	var parent = "Head"
	if first_person:
		parent = "SpringArm3D"
		# TODO: model visible
	var child = camera
	child.get_parent().remove_child(child)
	get_node(parent).add_child(child)
	camera = child
	if not first_person:
		camera.position = camera_pos
		# TODO: model invisible
	first_person = not first_person


func headbob(time):
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos
