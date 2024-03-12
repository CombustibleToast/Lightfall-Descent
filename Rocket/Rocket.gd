extends RigidBody3D

class_name Rocket

@onready var object_manager:ObjectManager = $".."

# State Machine
enum RocketState {FLOATING, MOUNTED, PRE_FIRE, FIRED, STUCK_IN_TARGET, EXPLODING, DISABLED}
@onready var PLAYER = null
@onready var state = RocketState.FLOATING
@onready var is_big_rocket = false

# Movement Variables
# Floating
const DESCENT_VECTOR = Vector3(0,0,-1) * 2
@onready var look_direction = DESCENT_VECTOR
@onready var desired_position = Vector3(0,0,0) #change this to be per-missile. Also is updated to current pos while the player is controlling it
const POSITION_CORRECTION_POWER = 10000
const MAX_FLOATING_VELOCITY = 10
# Mounted
@export_group("Mounted Movement")
@export var mounted_movement_force = 10000
@export var mounted_movement_drag = 0.01
@export var auto_course_stabilization_threshold = 1
const DRAG_DELTA_MULTIPLIER = 50
# Fired
@export_group("Fired Movement")
@export var fired_impulse = 10000
@export var fired_acceleration = 25.0
@onready var current_fired_velocity = -10 # for initial rocket pushback
@export var stage_1_timeout = 1
@onready var time_fired = 0
@onready var big_rocket_target = null

# Enemy Variables
@onready var hit_enemy:Enemy = null
@export var fuse_time = 2
@onready var remaining_fuse_time = fuse_time
@export var damage = 1
@onready var stored_targeting_reticle = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match state:
		RocketState.STUCK_IN_TARGET:
			if is_big_rocket:
				fuse_countdown(delta)
		_:
			pass


func _physics_process(delta):
	match state:
		RocketState.FIRED: 
			fired_movement(delta)
		RocketState.STUCK_IN_TARGET: 
			stick_in_enemy()
		RocketState.PRE_FIRE:
			pass
		_:
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
	var direction_delta = Vector3(linear_velocity.x, linear_velocity.y + linear_velocity.z/2, 0) * 0.1

	# Change look direction by the delta
	look_direction = DESCENT_VECTOR + direction_delta

	# Apply look
	look_at(position + look_direction)

func correct_position(delta):
	var direction = desired_position - position
	var distance_squared = position.distance_squared_to(desired_position)

	apply_central_force(direction * delta * POSITION_CORRECTION_POWER * distance_squared)
	# currently does not push other rigidbodies

	# add a conditional here for when the rocket is launched
	if linear_velocity.length() > MAX_FLOATING_VELOCITY:
		linear_velocity = linear_velocity.normalized() * MAX_FLOATING_VELOCITY
	
	# Occasionally nudge the rocket in a random direction to keep up pid wobble
	if randi() % 1000 == 69:
		apply_central_impulse(Vector3(randf(), randf(), randf()).normalized() * 5000)

## Player Interaction

func fired_movement(delta):
	# Point at target
	# TODO: make this a smooth/lerp'd function
	if not is_big_rocket and stored_targeting_reticle.stuck_on_target:
		look_at(stored_targeting_reticle.global_position)

	if is_big_rocket:
		look_at(big_rocket_target.global_position)

	# Move in direction of pointing
	# Just setting the velocity to match rotation exactly. Don't want the player to have to deal with weird things like the rocket orbiting the target.
	# That happens when just applying impulse
	# apply_central_impulse(-basis.z * fired_impulse * delta)
	current_fired_velocity += (fired_acceleration if time_fired < stage_1_timeout else (fired_acceleration * 10)) * delta
	linear_velocity = -basis.z * current_fired_velocity

	# Update firing time
	time_fired += delta

func player_mount(status:bool):
	if(status):
		state = RocketState.MOUNTED
	else:
		state = RocketState.FLOATING
	
	# Push the rocket down with a single impulse
	# apply_impulse(Vector3(0,0,1000), PLAYER.position)

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

# This function is called when the player begins to fire the rocket
func pre_fire(targeting_reticle:TargetingReticle):
	# Set state to prepare for firing
	state = RocketState.PRE_FIRE

	# Store targeting reticle to guide rocket during firing
	stored_targeting_reticle = targeting_reticle

	# Lock rotation so no jank physics stuff happens
	lock_rotation = true

# This function is called by the player after arming and releasing the rocket to be fired
func fire():
	# Update state
	state = RocketState.FIRED

	# Disable Interaction Collider
	$"Interaction Area/CollisionShape3D".disabled = true

## Enemy Collision

func _on_enemy_collision_area_area_entered(area:Area3D):
	var other = area.get_parent()
	# print("%s has areaEntered with %s"%[name, other.name])
	if other.is_in_group("enemies"):
		enemy_hit(other)

func enemy_hit(enemy:Enemy):
	# Wait one frame before applying effects. This is to let the rocket dig in a little and impart its momentum to the target
	# Doesn't work, just going to have the enemy be pushed back by the rocket in code. L
	# await get_tree().process_frame
	# await get_tree().process_frame
	
	# Disable own collider to prevent infinite recalls
	$"Enemy Collision Area/CollisionShape3D".disabled = true

	# Disable physics collider to avoid jank
	$"CollisionShape3D".disabled = true

	# Deactivate targeting reticle for reuse
	if stored_targeting_reticle:
		stored_targeting_reticle.deactivate()
		stored_targeting_reticle = null # just in case

	# Also call in big rocket if small and big rocket is available
	print("%s is small (%s) and the enemy has a big rocket inbound (%s)"%[name, is_big_rocket, enemy.big_rocket_inbound])
	if not is_big_rocket and not enemy.big_rocket_inbound:
		object_manager.spawn_big_rocket(enemy)

	# Update state
	state = RocketState.STUCK_IN_TARGET
	hit_enemy = enemy

	# Inform the enemy that it's been hit
	enemy.hit_by_rocket(self)

	# Inherit enemy's transform
	var old_global_transform = global_transform
	self.get_parent().remove_child(self)
	enemy.add_child(self)
	global_transform = old_global_transform

func fuse_countdown(delta):
	remaining_fuse_time -= delta
	if remaining_fuse_time <= 0:
		# Explode once the fuse is out
		# Deal damage to enemy
		hit_enemy.take_damage(damage)

		# Play particle effect or whatever here

		# Delete self
		self.queue_free()

# Called during phys_process. The enemy's transform is already inherited, so just don't move at all WRT the enemy
func stick_in_enemy():
	# linear_velocity = Vector3.ZERO
	freeze = true
