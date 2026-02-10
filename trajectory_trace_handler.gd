extends Node2D
@export var trajectory_line: Line2D

var time_step: float = 0.05
var max_steps: int = 30

func update_trajectory(start_position: Vector2, start_velocity: Vector2):
	trajectory_line.clear_points()
	
	var pos = start_position
	var vel = start_velocity
	
	for i in max_steps:
		trajectory_line.add_point(pos)
		
		# Same force as your ball: direction toward origin * gravity * 100
		# F = direction_to_center * Global.gravity * 100
		# For a RigidBody2D with mass 1, acceleration = force
		var accel = pos.direction_to(Vector2.ZERO) * Global.gravity * 100
		
		# Euler integration
		vel += accel * time_step
		var next_pos = pos + vel * time_step
		
		# Raycast to check for collisions
		var query = PhysicsRayQueryParameters2D.create(pos, next_pos)
		var collision = get_world_2d().direct_space_state.intersect_ray(query)
		
		if collision:
			trajectory_line.add_point(collision.position)
			break
		
		pos = next_pos
