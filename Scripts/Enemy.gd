extends Node2D

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

const DIRECTIONS := {
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

var seconds_till_attack := 2
var target_direction := "down"
var move_to_target := false
var attack_indicator_end := Vector2.ZERO
var arena_radius := 0.0
var tether_time: float = 0.0

@onready var direction_indicator: Line2D = $DirectionIndicator
@onready var attack_indicator: Line2D = $AttackIndicator
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var target: Vector2 = Vector2.ZERO
	var players: Array = get_tree().get_nodes_in_group("player")
	arena_radius = get_parent().arena_radius
	
	if players.size() > 0:
		var player = players[0]
		target = player.global_position - global_position

	$AnimatedSprite2D.play("idle_" + DIRECTIONS[_get_target_direction_vector(target)])
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

	var direction = target.normalized()

	var indicator_start = direction * indicator_offset
	var direction_indicator_end = direction * (indicator_offset + direction_indicator_length)
	attack_indicator_end = get_attack_target(indicator_start, direction)
	
	$DirectionIndicator.clear_points()
	$DirectionIndicator.add_point(indicator_start)
	$DirectionIndicator.add_point(direction_indicator_end)
	
	$DirectionIndicator.width = 2.0
	$DirectionIndicator.default_color = Color(0.2, 1.0, 0.3, 1.0)  # Bright green like in the image
	
	$DirectionIndicator.antialiased = true
	$DirectionIndicator.joint_mode = Line2D.LINE_JOINT_ROUND
	$DirectionIndicator.begin_cap_mode = Line2D.LINE_CAP_ROUND
	$DirectionIndicator.end_cap_mode = Line2D.LINE_CAP_ROUND

	$AttackIndicator.clear_points()
	$AttackIndicator.add_point(indicator_start)
	$AttackIndicator.add_point(to_local(attack_indicator_end))
	$AttackIndicator.width = attack_width

	if target:
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
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
		var direction = (attack_indicator_end - global_position).normalized()
		var step = move_speed * delta		
		if global_position.distance_to(attack_indicator_end) > step:
			global_position += direction * step
		else:
			global_position = attack_indicator_end
			move_to_target = false
			queue_free()


func _get_target_direction_vector(target) -> Vector2:
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
		
	var angle = target.angle()
	var direction = (int(round(angle / (TAU / num_directions))) + num_directions) % num_directions
		
	return directions[direction]


func get_attack_target(start: Vector2, direction: Vector2) -> Vector2:
	# ATTACK INDICATOR: Schnittpunkt Linie mit gegenüberliegenden Kreisrand!
	var attack_start = global_position + start        # absoluter Startpunkt
	var rel = attack_start - get_viewport_rect().size / 2                      # Vektor von Kreis-Mittelpunkt zum Start
	var a = direction.length_squared()
	var b = 2.0 * rel.dot(direction)
	var c = rel.length_squared() - arena_radius * arena_radius
	var discr = b*b - 4.0*a*c

	if discr >= 0.0:
		var t1 = (-b + sqrt(discr)) / (2.0 * a)
		var t2 = (-b - sqrt(discr)) / (2.0 * a)
		# Nimm das t, das weiter von attack_start entfernt ist (größerer Betrag)
		var t = t1 if abs(t1) > abs(t2) else t2
		# Endpunkt als absolut im Raum berechnen
		var attack_end_global = attack_start + direction * t
		# Line2D arbeitet in lokalen Koordinaten, deshalb Endpunkt in lokalen Bezug
		return attack_end_global
	else:
		# fallback: lang machen
		return attack_start + direction * (arena_radius * 2)

func _on_attack_area_body_entered(body):
	# body ist das eingefallene Objekt – z.B. dein Spieler
	if move_to_target and body.is_in_group("player"):
		body.apply_knockback(attack_indicator_end, knockback_strength, knockback_timer)
