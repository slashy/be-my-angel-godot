extends CharacterBody2D
## Player controller for movement, animations, and knockback.

const DIRECTIONS: Dictionary = {
	Vector2(0, -1): "up",
	Vector2(0, 1): "down",
	Vector2(-1, 0): "left",
	Vector2(1, 0): "right",	
	Vector2(1, 1): "down_right",
	Vector2(-1, 1): "down_left",
	Vector2(-1, -1): "up_left",
	Vector2(1, -1): "up_right",
}

@export var move_speed: float = 250.0
var last_direction: String = "down"
var is_dead: bool = false
var knockback_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var input_velocity: Vector2 = Vector2.ZERO

@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var gm: Node = get_node("../GameManager")


## Center the player at the arena origin.
func _ready() -> void:
	var arena_center = get_viewport_rect().size / 2
	position = arena_center
	
func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if self.is_dead:
		return
		
	if is_outside_arena():
		self.is_dead = true
		death_sound.play(0.3)
		$AnimatedSprite2D.play("dead")
		return
	
	if knockback_timer > 0.0:
		$AnimatedSprite2D.play("knockback")
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			velocity = Vector2.ZERO
	else:
		velocity = direction * move_speed
		if velocity != Vector2.ZERO:
			gm.start_game()
			last_direction = DIRECTIONS[map_to_diagonal_dir(velocity)]
			$AnimatedSprite2D.play("walk_" + last_direction)
		else:
			$AnimatedSprite2D.play("idle_" + last_direction)	

	move_and_slide()
	
## Apply temporary knockback velocity away from a target position.
func apply_knockback(target_position: Vector2, strength: float, duration: float) -> void:
	if knockback_timer > 0.0:
		return
	var dir = (target_position - global_position).normalized()
	velocity = dir * strength
	knockback_timer = duration
	
	if hit_sound:
		hit_sound.play(0.3)
	
func map_to_diagonal_dir(vec: Vector2) -> Vector2:
	return Vector2(sign(vec.x), sign(vec.y))
	
## Check whether the player has left the arena radius.
func is_outside_arena() -> bool:
	if gm == null:
		return false
	var arena_radius = gm.arena_radius
	var arena_center = get_viewport_rect().size / 2
	var distance = global_position.distance_to(arena_center)
	return distance > arena_radius
