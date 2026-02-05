extends Node

@export var arena_radius: float = 290.0
@export var enemy_scene: PackedScene
@export var initial_spawn_interval: float = 1.0
@export var min_spawn_interval: float = 0.4
@export var spawn_acceleration: float = 0.015
@export var max_enemys_per_spawn: int = 3

# New tuning for spacing
@export var min_separation_degrees: float = 25.0
@export var max_angle_attempts: int = 20

var elapsed_time: float = 0.0
var spawn_timer: float = 0.0
var spawn_interval: float
var game_over_shown = false
var game_started = false

var taken_angles: Array = []

@onready var player = get_node_or_null("../Player")
@onready var angel_container = get_node_or_null("../AngelContainer")
@onready var hud = get_node_or_null("../HUD")
@onready var startscreen = get_node_or_null("../HUD/Startscreen")
@onready var gameover = get_node_or_null("../Gameover/Gameover")
@onready var bgm: AudioStreamPlayer2D = get_node_or_null("../BGM")
@onready var arena: Sprite2D = get_node_or_null("../Background")

var arena_global_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	randomize()
	if bgm:
		bgm.volume_db -= 10
		bgm.play()
	
	spawn_interval = initial_spawn_interval
	spawn_timer = spawn_interval
	
	# Set arena center to viewport center
	if get_parent():
		arena_global_center = get_parent().get_viewport_rect().size / 2
	
	# Calculate arena radius based on viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	var base_viewport_size = 720.0  # Your original design size
	var base_radius = 290.0  # Your original radius
	var current_size = min(viewport_size.x, viewport_size.y)
	arena_radius = (current_size / base_viewport_size) * base_radius
	
	if hud:
		hud.call_deferred("update_highscore", load_highscore())
		hud.call_deferred("start_timer")
	else:
		push_warning("GameManager: HUD node not found at expected path '../HUD'. " +
				"Bitte Pfad prüfen.")

func _process(delta: float) -> void:
	if not game_started:
		return
	
	if player and player.is_dead:
		on_player_death()
		return
	elapsed_time += delta
	if hud:
		hud.set_time(elapsed_time)
	var interval_change = spawn_acceleration * elapsed_time
	spawn_interval = max(min_spawn_interval, initial_spawn_interval - interval_change)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_spawn_enemys_based_on_time()

func _spawn_enemys_based_on_time() -> void:
	var t = int(elapsed_time / 10)
	var count = clamp(1 + t, 1, max_enemys_per_spawn)
	_spawn_enemys(count)

func _spawn_enemys(count: int) -> void:
	if not enemy_scene:
		push_error("Enemy scene not assigned in GameManager")
		return
	var new_angles = _choose_spawn_angles(count)
	for angle in new_angles:
		_spawn_enemy_at_angle(angle)

func _spawn_enemy_at_angle(angle: float) -> void:
	var spawn_r = arena_radius
	
	var dir = Vector2(cos(angle), sin(angle)).normalized()
	var world_pos = arena_global_center + dir * spawn_r

	var enemy = enemy_scene.instantiate()	
	enemy.global_position = world_pos

	if angel_container:
		angel_container.add_child(enemy)
		enemy.global_position = world_pos
		enemy.arena_radius = arena_radius
	else:
		add_child(enemy)
		enemy.global_position = world_pos

	taken_angles.append(angle)
	var cb = Callable(self, "_on_enemy_removed").bind(angle)
	if not enemy.is_connected("tree_exited", cb):
		enemy.connect("tree_exited", cb)

func _on_enemy_removed(angle: float) -> void:
	for i in range(taken_angles.size()):
		if abs(wrapf(taken_angles[i] - angle, -PI, PI)) < 0.0001:
			taken_angles.remove_at(i)
			return
	
	for i in range(taken_angles.size()):
		if _angle_distance(taken_angles[i], angle) < deg_to_rad(2.0):
			taken_angles.remove_at(i)
			return

func _choose_spawn_angles(count: int) -> Array:
	var chosen: Array = []
	var min_sep_rad = deg_to_rad(min_separation_degrees)
	for n in range(count):
		var best_angle = null
		var best_score := -1.0
		for attempt in range(max_angle_attempts):
			var cand = randf() * TAU
			var min_dist = INF
			for a in taken_angles:
				min_dist = min(min_dist, _angle_distance(a, cand))
			for a in chosen:
				min_dist = min(min_dist, _angle_distance(a, cand))
			if min_dist >= min_sep_rad:
				best_angle = cand
				best_score = min_dist
				break
			if min_dist > best_score:
				best_score = min_dist
				best_angle = cand
		if best_angle == null:
			if chosen.size() == 0:
				return []
			best_angle = wrapf(chosen[chosen.size() - 1] + min_sep_rad, 0.0, TAU)
		chosen.append(best_angle)
	return chosen

func _angle_distance(a: float, b: float) -> float:	
	var diff = wrapf(a - b, -PI, PI)
	return abs(diff)

func save_highscore(time_value: float) -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load("user://highscores.cfg")
	if err != OK:
		cfg = ConfigFile.new()
	if cfg.has_section_key("scores", "best"):
		var best = cfg.get_value("scores", "best")
		if time_value > best:
			cfg.set_value("scores", "best", time_value)
	else:
		cfg.set_value("scores", "best", time_value)
	cfg.save("user://highscores.cfg")

func load_highscore() -> float:
	var cfg = ConfigFile.new()
	if cfg.load("user://highscores.cfg") == OK:
		if cfg.has_section_key("scores", "best"):
			return float(cfg.get_value("scores", "best"))
	return 0.0

func start_game() -> void:
	self.game_started = true
	if startscreen:
			startscreen.visible = false
		

func on_player_death() -> void:
	if game_over_shown:
		return
	game_over_shown = true
	
	if hud:
		hud.stop_timer()
		
	var best = load_highscore()
	if elapsed_time > best:
		if gameover:
			gameover.set_highscore(true)
		save_highscore(elapsed_time)
	if gameover:
		gameover.set_score(elapsed_time)
		gameover.show_gameover()
