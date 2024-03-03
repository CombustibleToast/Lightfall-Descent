extends CharacterBody3D

const SPEED = 5.0
const DRAG = 0.1
const INERTIA = 80.0

func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_vector = Input.get_vector("left", "right", "forward", "backward")
	var elevation = Input.get_axis("down", "up")
	var input_direction = (transform.basis * Vector3(input_vector.x, elevation, input_vector.y)).normalized()

	velocity += input_direction

	velocity *= (1 - DRAG)

	# print("speed %f" % velocity.length())

	move_and_slide()

	# To push around rigidbodies
	# Taken from https://kidscancode.org/godot_recipes/4.x/physics/character_vs_rigid/index.html
	# After calling move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			# c.get_collider().apply_central_impulse(-c.get_normal() * INERTIA)
			c.get_collider().apply_impulse(-c.get_normal() * INERTIA)