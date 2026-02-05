extends Control
## Displays the game over panel and handles restart/quit actions.

@onready var score_label: Label = $Screen/Score
@onready var highscore_label: RichTextLabel = $Screen/Highscore
@onready var restart_button: Button = $Screen/ButtonContainer/Restart
@onready var quit_button: Button = $Screen/ButtonContainer/Quit

## Hook visibility changes to manage focus.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

## Focus the restart button when the panel becomes visible.
func _on_visibility_changed() -> void:
	if visible:
		call_deferred("setup_focus")

## Grab focus for the restart button.
func setup_focus() -> void:
	restart_button.grab_focus()

## Show the game over panel.
func show_gameover() -> void:
	visible = true

## Set the current run score text.
func set_score(score: float) -> void:
	score_label.text = str("Score: %0.2f" % score)

## Show the highscore badge when applicable.
func set_highscore(is_highscore: bool) -> void:
	if is_highscore:
		highscore_label.show()

## Restart the current scene.
func _on_RestartButton_pressed() -> void:
	visible = false
	get_tree().reload_current_scene()

## Quit the application.
func _on_QuitButton_pressed() -> void:
	get_tree().quit()
