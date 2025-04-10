extends VehicleBody3D

const MAX_STEER = 0.4
const MAX_RPM = 400
const MAX_TORQUE = 200
const HORSE_POWER = 200

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func calc_engine_force(accel, rpm):
	return accel * MAX_TORQUE * (1 - rpm / MAX_RPM)

func _physics_process(delta: float) -> void:
	steering = lerp(steering,
					Input.get_axis("ui_right", "ui_left") * MAX_STEER,
					delta * 5.0)
	var accel = Input.get_axis("ui_down", "ui_up") * HORSE_POWER
	$backLeft.engine_force = calc_engine_force(accel, abs($backLeft.get_rpm()))
	$backRight.engine_force = calc_engine_force(accel, abs($backRight.get_rpm()))
	
	var fwd_mps = abs((linear_velocity * transform.basis).z)
	$Label.text = "%d mph" % (fwd_mps * 2.23694)
	
	$centerMass.global_position = $centerMass.global_position.lerp(
											   global_position, delta * 20.0)
	$centerMass.transform = $centerMass.transform.interpolate_with(
										 transform, delta * 5.0)
	$centerMass/Camera3D.look_at(global_position.lerp(
								  global_position + linear_velocity, delta * 5.0))
	check_and_right()

func check_and_right():
	if global_transform.basis.y.dot(Vector3.UP) < 0:
		var cur_rotation = self.rotation_degrees
		cur_rotation.x = 0  # Reset pitch
		cur_rotation.z = 0  # Reset roll
		self.rotation_degrees = cur_rotation
