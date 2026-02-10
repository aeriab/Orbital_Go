extends Node2D
@export var trajectory_line: Line2D

var time_step: float = 1.0 / 60.0
var max_steps: int = 30

func update_trajectory(ball: Stone, start_velocity: Vector2):
	trajectory_line.clear_points()
	
	var pos = ball.global_position
	var vel = start_velocity
	var damp = ball.linear_damp
	
	for i in max_steps:
		trajectory_line.add_point(pos)
		
		# Same force as your ball: direction toward origin * gravity * 100
		# F = direction_to_center * Global.gravity * 100
		# For a RigidBody2D with mass 1, acceleration = force
		var accel = ball.stone_acceleration(pos)
		
		# Euler integration
		vel += accel * time_step
		vel *= max(1.0 - damp * time_step, 0.0)
		
		var next_pos = pos + vel * time_step
		
		# Raycast to check for collisions
		var query = PhysicsRayQueryParameters2D.create(pos, next_pos)
		var collision = get_world_2d().direct_space_state.intersect_ray(query)
		
		if collision:
			trajectory_line.add_point(collision.position)
			break
		
		pos = next_pos
