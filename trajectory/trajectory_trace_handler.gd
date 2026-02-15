extends Node2D

@export var trajectory_line: Line2D
@export var line_color: Color = Color.WHITE

@export_group("Visual Scaling")
@export var max_alpha: float = 1.0
@export var min_alpha: float = 0.1
@export var max_width: float = 8.0
@export var min_width: float = 1.0
@export var min_speed: float = 50.0
@export var max_speed: float = 800.0 # Increased slightly for gravity slingshots

@export var time_step: float = 1.0 / 60.0
@export var max_steps: int = 200 

# We reuse this curve resource to avoid memory allocation spikes
var shared_width_curve: Curve = Curve.new()

func _ready():
	trajectory_line.top_level = true 
	trajectory_line.width = max_width
	trajectory_line.width_curve = shared_width_curve

func clear_trajectory():
	trajectory_line.clear_points()
	shared_width_curve.clear_points()

func update_trajectory(ball: Stone, start_velocity: Vector2):
	trajectory_line.clear_points()
	shared_width_curve.clear_points()

	var pos = ball.global_position
	var vel = start_velocity
	var damp = ball.linear_damp
	
	# We need to store the speeds to map them to the curve later
	var predicted_speeds: Array[float] = []

	for i in max_steps:
		trajectory_line.add_point(pos)
		
		var speed = vel.length()
		predicted_speeds.append(speed)
		
		# 1. Calculate Acceleration (The 'Orbit' logic)
		var accel = ball.stone_acceleration(pos)
		
		# 2. Physics Integration (Euler)
		vel += accel * time_step
		if damp > 0:
			vel *= clamp(1.0 - damp * time_step, 0.0, 1.0)
		
		var next_pos = pos + vel * time_step

		# 3. Collision Prediction
		var query = PhysicsRayQueryParameters2D.create(pos, next_pos)
		query.exclude = [ball.get_rid()] 
		var collision = get_world_2d().direct_space_state.intersect_ray(query)

		if collision:
			trajectory_line.add_point(collision.position)
			predicted_speeds.append(vel.length())
			break

		pos = next_pos

	# --- Apply Variable Width based on Speed ---
	var point_count = trajectory_line.get_point_count()
	for i in range(point_count):
		# t is the position along the line (0.0 to 1.0)
		var t = float(i) / float(point_count - 1) if point_count > 1 else 0.0
		
		# Calculate how fast the stone is at this specific point
		var current_speed = predicted_speeds[i]
		var speed_ratio = clamp((current_speed - min_speed) / (max_speed - min_speed), 0.0, 1.0)
		
		# Calculate the width multiplier (0.0 to 1.0)
		# This maps min_width to the low end and max_width to the high end
		var width_factor = lerp(min_width / max_width, 1.0, speed_ratio)
		
		shared_width_curve.add_point(Vector2(t, width_factor))

	# Overall alpha based on initial launch power
	var initial_speed_ratio = clamp((start_velocity.length() - min_speed) / (max_speed - min_speed), 0.0, 1.0)
	trajectory_line.self_modulate.a = lerp(min_alpha, max_alpha, initial_speed_ratio)
