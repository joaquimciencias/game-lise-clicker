extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func transition_to_scene(target_scene_path: String) -> void:
	# Permite que o ColorRect receba cliques durante a animação (evita cliques duplos)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Faz a tela escurecer (Fade Out)
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	
	# Troca para a nova cena
	get_tree().change_scene_to_file(target_scene_path)
	
	# Faz a tela clarear de volta (Fade In)
	animation_player.play_backwards("fade_to_black")
	await animation_player.animation_finished
	
	# Libera os cliques do mouse novamente
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
