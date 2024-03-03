extends Node3D

# Preload spawnable objects
var rocket_scene = preload("res://Rocket/Rocket.tscn")
var rng;

const SPAWN_NUM_ROCKETS = 10
const MAX_ROCKET_DISTANCE = 30.0
const MAX_ROCKET_ALTITUDE_VARIANCE = 5.0
# const ROCKET_OFFSET DISTANCE


# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	spawn_rockets(SPAWN_NUM_ROCKETS)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_rockets(amount):
	for i in range(0, amount):
		# Generate its location (polar to cartesian on x-z plane)
		var r = rng.randf() * MAX_ROCKET_DISTANCE
		var theta = deg_to_rad(rng.randf() * 360)
		var altitude = rng.randf() * MAX_ROCKET_ALTITUDE_VARIANCE - (MAX_ROCKET_ALTITUDE_VARIANCE/2)
		var rocket_desired_location = Vector3(r * cos(theta), altitude, r * sin(theta))


		var rocket_initial_location = rocket_desired_location + Vector3(rng.randf() * 2 - 1, rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized() # to generate pid wobble 

		# Instantiate rocket and give it initial values
		var new_rocket = rocket_scene.instantiate()
		add_child(new_rocket)
		new_rocket.desired_position = Vector3(rocket_desired_location)
		new_rocket.position = rocket_initial_location