extends VehicleBody3D

const MAX_STEER = 0.4
const MAX_RPM = 150
const MAX_TORQUE = 500
const HORSE_POWER = 75
const REVERSE_POWER = -HORSE_POWER * 2  # -50
const STUCK_TIME_THRESHOLD = 0.5

var stuck_timer = 0.0
var is_stuck = false

@onready var rayF  = $rayForward    # y=0
@onready var rayFL = $rayForwLeft   # y=30
@onready var rayFR = $rayForwRight  # y=-30
@onready var rayL  = $rayLeft       # y=75
@onready var rayR  = $rayRight      # y=-75

func _physics_process(delta):
	pass


func check_stuck_condition(delta):
	if linear_velocity.length() < 1.0:
		stuck_timer += delta
	else:
		stuck_timer = 0
	is_stuck = stuck_timer > STUCK_TIME_THRESHOLD


func update_raycasts():
	rayF.force_raycast_update()
	rayFL.force_raycast_update()
	rayFR.force_raycast_update()
	rayL.force_raycast_update()
	rayR.force_raycast_update()


func calc_engine_force(accel, rpm):
	return accel * MAX_TORQUE * (1 - rpm / MAX_RPM)


func check_and_right_vehicle():
	if self.global_transform.basis.y.dot(Vector3.UP) < 0:
		var current_rotation = self.rotation_degrees
		current_rotation.x = 0  # Reset pitch
		current_rotation.z = 0  # Reset roll
		self.rotation_degrees = current_rotation
