extends Node

# Referência ao nó que guarda os dados (ajuste o caminho se necessário no seu projeto)
@onready var data_handler = $"../DataHandler"
@onready var passive_income_timer = $PassiveIncomeTimer

func _ready() -> void:
	# Conecta o sinal do Timer à nossa função de ganho passivo
	passive_income_timer.timeout.connect(_on_passive_income_timer_timeout)
	print("GameManager: Iniciado com sucesso!")

# Esta função roda a cada 1 segundo graças ao Timer
func _on_passive_income_timer_timeout() -> void:
	calcular_ganho_passivo()

func calcular_ganho_passivo() -> void:
	# Verificamos se o DataHandler existe para evitar erros no console
	if data_handler:
		if data_handler.passive_income > 0:
			data_handler.adicionar_moedas(data_handler.passive_income)
			print("GameManager: Ganho passivo aplicado de +", data_handler.passive_income)
	else:
		print("GameManager Erro: DataHandler não encontrado na árvore!")
