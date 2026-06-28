extends MarginContainer

# Pegando a referência dos 4 labels de texto "Num" baseados na hierarquia da sua imagem
@onready var lbl_fisica = $VBoxContainer/VBoxContainer/Fisicas/HBoxContainer/Num
@onready var lbl_psicologica = $VBoxContainer/VBoxContainer/Psicologicas/HBoxContainer/Num
@onready var lbl_moral = $VBoxContainer/VBoxContainer/Morais/HBoxContainer/Num
@onready var lbl_patrimonial = $VBoxContainer/VBoxContainer/Patrimoniais/HBoxContainer/Num

# Contadores individuais
var cont_fisica: int = 0
var cont_psicologica: int = 0
var cont_moral: int = 0
var cont_patrimonial: int = 0

func _ready() -> void:
	# Zera os textos no início do jogo
	lbl_fisica.text = "0"
	lbl_psicologica.text = "0"
	lbl_moral.text = "0"
	lbl_patrimonial.text = "0"

# Esta função será chamada pela cena Game. 
# O "match" funciona como vários "ifs", checando qual número chegou.
func registrar_novo_caso(tipo_recebido: int) -> void:
	match tipo_recebido:
		0: # Equivalente ao TipoViolencia.FISICA
			cont_fisica += 1
			lbl_fisica.text = str(cont_fisica)
		1: # Equivalente ao TipoViolencia.PSICOLOGICA
			cont_psicologica += 1
			lbl_psicologica.text = str(cont_psicologica)
		2: # Equivalente ao TipoViolencia.MORAL
			cont_moral += 1
			lbl_moral.text = str(cont_moral)
		3: # Equivalente ao TipoViolencia.PATRIMONIAL
			cont_patrimonial += 1
			lbl_patrimonial.text = str(cont_patrimonial)
