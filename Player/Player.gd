extends CharacterBody3D

const SPEED = 5.0
const DRAG = 0.1

func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_vector = Input.get_vector("left", "right", "forward", "backward")
	var input_direction = (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()

	velocity += input_direction

	velocity *= (1 - DRAG)

	print("speed %f" % velocity.length())

	# if input_direction:
	# 	velocity.x = input_direction.x * SPEED
	# 	velocity.z = input_direction.z * SPEED
	# else:
	# 	velocity.x = move_toward(velocity.x, 0, SPEED)
	# 	velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
