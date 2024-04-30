extends CharacterBody3D


const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.5
var SPEED = WALK_SPEED

const JUMP_VELOCITY = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const CAM_SENSITIVITY = 0.03
@onready var camera = $Head/Camera3D
@onready var camera_arm = $SpringArm3D
@onready var camera_pos = camera.position

@onready var BASE_FOV = camera.fov  # 75
var FOV_CHANGE = 1.0

# @onready var animator = $gobot/AnimationPlayer

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

var MAX_HEALTH = 100
var HEALTH = MAX_HEALTH
var damage_lock = 0.0  # Prevent infinite damage
var attack_lock = 0.0
var inertia = Vector3.ZERO

var MAX_STAMINA = 50.0
var STAMINA = MAX_STAMINA
@onready var staminabar = $playerhud3d/staminabar

var PUSH_FORCE = 25.0

var dmg_shader = preload("res://assets/shaders/take_damage.tres")
@onready var HUD = get_tree().get_first_node_in_group("HUD")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("sprint") and STAMINA > 0:
		SPEED = SPRINT_SPEED
		FOV_CHANGE = 2.0
		update_stamina(-5 * delta)
	else:
		SPEED = WALK_SPEED
		FOV_CHANGE = 1.0
		if STAMINA != MAX_STAMINA:
			update_stamina(5 * delta)
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		# if SPEED == WALK_SPEED:
		# 	animator.play("Walk")
		# else:
		# 	animator.play("Run")
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# animator.play("Idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	damage_lock = max(damage_lock-delta, 0.0)
	attack_lock = max(attack_lock-delta, 0.0)
	velocity += inertia
	inertia = inertia.move_toward(Vector3(), delta*1000.0)
	
	if Input.is_action_just_pressed("slash") and STAMINA > 0:  # Left click
		do_attack()
	
	if damage_lock == 0.0:
		HUD.dmg_overlay.material = null

	
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var c = get_slide_collision(i)
		var col = c.get_collider()
		if col is RigidBody3D and is_on_floor():
			col.apply_central_force(-c.get_normal() * PUSH_FORCE)
			# col.apply_central_impulse(-c.get_normal() * PUSH_FORCE)
	
	if self.global_position.y <= -50:
		take_damage(MAX_HEALTH)
	pass

func update_stamina(amount):
	STAMINA = clamp(STAMINA + amount, -10, MAX_STAMINA)
	staminabar.max_value = MAX_STAMINA
	staminabar.value = max(int(STAMINA), 0)
	if STAMINA <= 0:
		SPEED = WALK_SPEED
		FOV_CHANGE = 1.0

func update_healthbar():
	var healthbar: ProgressBar = HUD.healthbar
	healthbar.max_value = MAX_HEALTH
	healthbar.value = int(HEALTH)
	var old_style = healthbar.get_theme_stylebox("fill")
	var style = StyleBoxFlat.new() if old_style == null else old_style
	healthbar.add_theme_stylebox_override("fill", style)
	if HEALTH/float(MAX_HEALTH) <= 0.25:  # Health <= 25% full
		style.bg_color = Color(.5, 0, 0, 0.75)  # Dark Red
	else:
		style.bg_color = Color(1, 0, 0, 0.75)  # Red
	healthbar.force_update_transform()

func do_attack():
	if attack_lock == 0.0 and $Sword/CollisionTimer.is_stopped() and STAMINA > 0:
		update_stamina(-10)
		# Configure and animate the rotation
		var tween = get_tree().create_tween()
		tween.tween_property($Sword, "rotation_degrees:y", (90), 0.05) \
			 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property($Sword, "rotation_degrees:y", (0), 0.15) \
			 .set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		# tween.tween_property($Sword, "global_rotation_degrees:y", (0), 0.05) \
		# 	 .set_delay(0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack_lock = 0.2
		$Sword/CollisionTimer.start()
		tween.play()
		await tween.finished
		$Sword/CollisionTimer.stop()

func _on_collision_timer_timeout():
	# Check for collisions at each step of the tween animation
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if $Sword.overlaps_area(enemy.dmg_area):
			enemy.queue_free()  # TODO: replace with "enemy.take_damage(ATTACK)"
			# Enemy needs health and inertia variables, take_damage(dmg) function

func take_damage(dmg):
	if damage_lock == 0.0:
		damage_lock = 0.5
		HEALTH -= dmg
		update_healthbar()
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
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var parent = "SpringArm3D"
	var child = camera
	child.get_parent().remove_child(child)
	get_node(parent).add_child(child)
	camera = child
	camera.position = camera_pos
	update_healthbar()
	var stambarstyle = StyleBoxFlat.new()
	staminabar.add_theme_stylebox_override("fill", stambarstyle)
	stambarstyle.bg_color = Color(0, 0.67, 0.2, 0.75)
	staminabar.force_update_transform()
	update_stamina(0)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * (CAM_SENSITIVITY / 10.0))
		camera_arm.rotate_x(-event.relative.y * (CAM_SENSITIVITY / 10.0))
		camera_arm.rotation.x = clamp(camera_arm.rotation.x, deg_to_rad(-75), deg_to_rad(75))

