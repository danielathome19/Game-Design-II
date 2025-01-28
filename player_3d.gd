extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const CAM_SENSITIVITY = 0.03
@onready var camera = $Head/Camera3D

var first_person = true


const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and \
	   Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if first_person == true:
			self.rotate_y(-event.relative.x * (CAM_SENSITIVITY / 10.0))
			camera.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	pass


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	move_and_slide()


func headbob(time):
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos
