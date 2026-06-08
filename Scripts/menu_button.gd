extends Button

# Definimos os tipos de botões que podem existir no jogo
enum ButtonAction { PLAY, OPTIONS, QUIT, BACK, CREDITS }

# Expõe no Inspetor para você escolher o que este botão específico faz
@export var action_type: ButtonAction = ButtonAction.PLAY

# Sinal personalizado que envia o tipo da ação quando clicado
signal menu_button_pressed(action: ButtonAction)

func _ready() -> void:
	# Conecta o sinal padrão do Button à nossa função interna
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Emite o nosso sinal personalizado passando o tipo da ação
	menu_button_pressed.emit(action_type)
