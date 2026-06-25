extends MarginContainer
# --- ESSE CÓDIGO SERVE SÓ PARA ALTERNAR ENTRE AS ABAS DA LOJA ---
@onready var btn_expansao = $PainelAnimLoja/VBoxContainer/HBoxBotoes/Expansao
@onready var btn_conscientizacao = $PainelAnimLoja/VBoxContainer/HBoxBotoes/Conscientizacao
@onready var btn_formacao = $PainelAnimLoja/VBoxContainer/HBoxBotoes/Formacao

@onready var conteudo_expansao = $PainelAnimLoja/VBoxContainer/ScrollContainer/ConteudoExpansao
@onready var conteudo_conscientizacao = $PainelAnimLoja/VBoxContainer/ScrollContainer/ConteudoConscientizacao
@onready var conteudo_formacao = $PainelAnimLoja/VBoxContainer/ScrollContainer/ConteudoFormacao

func _ready():
	# Conectar sinais dos botoes
	btn_expansao.pressed.connect(_on_expansao_pressed)
	btn_conscientizacao.pressed.connect(_on_conscientizacao_pressed)
	btn_formacao.pressed.connect(_on_formacao_pressed)
	
	# Mostrar aba inicial
	mostrar_aba("expansao")

func _on_expansao_pressed():
	mostrar_aba("expansao")

func _on_conscientizacao_pressed():
	mostrar_aba("conscientizacao")

func _on_formacao_pressed():
	mostrar_aba("formacao")

func mostrar_aba(aba: String):
	# Esconder todos os conteudos
	conteudo_expansao.visible = false
	conteudo_conscientizacao.visible = false
	conteudo_formacao.visible = false
	
	# Mostrar apenas o selecionado
	match aba:
		"expansao":
			conteudo_expansao.visible = true
		"conscientizacao":
			conteudo_conscientizacao.visible = true
		"formacao":
			conteudo_formacao.visible = true
