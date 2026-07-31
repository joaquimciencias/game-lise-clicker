extends MarginContainer

@onready var label = $Panel/CenterContainer/Label

# Função que será chamada para configurar a mensagem
# com_animacao = true (padrão para compras)
# com_animacao = false (para eventos aleatórios como ligação interceptada)
func mostrar_mensagem(texto: String, com_animacao: bool = true) -> void:
	label.text = texto
	
	if com_animacao:
		# Inicia a animação suave usando Tween para compras
		var tween = create_tween().set_parallel(true)
		
		# Animação 1: Sobe a posição do popup levemente (efeito flutuar)
		tween.tween_property(self, "position:y", position.y - 60, 4)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
			
		# Animação 2: Efeito de sumir aos poucos
		var cor_invisivel = Color(1, 1, 1, 0)
		tween.tween_property(self, "modulate", cor_invisivel, 1.5)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_IN)
		
		# Quando a animação terminar, remove o popup
		tween.chain().tween_callback(queue_free)
	else:
		# Sem animação de popup flutuante
		modulate.a = 1.0 # Garante que está 100% visível
		
		# Aguarda 3 segundos fixo na tela para o jogador ler a notificação e se destrói
		await get_tree().create_timer(3.0).timeout
		queue_free()
