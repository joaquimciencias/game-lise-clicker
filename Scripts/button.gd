extends Button # Ou TextureButton, dependendo do nó que você usou

@onready var data_handler = $"../DataHandler" # Ajuste o caminho até o seu DataHandler

func _ready() -> void:
	# Conecta o clique do botão diretamente à função correspondente
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if data_handler:
		data_handler.realizar_clique()
