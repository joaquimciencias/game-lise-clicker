extends Node

# Sinais para avisar o resto do jogo que algo mudou
signal moedas_alteradas(nova_quantidade)

# Variáveis de estado do jogo
var coins: int = 0
var passive_income: int = 5 # Começamos com 5 para testar se o GameManager funciona
var coins_per_click: int = 1

func adicionar_moedas(quantidade: int) -> void:
	coins += quantidade
	emit_signal("moedas_alteradas", coins)
	print("DataHandler: Moedas atuais: ", coins)

func realizar_clique() -> void:
	adicionar_moedas(coins_per_click)
