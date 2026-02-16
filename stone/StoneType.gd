class_name StoneType
extends Resource

@export var type_name: String = "Normal"
@export var fill_color: Color = Color.WHITE
@export var outline_color: Color = Color.DARK_GRAY

# Use bitmasks or an array for teams so a stone can be multiple teams
# e.g., ["P1", "P2"] for a neutral stone that connects both
@export var valid_teams: Array[String] = ["P1"]
@export var point_value: float = 1.0

# Future-proofing: unique physics or logic
@export var mass_multiplier: float = 1.0
@export var can_be_captured: bool = true
