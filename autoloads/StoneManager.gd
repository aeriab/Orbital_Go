# StoneManager.gd — Autoload Singleton
extends Node

# --- Debug Visualization ---
# Add these variables at the top with your other vars
var debug_enabled: bool = true
var debug_sprite: Sprite2D = null
var debug_image: Image = null
var debug_texture: ImageTexture = null

# Colors for the debug overlay
var debug_white_color: Color = Color(1, 1, 1, 0.3)     # semi-transparent white
var debug_black_color: Color = Color(0, 0, 0, 0.3)     # semi-transparent black
var debug_captured_color: Color = Color(1, 0, 0, 0.4)  # red = enclosed area
var debug_empty_color: Color = Color(0, 0, 0, 0.0)     # fully transparent




# --- Grid Configuration ---
# Tweak these to match your play area and desired resolution.

# Grid resolution. 64x64 = 4096 cells. Flood fill is O(cells), so
# this can run every frame without breaking a sweat.
const GRID_SIZE: int = 32

# How big is the play area in world units?
# Your stones gravity toward Vector2.ZERO, so the play area is
# roughly a square from (-WORLD_RADIUS, -WORLD_RADIUS) to
# (+WORLD_RADIUS, +WORLD_RADIUS). Adjust to fit your actual area.
@export var world_radius: float = 500.0

# How many grid cells each stone paints around itself.
# This controls how CLOSE stones need to be to form a wall.
# - 1 = stones must be nearly touching to seal a boundary
# - 2 = small gaps are forgiven (recommended starting point)
# - 3 = very forgiving, loose formations count as walls
@export var paint_radius: int = 2

# How often to run capture detection (seconds).
# 0.0 = every physics frame. 0.2 = 5 times per second.
@export var capture_interval: float = 0.2

# --- Cell Constants ---
# Using raw ints instead of an enum for PackedByteArray compatibility.
const EMPTY: int = 0
const WHITE: int = 1
const BLACK: int = 2

# --- Internal State ---
var stones: Array[Stone] = []
var grid: PackedByteArray          # The influence map itself
var reached: PackedByteArray       # Reused buffer for flood fill
var capture_timer: float = 0.0


func _ready():
	# Pre-allocate flat arrays. We reuse these every frame
	# instead of allocating new ones — zero garbage collection pressure.
	var total_cells = GRID_SIZE * GRID_SIZE
	grid = PackedByteArray()
	grid.resize(total_cells)
	reached = PackedByteArray()
	reached.resize(total_cells)
	
	if debug_enabled:
		_setup_debug_overlay()


func _setup_debug_overlay() -> void:
	# Create a tiny image the same size as our grid
	debug_image = Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGBA8)
	debug_texture = ImageTexture.create_from_image(debug_image)

	# Create a Sprite2D to display it
	debug_sprite = Sprite2D.new()
	debug_sprite.texture = debug_texture
	debug_sprite.centered = true

	# Position at world center (where your stones orbit)
	debug_sprite.position = Vector2.ZERO

	# Scale it up to cover the play area.
	# The image is GRID_SIZE pixels, the world is world_radius*2 units.
	# So each pixel needs to cover (world_radius*2 / GRID_SIZE) world units.
	var scale_factor = (world_radius * 2.0) / GRID_SIZE
	debug_sprite.scale = Vector2(scale_factor, scale_factor)

	# Render on top of everything for visibility
	debug_sprite.z_index = 100

	add_child(debug_sprite)


# Call this at the end of _run_capture_check(), after Step 3
# but before Step 4 (destroying stones). Pass in the capture results.
func _update_debug_overlay(black_captured: PackedByteArray, white_captured: PackedByteArray) -> void:
	if not debug_enabled or debug_image == null:
		return
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var idx = _idx(x, y)
			var color: Color
			# Priority: show captured regions in red,
			# then wall colors, then empty
			if black_captured[idx] == 1 or white_captured[idx] == 1:
				color = debug_captured_color
			elif grid[idx] == WHITE:
				color = debug_white_color
			elif grid[idx] == BLACK:
				color = debug_black_color
			else:
				color = debug_empty_color
			debug_image.set_pixel(x, y, color)
	# Push updated pixels to the GPU
	debug_texture.update(debug_image)






# --- Registration ---
func register_stone(stone: Stone) -> void:
	stones.append(stone)


func unregister_stone(stone: Stone) -> void:
	stones.erase(stone)


# --- Main Loop ---
func _physics_process(delta: float) -> void:
	capture_timer += delta
	if capture_timer >= capture_interval:
		capture_timer = 0.0
		_run_capture_check()


# --- The Core Algorithm ---
func _run_capture_check() -> void:
	# Step 1: Clear the grid
	grid.fill(EMPTY)

	# Step 2: Every stone paints its color onto the grid
	_paint_all_stones()

	# Step 3: Check captures for both colors
	# "Which Black stones are enclosed by White walls?"
	var black_captured = _find_enclosed_cells(WHITE)
	# "Which White stones are enclosed by Black walls?"
	var white_captured = _find_enclosed_cells(BLACK)
	
	_update_debug_overlay(black_captured, white_captured)

	# Step 4: Destroy captured stones
	# Collect first, destroy after — don't modify the array while iterating
	var to_destroy: Array[Stone] = []

	for stone in stones:
		if not is_instance_valid(stone):
			continue
		var cell = _world_to_grid(stone.global_position)
		var idx = _idx(cell.x, cell.y)

		# A Black stone on a cell enclosed by White → captured
		if stone.team == "Black" and black_captured[idx]:
			to_destroy.append(stone)
		# A White stone on a cell enclosed by Black → captured
		elif stone.team == "White" and white_captured[idx]:
			to_destroy.append(stone)

	for stone in to_destroy:
		print("Captured a ", stone.team, " stone!")
		stone.on_captured()


# --- Painting ---
# Each stone stamps its color onto nearby grid cells.
# This is what turns discrete point-objects into continuous
# "territory" on the grid. The paint_radius controls how
# close stones need to be to form a sealed wall.
func _paint_all_stones() -> void:
	for stone in stones:
		if not is_instance_valid(stone):
			continue

		var center = _world_to_grid(stone.global_position)
		var color = WHITE if stone.team == "White" else BLACK

		# Paint a square of cells around the stone's grid position
		for dx in range(-paint_radius, paint_radius + 1):
			for dy in range(-paint_radius, paint_radius + 1):
				var gx = center.x + dx
				var gy = center.y + dy
				if gx >= 0 and gx < GRID_SIZE and gy >= 0 and gy < GRID_SIZE:
					grid[_idx(gx, gy)] = color


# --- Flood Fill Capture Detection ---
# This is the heart of the system. Here's the intuition:
#
# Imagine the grid is a room. 'wall_color' cells are actual walls.
# We pour water in from every edge of the room. The water flows
# through EMPTY cells and through the OTHER color's cells, but
# it CAN'T flow through wall_color cells.
#
# After the flood:
# - Cells the water REACHED are "outside" (safe, not enclosed)
# - Cells the water DIDN'T REACH are "inside" (enclosed by walls)
#
# Returns a PackedByteArray where 1 = enclosed, 0 = safe.
func _find_enclosed_cells(wall_color: int) -> PackedByteArray:
	# Reset the reachability buffer
	reached.fill(0)

	# BFS queue — seed with all edge cells that aren't walls
	var queue: Array[int] = []  # Store flat indices for speed

	# Top and bottom edges
	for x in GRID_SIZE:
		for y in [0, GRID_SIZE - 1]:
			var idx = _idx(x, y)
			if grid[idx] != wall_color and reached[idx] == 0:
				reached[idx] = 1
				queue.append(idx)

	# Left and right edges (skip corners, already handled)
	for y in range(1, GRID_SIZE - 1):
		for x in [0, GRID_SIZE - 1]:
			var idx = _idx(x, y)
			if grid[idx] != wall_color and reached[idx] == 0:
				reached[idx] = 1
				queue.append(idx)

	# BFS — spread from edges through anything that isn't a wall
	# Using an index into the queue array instead of pop_front()
	# because pop_front() on a large Array is O(n) (shifts everything).
	var head: int = 0
	while head < queue.size():
		var idx = queue[head]
		head += 1

		# Convert flat index back to 2D for neighbor calculation
		var cx = idx % GRID_SIZE
		var cy = idx / GRID_SIZE

		# Check all 4 neighbors
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx = cx + dir.x
			var ny = cy + dir.y

			if nx < 0 or nx >= GRID_SIZE or ny < 0 or ny >= GRID_SIZE:
				continue

			var nidx = _idx(nx, ny)

			# Skip if already visited or if it's a wall
			if reached[nidx] == 1 or grid[nidx] == wall_color:
				continue

			reached[nidx] = 1
			queue.append(nidx)

	# Invert: anything NOT reached is enclosed
	var enclosed = PackedByteArray()
	enclosed.resize(GRID_SIZE * GRID_SIZE)
	for i in reached.size():
		enclosed[i] = 1 if reached[i] == 0 else 0

	return enclosed


# --- Coordinate Conversion ---
# Maps a world position to a grid cell.
# World goes from -world_radius to +world_radius on both axes.
# Grid goes from 0 to GRID_SIZE-1.
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var normalized_x = (world_pos.x + world_radius) / (world_radius * 2.0)
	var normalized_y = (world_pos.y + world_radius) / (world_radius * 2.0)
	var gx = clampi(int(normalized_x * GRID_SIZE), 0, GRID_SIZE - 1)
	var gy = clampi(int(normalized_y * GRID_SIZE), 0, GRID_SIZE - 1)
	return Vector2i(gx, gy)


# Flat array index from 2D coordinates
func _idx(x: int, y: int) -> int:
	return y * GRID_SIZE + x
