extends CharacterBody3D
class_name Player

const SPEED = 50.0 # change to about 5 once movement abilities are in
@export var arming_movement_speed_throttle:float = 0.05
const DRAG = 0.1
const DRAG_DELTA_MULTIPLIER = 50
const INERTIA = 80.0

# Rocket interactions
@onready var all_interactables = []
@onready var currently_mounted_rocket:Rocket = null
@export var riding_position_offset:Vector3 = Vector3(0,0.1,0)
@onready var jump_push_impulse = 6000.0
@onready var collider = $"CollisionShape3D"
@export var targeting_raycast:RayCast3D # set in inspector of game scene
@export var targeting_reticle:TargetingReticle # set in inspector of game scene

# Character state machine
enum State {FALLING, RIDING, ARMING, ARMING_CANCELLED_BUT_BUTTON_STILL_HELD, FIRING}
@onready var state = State.FALLING

# Visual Stuff
@onready var animator:AnimationTree = $"AnimationTree"
@onready var camera = $"../Camera3D"
@onready var initial_camera_offset:Vector3 = camera.position - self.position
# @onready var mesh = $

func _process(delta):
	# Check for interaction press
	if Input.is_action_just_pressed("interact"):
		try_interact()
	
	# Process arming cylce
	process_arming()

	# Process targeting
	process_targeting()

	# Update animator
	update_animator()
	# print(state)

func _physics_process(delta):
	# Collect inputs
	var inputs:Vector3 = collect_movement_inputs()

	# Process movement
	match state:
		State.FALLING:
			freefall_movement(inputs, delta)
		State.RIDING:
			mounted_movement(inputs, delta)
		State.ARMING:
			mounted_movement(inputs, delta)
		State.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD:
			mounted_movement(inputs, delta)
		State.FIRING:
			# Disallow movement
			pass

## Movement

func collect_movement_inputs() -> Vector3:
	# Some of the axes are funky because of the way the camera and scene are oriented 
	var input_vector = Input.get_vector("left", "right", "forward", "backward")
	var elevation_vector = Input.get_axis("down", "up")
	return (transform.basis * Vector3(input_vector.x, elevation_vector, input_vector.y)).normalized()

func freefall_movement(input_vector:Vector3,delta):
	velocity += input_vector * SPEED * delta

	var delta_drag = 1 - (DRAG * delta * DRAG_DELTA_MULTIPLIER) # No idea if this is the right way to influence drag with delta.
	velocity *= delta_drag

	move_and_slide()

	# To push around rigidbodies
	# Taken from https://kidscancode.org/godot_recipes/4.x/physics/character_vs_rigid/index.html
	# After calling move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			# c.get_collider().apply_central_impulse(-c.get_normal() * INERTIA)
			c.get_collider().apply_impulse(-c.get_normal() * INERTIA)

func mounted_movement(input_vector:Vector3, delta):
	# Scale movment down if arming
	input_vector *= arming_movement_speed_throttle if state == State.ARMING else 1.0
	# Pass input to rocket for movement
	currently_mounted_rocket.mounted_input_movement(input_vector, delta)

func inherit_global_transform():
	# Inherit global transform
	var old_global_transform = global_transform
	var root_node = get_tree().root
	self.get_parent().remove_child(self)
	root_node.add_child(self)
	global_transform = old_global_transform

	# Reset rotation
	rotation = Vector3.ZERO

## Rocket Firing

func process_arming():
	# Don't do any arming if not currently on a rocket
	if !currently_mounted_rocket:
		return
	
	# The rocket should be armed while the arm button is being held
	# When it's released, fire the rocket
	# Cancellable if the disarm button is pressed
	# Don't try to start arming again until the arm button is re-pressed

	# Check for arming button held but don't care if it's from a cancelled arming cycle
	if Input.is_action_pressed("arm_rocket") && state != State.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD:
		# Arm the rocket if not already
		state = State.ARMING
		

	# Check for disarm button press. Only care if the rocket's being armed
	if state == State.ARMING && Input.is_action_just_pressed("disarm_rocket"):
		# Disarm the rocket
		state = State.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD

	# Reset arming state if the button was released after disarming
	if state == State.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD && Input.is_action_just_released("arm_rocket"):
		state = State.RIDING

	# If the rocket is properly armed and the button is released, fire it
	if state == State.ARMING && Input.is_action_just_released("arm_rocket"):
		fire_rocket()

func process_targeting():
	# If the player is currently firing the rocket, don't do anything. That was handled in process_arming() -> fire_rocket()
	if state == State.FIRING:
		return
	
	# If the reticle is stuck in another target, also don't do anything
	if targeting_reticle.stuck_on_target:
		return
	
	# Only enable the targeting raycast if the player is targeting
	if state != State.ARMING:
		targeting_raycast.enabled = false
		if targeting_reticle.visible:
			targeting_reticle.deactivate()
		return

	# Enable the raycast and check for a hit
	targeting_raycast.enabled = true
	if targeting_raycast.is_colliding():
		# print("raycast is hitting %s!"%other_collider.name)
		# Raycast is hitting an enemy, gather spatial information about the contact
		var collision_point:Vector3 = targeting_raycast.get_collision_point()
		var collision_normal:Vector3 = targeting_raycast.get_collision_normal()

		# Activate targeting reticle and move it to that point
		targeting_reticle.activate(collision_point, collision_normal)
	
	else:
		targeting_reticle.deactivate()	

func fire_rocket():
	# Play animation
	state = State.FIRING

	# Notify the rocket that it's about to be fired and give it the reticle for targeting purposes
	currently_mounted_rocket.pre_fire(targeting_reticle)

	# Notify the reticle that the rocket is being fired so it sticks to the target
	targeting_reticle.rocket_firing(targeting_raycast.get_collider())

	# Releasing the rocket is handled in animation_jump_release
	# Resetting the state is hangled in animation_jump_finished

## Interactions

func try_interact():
	# Dismounting current rocket if available
	if currently_mounted_rocket:
		dismount_rocket()
		return

	if all_interactables.size() > 0:
		var interactable = all_interactables[0]
		print("Interacting with %s"%interactable.name)

		# put a match block here for determining what kind of interaction should be carried out
		# for now, assume it's a rocket
		mount_rocket(interactable)

func mount_rocket(rocket):
	# Set variables to show state.
	# In the future, implement a state machine for freefall/mounted/dismounting/mounting/etc
	currently_mounted_rocket = rocket

	# Play mount animation
	state = State.RIDING

	# Inherit rocket transform
	position = rocket.position + riding_position_offset
	var old_global_transform = global_transform
	self.get_parent().remove_child(self)
	rocket.add_child(self)
	global_transform = old_global_transform

	# Inform rocket of mounted status
	rocket.player_mount(true)

	# Disable own collider
	collider.disabled = true

func dismount_rocket():
	# This function should only be called while mounted, will crash otherwise
	currently_mounted_rocket.player_mount(false)
	currently_mounted_rocket = null

	inherit_global_transform()
	
	# Update state
	state = State.FALLING

	# Re-enable own collider
	collider.disabled = true

func _on_player_interaction_area_area_entered(area):
	print("%s has entered player's interact area"%area.get_parent().name)
	all_interactables.append(area.get_parent())
	pass # Replace with function body.

func _on_player_interaction_area_area_exited(area):
	all_interactables.erase(area.get_parent())
	pass # Replace with function body.

## Visuals

func update_animator():	
	animator.set("parameters/conditions/mount", state == State.RIDING)
	animator.set("parameters/conditions/dismount", state == State.FALLING)
	animator.set("parameters/conditions/arm", state == State.ARMING)
	animator.set("parameters/conditions/disarm", state == State.RIDING || state == State.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD)
	animator.set("parameters/conditions/fire", state == State.FIRING)

# This function is called within the AnimationPlayer -> jump animation. Scroll to the bottom of all the tracks to see it
func animation_jump_release():
	# Fire the rocket
	currently_mounted_rocket.fire()

	# Push the rocket down and the player up
	currently_mounted_rocket.apply_central_impulse(Vector3(0, -jump_push_impulse, 0))

	# Dismount the rocket
	currently_mounted_rocket = null
	inherit_global_transform()

	# Re-enable own collider
	collider.disabled = true

# This function is called within the AnimationPlayer -> jump animation. Scroll to the bottom of all the tracks to see it
func animation_jump_finished():
	# Jump animation is done, reset to falling state
	state = State.FALLING
