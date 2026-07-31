extends MarginContainer

@onready var num_atendidas_label: Label = $CenterContainer/HBoxContainer/NumAtendidas

# Variável interna que controla o total
var total_atendidos: int = 0

func _ready() -> void:
	# Garante que começa mostrando o valor inicial (0 ou o que preferir)
	atualizar_display()

# Função que será chamada de fora para atualizar o valor
func adicionar_atendimento() -> void:
	total_atendidos += 1
	atualizar_display()

func atualizar_display() -> void:
	num_atendidas_label.text = str(total_atendidos)
