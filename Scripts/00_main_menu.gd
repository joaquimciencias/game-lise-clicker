extends Control

const CENA_GAME = "res://Scenes/01-game.tscn"
const CENA_OPTIONS = "res://Scenes/02-options.tscn"

func _on_jogar_pressed() -> void:
	TransitionScreen.transition_to_scene(CENA_GAME)

func _on_opcoes_pressed() -> void:
	TransitionScreen.transition_to_scene(CENA_OPTIONS)
