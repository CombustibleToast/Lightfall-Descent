extends Node3D

var rocket_scene = preload("res://Rocket/Rocket.tscn")
var rng;
@onready var PLAYER = $"../Player"

@export_group("Rocket Initialization")
@export var SPAWN_NUM_ROCKETS = 10
@export var MAX_ROCKET_DISTANCE = 30.0
@export var MAX_ROCKET_ALTITUDE_VARIANCE = 5.0
@export var ROCKET_INITAL_OFFSET_DISTANCE = 5.0


# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	spawn_rockets(SPAWN_NUM_ROCKETS)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_rockets(amount):
	# All rockets are placed in the "rockets" group
	# get_tree().get_nodes_in_group("rockets")
	# get_tree().call_group("rockets", "function_name")

	for i in range(0, amount):
		# Generate its location (polar to cartesian on x-z plane)
		var r = rng.randf() * MAX_ROCKET_DISTANCE
		var theta = deg_to_rad(rng.randf() * 360)
		var altitude = rng.randf() * MAX_ROCKET_ALTITUDE_VARIANCE - (MAX_ROCKET_ALTITUDE_VARIANCE/2)
		var rocket_desired_location = Vector3(r * cos(theta), altitude, r * sin(theta))

		# Make rocket's actual initial position different than its desired one to generate pid wobble 
		var rocket_initial_location = rocket_desired_location 
		rocket_initial_location.x += rng.randf() * ROCKET_INITAL_OFFSET_DISTANCE - (ROCKET_INITAL_OFFSET_DISTANCE/2)
		rocket_initial_location.y += rng.randf() * ROCKET_INITAL_OFFSET_DISTANCE - (ROCKET_INITAL_OFFSET_DISTANCE/2)
		rocket_initial_location.z += rng.randf() * ROCKET_INITAL_OFFSET_DISTANCE - (ROCKET_INITAL_OFFSET_DISTANCE/2)

		# Instantiate rocket and give it initial values
		var new_rocket = rocket_scene.instantiate()
		add_child(new_rocket)
		new_rocket.desired_position = Vector3(rocket_desired_location)
		new_rocket.position = rocket_initial_location
		new_rocket.name = "Rocket %d"%i
		new_rocket.PLAYER = PLAYER