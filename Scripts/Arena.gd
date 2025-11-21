extends Node2D

func _ready():
	var viewport_size = get_viewport_rect().size
	var arena_center = viewport_size / 2
	
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://Resources/Sprites/M08s-P1a-Arena.png")
	sprite.position = arena_center
	sprite.scale = Vector2(0.5, 0.5)
	sprite.z_index = -2
	add_child(sprite)
