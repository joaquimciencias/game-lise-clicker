# MenuButtonOptions.gd
extends MenuButton

# Criamos um enum para identificar as opções sem usar texto direto (evita bugs de digitação)
enum Options { SAVE_GAME, LOAD_GAME, SETTINGS, QUIT }

var popup: PopupMenu = get_popup()

func _ready() -> void:
	# 1. Adiciona os itens ao menu dropdown
	popup.add_item("Salvar Jogo", Options.SAVE_GAME)
	popup.add_item("Carregar Jogo", Options.LOAD_GAME)
	popup.add_separator() # Adiciona uma linha divisória visual
	popup.add_item("Configurações", Options.SETTINGS)
	popup.add_item("Sair", Options.QUIT)
	
	# 2. Conecta o sinal de clique de um item à nossa função
	popup.id_pressed.connect(_on_item_pressed)

func _on_item_pressed(id: int) -> void:
	# O 'id' recebido corresponde ao valor que definimos no Enum Options
	match id:
		Options.SAVE_GAME:
			print("Salvar selecionado!")
			# Aqui você chamaria seu SaveManager.save_game()
		Options.LOAD_GAME:
			print("Carregar selecionado!")
		Options.SETTINGS:
			print("Abrir painel de configurações.")
		Options.QUIT:
			get_tree().quit() # Fecha o jogo
