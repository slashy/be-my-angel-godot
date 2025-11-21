extends CanvasLayer

@onready var time_label: Label = get_node_or_null("VBoxContainer/TimeLabel")
@onready var best_label: Label = get_node_or_null("VBoxContainer/BestLabel")
var timer_playing: bool = false

func _ready() -> void:
	if time_label == null:
		push_warning("HUD: TimeLabel not found at 'VBoxContainer/TimeLabel'. Bitte prüfen: Node existiert und heißt genau so.")
	if best_label == null:
		push_warning("HUD: BestLabel not found at 'VBoxContainer/BestLabel'. Bitte prüfen: Node existiert und heißt genau so.")

func start_timer() -> void:
	timer_playing = true

func stop_timer() -> void:
	timer_playing = false

func set_time(t: float) -> void:
	if time_label == null:
		return
	var s = int(t)
	var ms = int((t - s) * 100)
	time_label.text = "Time: %d.%02d" % [s, ms]

func update_highscore(val: float) -> void:
	if best_label == null:
		return
	var s = int(val)
	var ms = int((val - s) * 100)
	best_label.text = "Best: %d.%02d" % [s, ms]
