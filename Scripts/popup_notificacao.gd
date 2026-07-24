extends MarginContainer

@onready var label = $Panel/CenterContainer/Label

# Função que será chamada para configurar a mensagem e iniciar a animação
func mostrar_mensagem(texto: String) -> void:
	label.text = texto
	
	# Inicia a animação suave usando Tween
	var tween = create_tween().set_parallel(true)
	
	# Animação 1: Sobe a posição do popup levemente (efeito flutuar)
	# Move 50 pixels para cima a partir da posição atual do Y
	tween.tween_property(self, "position:y", position.y - 60, 1)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# Animação 2: Efeito de sumir aos poucos (modulate altera a opacidade/alfa)
	# Vai sumindo até ficar totalmente transparente (Color.TRANSPARENT)
	var cor_invisivel = Color(1, 1, 1, 0)
	tween.tween_property(self, "modulate", cor_invisivel, 1)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN)
	
	# Quando as duas animações terminarem, apaga o popup da memória do jogo automaticamente
	tween.chain().tween_callback(queue_free)
