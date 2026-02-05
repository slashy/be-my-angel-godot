extends CanvasLayer
## Displays the timer and best score during gameplay.

@onready var time_label: Label = get_node_or_null("VBoxContainer/TimeLabel")
@onready var best_label: Label = get_node_or_null("VBoxContainer/BestLabel")
var timer_playing: bool = false

## Initialize HUD scaling and warn on missing labels.
func _ready() -> void:
	# Ensure HUD doesn't scale with the game world
	follow_viewport_enabled = false
	# Keep UI at native resolution
	transform = Transform2D.IDENTITY
	
	if time_label == null:
		push_warning(
			"HUD: TimeLabel not found at 'VBoxContainer/TimeLabel'. " +
			"Check the node name and path."
		)
	if best_label == null:
		push_warning(
			"HUD: BestLabel not found at 'VBoxContainer/BestLabel'. " +
			"Check the node name and path."
		)

func start_timer() -> void:
	timer_playing = true

func stop_timer() -> void:
	timer_playing = false

## Update the on-screen timer.
func set_time(t: float) -> void:
	if time_label == null:
		return
	var s = int(t)
	var ms = int((t - s) * 100)
	time_label.text = "Time: %d.%02d" % [s, ms]

## Update the best time display.
func update_highscore(val: float) -> void:
	if best_label == null:
		return
	var s = int(val)
	var ms = int((val - s) * 100)
	best_label.text = "Best: %d.%02d" % [s, ms]
