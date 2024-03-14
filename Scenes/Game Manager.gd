extends Node3D
class_name GameManager

# Objects
@onready var object_manager:ObjectManager = $"../ObjectManager"
@onready var player:Player = $"../Player"
@onready var prism:Node3D = $"../Prism"

@export_group("Game")
@export var prism_health:int = 10
@export var rocket_refresh_time_seconds:float = 4
@onready var current_rocket_refresh_timer = rocket_refresh_time_seconds

@export_group("Enemies")
@export var enemy_spawn_distance = 1000
@export var enemy_spawn_timer:float = 1
@onready var current_enemy_spawn_timer = 0
@onready var enemies = []
@export var enemy_location_threshold_z_axis:float = 200

func _process(delta):
    # Process timer related events
    process_timers(delta)

    # Process checks
    cull_enemies()
    check_enemy_positions()
    check_game_over()
    pass

func process_timers(delta):
    # New rockets
    current_rocket_refresh_timer -= delta
    if current_rocket_refresh_timer <= 0:
        current_rocket_refresh_timer = rocket_refresh_time_seconds
        object_manager.spawn_rocket(Vector3(0,0,object_manager.big_rocket_spawn_distance), object_manager.get_random_rocket_location(), "Spawned Rocket")

    # New enemies
    current_enemy_spawn_timer -= delta
    if current_enemy_spawn_timer <= 0:
        current_enemy_spawn_timer = enemy_spawn_timer
        var new_enemies = object_manager.spawn_enemies(0, 1, enemy_spawn_distance) #change to point buy system in the future
        enemies.append_array(new_enemies)

        # speed up spawn timer slightly
        enemy_spawn_timer *= 0.99;

# Check if any enemy has been previously freed (destroyed by player)
func cull_enemies():
    var i = 0; # needs to be while; `for i in range(x)` does not allow you to change the value of i
    while i < enemies.size():
        if not is_instance_valid(enemies[i]):
            enemies.remove_at(i)
            print(i)
            i -= 1
            print(i)
        i += 1

# Check all enemies if they've passed the damage threshold
func check_enemy_positions():
    var i = 0; # needs to be while; `for i in range(x)` does not allow you to change the value of i
    while i < enemies.size():
        var enemy:Enemy = enemies[i]

        # Check if the enemy is beyond the threshold
        # print("%s is at %f"%[enemy.name, enemy.position.z])
        if enemy.position.z >= enemy_location_threshold_z_axis:
            # They have, deal damage to the prism
            prism_health -= enemy.damage_to_prism
            print("Prism took %d damage"%enemy.damage_to_prism)

            #do some kind of effect to show the prism's been damaged

            # Destroy the enemy
            enemies.remove_at(i)
            enemy.queue_free()

            # Manage loop variant because we have one less element now
            i -= 1

        i += 1

func check_game_over():
    # Do nothing if the prism still has health
    if prism_health > 0:
        return

    # End the game
    print("Game over")