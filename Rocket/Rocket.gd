extends RigidBody3D

const DESCENT_VECTOR = Vector3(0,-2,1)
@onready var look_direction = DESCENT_VECTOR
# const ROTATION_CORRECTION_POWER = 100000
@onready var desired_position = Vector3(0,0,0) #change this to be per-missile. Also is updated to current pos while the player is controlling it
const POSITION_CORRECTION_POWER = 10000
const MAX_FLOATING_VELOCITY = 10

# State Machine
enum RocketState {FLOATING, MOUNTED, FIRED, EXPLODING, DISABLED}
@onready var PLAYER = null
@onready var state = RocketState.FLOATING

# Movement Variables
@export_group("Mounted Movement")
@export var mounted_movement_force = 10000
@export var mounted_movement_drag = 0.01
@export var auto_course_stabilization_threshold = 1
const DRAG_DELTA_MULTIPLIER = 50

@export_group("Fired Movement")
@export var fired_impulse = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	if(state == RocketState.FIRED):
		fired_movement(delta)
	else:
		correct_rotation(delta)
		correct_position(delta)

func correct_rotation(delta):
	# https://forum.godotengine.org/t/how-to-find-a-torque-to-rotate-an-object-towards-a-desired-rotation/13914/2
	# Rotate towards desired angle
	# var desired_transform = transform.looking_at(position + DESCENT_VECTOR)
	# var torque_vector = transform.basis.z.cross(desired_transform.basis.z)
	# print(torque_vector)
	# apply_torque(ROTATION_CORRECTION_POWER * delta * torque_vector)

	# Non-physics easy mode
	# Change rotation to slightly point in direction of movement
	# Create 2d shadow of velocity vector excluding forward and backward movement
	var direction_delta = Vector3(-linear_velocity.x, -linear_velocity.y - linear_velocity.z/2, 0) * 0.1

	# Change look direction by the delta
	look_direction = DESCENT_VECTOR + direction_delta

	# Apply look
	look_at(position + look_direction)

func correct_position(delta):
	var direction = desired_position - position
	var distance_squared = position.distance_squared_to(desired_position)
	# print(direction)
	apply_central_force(direction * delta * POSITION_CORRECTION_POWER * distance_squared)
	# currently does not push other rigidbodies

	# add a conditional here for when the rocket is launched
	if linear_velocity.length() > MAX_FLOATING_VELOCITY:
		linear_velocity = linear_velocity.normalized() * MAX_FLOATING_VELOCITY

func fired_movement(delta):
	print("%s is fired, vel = %s"%[name, linear_velocity])
	apply_central_impulse(basis.y * fired_impulse * delta)

func player_mount(status):
	if(status):
		state = RocketState.MOUNTED
	else:
		state = RocketState.FLOATING

# This function is called by the player script while the player is mounted to a rocket
# This function is called in a phys_process and input_vector is normalized
func mounted_input_movement(input_vector, delta):
	# Apply force
	apply_central_force(input_vector * POSITION_CORRECTION_POWER)

	# Apply linear drag if above a certain speed
	var delta_drag = 1 - (mounted_movement_drag * delta * DRAG_DELTA_MULTIPLIER) # No idea if this is the right way to influence drag with delta.
	linear_velocity *= delta_drag if linear_velocity.length() > auto_course_stabilization_threshold else 1.0

	# Update desired position if necessary
	if linear_velocity.length() > auto_course_stabilization_threshold:
			desired_position = position

# This function is called by the player after arming and releasing the rocket to be fired
func fire():
	state = RocketState.FIRED
	
	# look at crosshair before firing, not yet implemented
	lock_rotation = true