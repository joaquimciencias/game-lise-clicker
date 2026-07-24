extends MarginContainer
# Script conectado à raiz da cena JogoPausado

signal jogo_retomado

func _ready() -> void:
	add_to_group("janelas_pausa")
	hide()

func abrir() -> void:
	show()

# Botão de continuar que está DENTRO da cena de pausa
func _on_botao_continuar_pressed() -> void:
	hide()
	# Emitimos o sinal para avisar a cena principal
	jogo_retomado.emit()
