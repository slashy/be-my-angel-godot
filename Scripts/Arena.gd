extends Node2D
## Resizes the arena and background for the current viewport.

@onready var gm: Node = $GameManager
@onready var bg: Sprite2D = $Background
@onready var player: Node2D = get_node_or_null("Player")

## Scale background and arena to the current viewport.
func _ready() -> void:
	# Scale background to fit viewport
	var viewport_size = get_viewport_rect().size
	var bg_size = bg.get_rect().size
	var scale_factor = viewport_size / bg_size
	bg.scale = scale_factor
	
	scale_player_for_viewport()
	
	# Update arena radius based on viewport size
	# Assuming the arena should be 290 radius for a 720x720 viewport
	var base_viewport_size = 720.0
	var base_radius = 290.0
	# Use the smaller dimension to preserve a circular arena.
	var current_viewport_size = min(viewport_size.x, viewport_size.y)
	gm.arena_radius = (current_viewport_size / base_viewport_size) * base_radius

func _draw() -> void:
	draw_circle(gm.arena_global_center, gm.arena_radius, Color.RED, false, 5.0)

## Scale and center the player based on viewport size.
func scale_player_for_viewport() -> void:
	var viewport_size = get_viewport_rect().size
	var base_viewport_size = 720.0
	var current_size = min(viewport_size.x, viewport_size.y)
	var scale_factor = current_size / base_viewport_size
	
	# Scale the player
	if player == null:
		return
	player.scale = Vector2(scale_factor, scale_factor) * 0.75  # 0.75 is your current scale
	
	# Also update player position to center
	player.position = get_viewport_rect().size / 2
