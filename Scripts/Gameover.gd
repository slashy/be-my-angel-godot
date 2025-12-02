extends Control

@onready var score_label: Label = $Screen/Score
@onready var highscore_label: RichTextLabel = $Screen/Highscore
@onready var restart_button: Button = $Screen/ButtonContainer/Restart
@onready var quit_button: Button = $Screen/ButtonContainer/Quit

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		call_deferred("setup_focus")

func setup_focus():
	restart_button.grab_focus()

func show_gameover():
	visible = true

func set_score(score: float):
	score_label.text = str("Score: %0.2f" % score)

func set_highscore(is_highscore: bool):
	if is_highscore:
		highscore_label.show()

func _on_RestartButton_pressed():
	visible = false
	get_tree().reload_current_scene()

func _on_QuitButton_pressed():
	get_tree().quit()
