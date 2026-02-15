extends Node2D

@export var trajectory_line: Line2D
@export var line_color: Color = Color.WHITE

@export_group("Visual Scaling")
@export var max_alpha: float = 1.0
@export var min_alpha: float = 0.1
@export var max_width: float = 8.0
@export var min_width: float = 1.0
@export var min_speed: float = 50.0
@export var max_speed: float = 500.0

var time_step: float = 1.0 / 60.0
var max_steps: int = 200 # Reduced slightly for performance

func _ready():
	# Crucial: This ensures world coordinates match the line points
	trajectory_line.top_level = true 
	# Pre-allocate resources if needed, but for now we'll optimize the loop
	trajectory_line.width = max_width

func clear_trajectory():
	trajectory_line.clear_points()

func update_trajectory(ball: Stone, start_velocity: Vector2):
	trajectory_line.clear_points()

	var pos = ball.global_position
	var vel = start_velocity
	
	# Match the Stone's mass and damp
	var mass = ball.mass
	var damp = ball.linear_damp
	
	# Instead of creating new Gradients/Curves every frame, we use a simple color 
	# logic or update the points. Creating new resources in _process is heavy.
	for i in max_steps:
		trajectory_line.add_point(pos)
		
		# 1. Calculate Acceleration (The 'Orbit' logic)
		var accel = ball.stone_acceleration(pos)
		
		# 2. Physics Integration (Euler)
		vel += accel * time_step
		if damp > 0:
			vel *= clamp(1.0 - damp * time_step, 0.0, 1.0)
		
		var next_pos = pos + vel * time_step

		# 3. Collision Prediction
		var query = PhysicsRayQueryParameters2D.create(pos, next_pos)
		# Ensure the ray ignores the ball itself!
		query.exclude = [ball.get_rid()] 
		var collision = get_world_2d().direct_space_state.intersect_ray(query)

		if collision:
			trajectory_line.add_point(collision.position)
			break

		pos = next_pos

	# Optional: Instead of per-point width (heavy), just scale the whole line 
	# based on the initial launch speed
	var initial_speed_ratio = clamp((start_velocity.length() - min_speed) / (max_speed - min_speed), 0.0, 1.0)
	trajectory_line.self_modulate.a = lerp(min_alpha, max_alpha, initial_speed_ratio)
