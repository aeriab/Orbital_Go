# StoneManager.gd — Autoload Singleton
extends Node

@export var capture_interval: float = 0.2

# --- Internal State ---
var stones: Array[Stone] = []
var capture_timer: float = 0.0

# --- Registration ---
func register_stone(stone: Stone) -> void:
	if not stones.has(stone):
		stones.append(stone)

func unregister_stone(stone: Stone) -> void:
	stones.erase(stone)

# --- Main Loop ---
func _physics_process(delta: float) -> void:
	capture_timer += delta
	if capture_timer >= capture_interval:
		capture_timer = 0.0
		# This is where we will eventually call the C# logic
		_run_capture_check()

func _run_capture_check() -> void:
	# Filter out any stones that might have been queued for deletion
	var active_stones = stones.filter(func(s): return is_instance_valid(s))
	
	# TODO: In the next step, we will call our C# CaptureManager here.
	# For now, we just ensure the list is clean.
	pass

# --- Utility for C# ---
# This allows C# to easily grab the stones without managing its own list
func get_active_stones() -> Array[Stone]:
	return stones.filter(func(s): return is_instance_valid(s))
