extends Label

@onready var data_handler = $"../DataHandler" # Ajuste o caminho até o seu DataHandler

func _ready() -> void:
	if data_handler:
		# Nos inscrevemos no sinal do DataHandler. 
		# Sempre que as moedas mudarem, o texto muda.
		data_handler.moedas_alteradas.connect(_on_moedas_alteradas)
		text = "Moedas: " + str(data_handler.coins)

func _on_moedas_alteradas(nova_quantidade: int) -> void:
	text = "Moedas: " + str(nova_quantidade)
	$"../Pb_Ligacoes".value = nova_quantidade
