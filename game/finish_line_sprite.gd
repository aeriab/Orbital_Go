extends Sprite2D

func _ready() -> void:
	Global.zone_radius_changed.connect(change_zone_radius)

func change_zone_radius(radius: float) -> void:
	scale = Vector2(radius / 1465.0, radius / 1465.0)
