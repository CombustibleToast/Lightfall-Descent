extends Node3D

func _physics_process(delta):
    rotate(Vector3.FORWARD, delta/10)