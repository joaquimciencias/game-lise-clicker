extends MarginContainer
# Script conectado à raiz da cena JogoPausado

signal jogo_retomado

func _ready() -> void:
	hide()

func abrir() -> void:
	show()

# Botão de continuar que está DENTRO da cena de pausa
func _on_botao_continuar_pressed() -> void:
	hide()
	# Emitimos o sinal para avisar a cena principal
	jogo_retomado.emit()
