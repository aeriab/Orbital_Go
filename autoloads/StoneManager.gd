# StoneManager.gd — Autoload Singleton
extends Node

# StoneManager.gd
var stones: Array[RigidBody2D] = [] # Changed from Array[Stone]

func register_stone(body: RigidBody2D) -> void: # Changed parameter name/type
	if not stones.has(body):
		stones.append(body)

func unregister_stone(body: RigidBody2D) -> void:
	stones.erase(body)

func get_active_stones() -> Array[RigidBody2D]:
	return stones.filter(func(s): return is_instance_valid(s))
