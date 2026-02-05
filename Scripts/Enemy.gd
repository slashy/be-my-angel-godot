extends Node2D
## Enemy that telegraphs an attack and dashes across the arena.

@export var spawn_time: float = 0.4
@export var aim_time: float = 1.8
@export var indicator_offset: float = 24.0
@export var aoe_indicator_time: float = 0.2
@export var direction_indicator_length: float = 30.0
@export var attack_width: float = 40.0
@export var knockback_strength: float = 400.0
@export var knockback_timer: float = 0.75
@export var move_speed: float = 1000.0
@export var tether_pulse_speed: float = 3.0
@export var tether_glow_intensity: float = 1.5

const DIRECTIONS: Dictionary = {
	Vector2(0, -1): "up",
	Vector2(0, 1): "down",
	Vector2(-1, 0): "left",
	Vector2(1, 0): "right",	
	Vector2(1, 1): "down_right",
	Vector2(-1, 1): "down_left",
	Vector2(-1, -1): "up_left",
	Vector2(1, -1): "up_right",
	Vector2.ZERO: "down"
}

var seconds_till_attack: int = 2
var target_direction: String = "down"
var move_to_target: bool = false
var attack_indicator_end: Vector2 = Vector2.ZERO
var arena_radius: float = 0.0
var tether_time: float = 0.0

@onready var direction_indicator: Line2D = $DirectionIndicator
@onready var attack_indicator: Line2D = $AttackIndicator
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound

## Initialize enemy visuals and telegraph attack direction.
func _ready() -> void:
	# Scale enemy to be proportional to viewport, but smaller than before
	var viewport_size = get_viewport().get_visible_rect().size
	var base_viewport_size = 720.0
	var current_size = min(viewport_size.x, viewport_size.y)
	var scale_factor = current_size / base_viewport_size
	
	# Apply a smaller scale factor for enemies (e.g., 0.6 times the viewport scale)
	scale = Vector2(scale_factor * 0.6, scale_factor * 0.6)
	
	var target: Vector2 = Vector2.ZERO
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	arena_radius = get_parent().arena_radius
	
	if players.size() > 0:
		var player := players[0] as Node2D
		if player == null:
			queue_free()
			return
		target = player.global_position - global_position
	else:
		queue_free()
		return

	if target == Vector2.ZERO:
		target = Vector2.DOWN

	$AnimatedSprite2D.play("idle_" + DIRECTIONS[_get_target_direction_vector(target)])
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

	var direction: Vector2 = target.normalized()

	var indicator_start: Vector2 = direction * indicator_offset
	var direction_indicator_end: Vector2 = direction * (
				indicator_offset + direction_indicator_length
			)
	attack_indicator_end = get_attack_target(indicator_start, direction)
	
	$DirectionIndicator.clear_points()
	$DirectionIndicator.add_point(indicator_start)
	$DirectionIndicator.add_point(direction_indicator_end)
	
	$DirectionIndicator.width = 2.0
	# Bright green indicator color.
	$DirectionIndicator.default_color = Color(0.2, 1.0, 0.3, 1.0)
	
	$DirectionIndicator.antialiased = true
	$DirectionIndicator.joint_mode = Line2D.LINE_JOINT_ROUND
	$DirectionIndicator.begin_cap_mode = Line2D.LINE_CAP_ROUND
	$DirectionIndicator.end_cap_mode = Line2D.LINE_CAP_ROUND

	$AttackIndicator.clear_points()
	$AttackIndicator.add_point(indicator_start)
	$AttackIndicator.add_point(to_local(attack_indicator_end))
	$AttackIndicator.width = attack_width

	if target != Vector2.ZERO:
		await get_tree().create_timer(spawn_time).timeout
		$DirectionIndicator.visible = true
		await get_tree().create_timer(aim_time).timeout
		$DirectionIndicator.z_index = -10
		$DirectionIndicator.visible = false
		await get_tree().process_frame
		$AttackIndicator.visible = true
		await get_tree().create_timer(aoe_indicator_time).timeout
		$AttackIndicator.visible = false
		if attack_sound:
			attack_sound.play()
		move_to_target = true
		

func _process(delta: float) -> void:
	if $DirectionIndicator.visible:
		tether_time += delta * tether_pulse_speed
		var pulse = (sin(tether_time) + 1.0) * 0.5
		var base_width = 2.0
		var pulse_width = base_width + (pulse * 4.0)
		$DirectionIndicator.width = pulse_width
		
		var alpha_pulse = 0.7 + (pulse * 0.3)
		$DirectionIndicator.modulate.a = alpha_pulse
	
	if move_to_target:
		$AnimatedSprite2D.play("idle_" + 
			DIRECTIONS[_get_target_direction_vector(to_local(attack_indicator_end))])
		var direction: Vector2 = (attack_indicator_end - global_position).normalized()
		var step: float = move_speed * delta
		if global_position.distance_to(attack_indicator_end) > step:
			global_position += direction * step
		else:
			global_position = attack_indicator_end
			move_to_target = false
			queue_free()


## Map a direction vector to the nearest 8-way direction.
func _get_target_direction_vector(target: Vector2) -> Vector2:
	var directions = [
		Vector2.RIGHT,
		Vector2(1, 1),
		Vector2.DOWN,
		Vector2(-1, 1),
		Vector2.LEFT,
		Vector2(-1, -1),
		Vector2.UP,
		Vector2(1, -1)
	]
	var num_directions = directions.size()
	
	if target == Vector2.ZERO:
		return target 
		
	var angle: float = target.angle()
	var direction = (int(round(angle / (TAU / num_directions))) + num_directions) % num_directions
		
	return directions[direction]


## Return the circle intersection point for the attack line.
func get_attack_target(start: Vector2, direction: Vector2) -> Vector2:
	# Attack indicator: line intersection with the opposite circle edge.
	var attack_start = global_position + start # absolute start point
	if direction == Vector2.ZERO:
		return attack_start
	# Vector from circle center to start.
	var rel = attack_start - get_viewport_rect().size / 2
	var a = direction.length_squared()
	var b = 2.0 * rel.dot(direction)
	var c = rel.length_squared() - arena_radius * arena_radius
	var discr = b*b - 4.0*a*c

	if discr >= 0.0:
		var t1 = (-b + sqrt(discr)) / (2.0 * a)
		var t2 = (-b - sqrt(discr)) / (2.0 * a)
		# Choose the t that is farther from the start point.
		var t = t1 if abs(t1) > abs(t2) else t2
		# Compute end point in global space.
		var attack_end_global = attack_start + direction * t
		# Line2D uses local coords, so return global and convert outside.
		return attack_end_global
	
	# Fallback: extend far beyond the arena.
	return attack_start + direction * (arena_radius * 2)

## Handle collisions with the attack area.
func _on_attack_area_body_entered(body: Node) -> void:
	# Body is the colliding object (e.g. the player).
	if move_to_target and body.is_in_group("player"):
		print("Player hit!")
		body.apply_knockback(attack_indicator_end, knockback_strength, knockback_timer)
		
