extends Node2D

@onready var gm: Node = $GameManager
@onready var bg: Sprite2D = $Background

func _ready():
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
	var current_viewport_size = min(viewport_size.x, viewport_size.y)  # Use smaller dimension
	gm.arena_radius = (current_viewport_size / base_viewport_size) * base_radius

func _draw() -> void:
	draw_circle(gm.arena_global_center, gm.arena_radius, Color.RED, false, 5.0)

func scale_player_for_viewport():
	var viewport_size = get_viewport_rect().size
	var base_viewport_size = 720.0
	var current_size = min(viewport_size.x, viewport_size.y)
	var scale_factor = current_size / base_viewport_size
	
	# Scale the player
	var player = get_node("Player")  # Adjust path as needed
	player.scale = Vector2(scale_factor, scale_factor) * 0.75  # 0.75 is your current scale
	
	# Also update player position to center
	player.position = get_viewport_rect().size / 2
