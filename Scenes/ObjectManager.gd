extends Node3D
class_name ObjectManager

var rocket_scene = preload("res://Rocket/Rocket.tscn")
@onready var PLAYER = $"../Player"
@onready var game_manager:GameManager = $"../Game Manager"

@export_group("Rocket Initialization")
@export var SPAWN_NUM_ROCKETS = 20
@export var MAX_ROCKET_DISTANCE = 100.0
@export var MAX_ROCKET_ALTITUDE_VARIANCE = 20.0
@export var ROCKET_INITAL_OFFSET_DISTANCE = 5.0

@export_group("Big Rocket")
@export var big_rocket_scale:float = 10
@export var big_rocket_spawn_distance:float = 600
@export var big_rocket_max_spawn_radius:float = 1000

@export_group("Enemies")
@export var enemy_spawn_radius:float = 400
@export var basic_enemy = preload("res://Enemies/Basic Enemy.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_rockets(SPAWN_NUM_ROCKETS)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Rockets

func get_random_rocket_location() -> Vector3:
	# Generate its location (polar to cartesian on x-z plane)
	var r = randf() * MAX_ROCKET_DISTANCE
	var theta = deg_to_rad(randf() * 360)
	var altitude = randf() * MAX_ROCKET_ALTITUDE_VARIANCE - (MAX_ROCKET_ALTITUDE_VARIANCE/2)
	var rocket_desired_location = Vector3(r * cos(theta), r * sin(theta), altitude)
	return rocket_desired_location

func spawn_rocket(initial_position:Vector3, desired_position:Vector3, rocket_name:String) -> Rocket:
	# Instantiate rocket and give it initial values
	var new_rocket = rocket_scene.instantiate()
	add_child(new_rocket)
	new_rocket.desired_position = Vector3(desired_position)
	new_rocket.position = initial_position
	new_rocket.name = rocket_name
	new_rocket.PLAYER = PLAYER
	return new_rocket

func spawn_rockets(amount):
	# All rockets are placed in the "rockets" group
	# get_tree().get_nodes_in_group("rockets")
	# get_tree().call_group("rockets", "function_name")

	for i in range(0, amount):
		# Make rocket's actual initial position different than its desired one to generate pid wobble 
		var rocket_desired_location = get_random_rocket_location()
		var rocket_initial_location = rocket_desired_location 
		rocket_initial_location.x += randf() * ROCKET_INITAL_OFFSET_DISTANCE - (ROCKET_INITAL_OFFSET_DISTANCE/2)
		rocket_initial_location.y += randf() * ROCKET_INITAL_OFFSET_DISTANCE - (ROCKET_INITAL_OFFSET_DISTANCE/2)
		rocket_initial_location.z += randf() * ROCKET_INITAL_OFFSET_DISTANCE - (ROCKET_INITAL_OFFSET_DISTANCE/2)

		# Spawn rocket
		spawn_rocket(rocket_initial_location, rocket_desired_location, "Rocket %i"%i)


func spawn_big_rocket(target:Node3D):
	# Calculate initial position, polar to cartesian on x-y plane
	# Distance should be +z (behind camera)
	var r = randf() * big_rocket_max_spawn_radius
	var theta = deg_to_rad(randf() * 360)
	var spawn_position = Vector3(r * cos(theta), r * sin(theta), big_rocket_spawn_distance)
	print("Spawning big one at %s"%spawn_position)
	
	# Instantiate rocket and give it initial values
	var new_rocket:Rocket = rocket_scene.instantiate()
	add_child(new_rocket)
	new_rocket.is_big_rocket = true
	new_rocket.scale = Vector3.ONE * big_rocket_scale
	new_rocket.mass *= 2
	new_rocket.position = spawn_position
	new_rocket.fire()
	new_rocket.big_rocket_target = target

## Enemies

func spawn_enemies(type:int, amount:int, distance_away:float) -> Array:
	var all_new_enemies = []
	for i in range(0, amount):
		# Generate its location 
		var r = randf() * enemy_spawn_radius
		var theta = deg_to_rad(randf() * 360)
		var spawn_location = Vector3(r * cos(theta), r * sin(theta), -distance_away)

		# Spawn it and give it initial values
		var new_enemy:Enemy = basic_enemy.instantiate()
		add_child(new_enemy)
		new_enemy.position = spawn_location

		# Make sure to return the new enemy
		all_new_enemies.append(new_enemy)

	return all_new_enemies
