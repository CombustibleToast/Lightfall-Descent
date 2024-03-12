extends Node3D
class_name ObjectManager

var rocket_scene = preload("res://Rocket/Rocket.tscn")
var rng;
@onready var PLAYER = $"../Player"

@export_group("Rocket Initialization")
@export var SPAWN_NUM_ROCKETS = 100
@export var MAX_ROCKET_DISTANCE = 100.0
@export var MAX_ROCKET_ALTITUDE_VARIANCE = 5.0
@export var ROCKET_INITAL_OFFSET_DISTANCE = 5.0

@export_group("Big Rocket")
@export var big_rocket_scale:float = 10
@export var big_rocket_spawn_location:Vector3 = Vector3(0,300,300)

@export_group("Enemies")
@export var enemy_spawn_location:Vector3
@export var enemy_spawn_radius:float
@export var basic_enemy:Enemy

# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	spawn_rockets(SPAWN_NUM_ROCKETS)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Rockets

func spawn_rockets(amount):
	# All rockets are placed in the "rockets" group
	# get_tree().get_nodes_in_group("rockets")
	# get_tree().call_group("rockets", "function_name")

	for i in range(0, amount):
		# Generate its location (polar to cartesian on x-z plane)
		var r = rng.randf() * MAX_ROCKET_DISTANCE
		var theta = deg_to_rad(rng.randf() * 360)
		var altitude = rng.randf() * MAX_ROCKET_ALTITUDE_VARIANCE - (MAX_ROCKET_ALTITUDE_VARIANCE/2)
		var rocket_desired_location = Vector3(r * cos(theta), r * sin(theta), altitude)

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

func spawn_big_rocket(target:Node3D):
	# Instantiate rocket and give it initial values
	var new_rocket:Rocket = rocket_scene.instantiate()
	add_child(new_rocket)
	new_rocket.is_big_rocket = true
	new_rocket.scale = Vector3.ONE * big_rocket_scale
	new_rocket.position = big_rocket_spawn_location
	new_rocket.fire()
	new_rocket.big_rocket_target = target

## Enemies

func spawn_enemies(amount:int):
	for i in range(0, amount):
		# Generate its location (polar to cartesian on x-z plane)
		var r = rng.randf() * enemy_spawn_radius
		var theta = deg_to_rad(rng.randf() * 360)
		var spawn_location = Vector3(r * cos(theta), r * sin(theta), 0)

		var new_enemy = basic_enemy.instantiate()
		add_child(new_enemy)