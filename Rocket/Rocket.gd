extends RigidBody3D

const DESCENT_VECTOR = Vector3(0,-2,1)
# const ROTATION_CORRECTION_POWER = 100000
var desired_position = Vector3(0,0,0) #change this to be per-missile. Also is updated to current pos while the player is controlling it
const POSITION_CORRECTION_POWER = 10000
const MAX_FLOATING_VELOCITY = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	correct_rotation(delta)
	correct_position(delta)
	pass

func correct_rotation(delta):
	# https://forum.godotengine.org/t/how-to-find-a-torque-to-rotate-an-object-towards-a-desired-rotation/13914/2
	# Rotate towards desired angle
	# var desired_transform = transform.looking_at(position + DESCENT_VECTOR)
	# var torque_vector = transform.basis.z.cross(desired_transform.basis.z)
	# print(torque_vector)
	# apply_torque(ROTATION_CORRECTION_POWER * delta * torque_vector)

	# Non-physics easy mode
	look_at(position + DESCENT_VECTOR)

func correct_position(delta):
	var direction = desired_position - position
	var distance_squared = position.distance_squared_to(desired_position)
	# print(direction)
	apply_central_force(direction * delta * POSITION_CORRECTION_POWER * distance_squared)
	# currently does not push other rigidbodies

	# add a conditional here for when the rocket is launched
	if linear_velocity.length() > MAX_FLOATING_VELOCITY:
		linear_velocity = linear_velocity.normalized() * MAX_FLOATING_VELOCITY