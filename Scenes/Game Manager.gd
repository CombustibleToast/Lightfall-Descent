extends Node3D

@onready var object_manager:ObjectManager = $"../ObjectManager"
@onready var player:Player = $"../Player"
@export var enemy_spawn_timer:float = 4

func _process(delta):
    pass