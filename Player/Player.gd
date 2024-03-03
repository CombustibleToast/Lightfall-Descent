extends CharacterBody3D

const SPEED = 200.0 # change to about 5 once movement abilities are in
const DRAG = 0.1
const DRAG_DELTA_MULTIPLIER = 50
const INERTIA = 80.0

@onready var all_interactables = []
@onready var currently_mounted_rocket = null

# Rocket arming and firing
enum ArmingState {NOT_ARMING, ARMING, ARMING_CANCELLED_BUT_BUTTON_STILL_HELD}
@onready var arming_state = ArmingState.NOT_ARMING

func _process(delta):
	# Check for interaction press
	if Input.is_action_just_pressed("interact"):
		try_interact()
	
	# Process arming cylce
	process_arming()

func _physics_process(delta):
	if currently_mounted_rocket:
		mounted_movement(delta)
	else:
		freefall_movement(delta)

## Movement

func freefall_movement(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_vector = Input.get_vector("left", "right", "forward", "backward")
	var elevation_vector = Input.get_axis("down", "up")
	var input_direction = (transform.basis * Vector3(input_vector.x, elevation_vector, input_vector.y)).normalized()

	velocity += input_direction * SPEED * delta

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

func mounted_movement(delta):
	# Inherit transform
	position = currently_mounted_rocket.position + Vector3(0,1,0)

	# Collect input
	var input_vector = Input.get_vector("left", "right", "forward", "backward")
	var elevation_vector = Input.get_axis("down", "up")
	var input_direction = (transform.basis * Vector3(input_vector.x, elevation_vector, input_vector.y)).normalized()

	# Pass input to rocket for movement
	currently_mounted_rocket.mounted_input_movement(input_direction, delta)

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
	if Input.is_action_pressed("arm_rocket") && arming_state != ArmingState.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD:
		# Arm the rocket if not already
		arming_state = ArmingState.ARMING
		

	# Check for disarm button press. Only care if the rocket's being armed
	if arming_state == ArmingState.ARMING && Input.is_action_just_pressed("disarm_rocket"):
		# Disarm the rocket
		arming_state = ArmingState.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD

	# Reset arming state if the button was released after disarming
	if arming_state == ArmingState.ARMING_CANCELLED_BUT_BUTTON_STILL_HELD && Input.is_action_just_released("arm_rocket"):
		arming_state = ArmingState.NOT_ARMING

	# If the rocket is properly armed and the button is released, fire it
	if arming_state == ArmingState.ARMING && Input.is_action_just_released("arm_rocket"):
		fire_rocket()

func fire_rocket():
	currently_mounted_rocket.fire()
	currently_mounted_rocket = null

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

	# Position inheritence is handled in mounted_movement()

	# Inform rocket of mounted status
	rocket.player_mount(true)

func dismount_rocket():
	# This function should only be called while mounted, will crash otherwise
	currently_mounted_rocket.player_mount(false)
	currently_mounted_rocket = null

func _on_player_interaction_area_area_entered(area):
	print("%s has entered player's interact area"%area.get_parent().name)
	all_interactables.append(area.get_parent())
	pass # Replace with function body.

func _on_player_interaction_area_area_exited(area):
	all_interactables.erase(area.get_parent())
	pass # Replace with function body.
