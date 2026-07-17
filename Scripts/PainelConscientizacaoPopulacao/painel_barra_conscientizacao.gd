extends MarginContainer # Ajuste se o nó raiz for Control ou Panel

@onready var progress_bar: ProgressBar = $VBoxContainer/HBoxContainer/ProgressBar

func _ready() -> void:
	# Define os limites padrão da barra (0% a 100%)
	progress_bar.max_value = 100.0
	progress_bar.min_value = 0.0
	definir_conscientizacao(0.0) # Começa zerada

## Função exposta para a Main atualizar o valor da barra diretamente
func definir_conscientizacao(valor: float) -> void:
	if progress_bar:
		# Modifica o valor da ProgressBar (o próprio motor cuida do preenchimento)
		progress_bar.value = clamp(valor, 0.0, 100.0)
