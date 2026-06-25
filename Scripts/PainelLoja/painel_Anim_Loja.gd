extends Panel
# --- ESSE CÓDIGO AQUI SERVE SÓ PARA ANIMAR ENTRE AS ABAS---
# Referências para os botões
@onready var btn_expansao = $VBoxContainer/HBoxBotoes/Expansao
@onready var btn_conscientizacao = $VBoxContainer/HBoxBotoes/Conscientizacao
@onready var btn_formacao = $VBoxContainer/HBoxBotoes/Formacao

# Referências para os conteúdos
@onready var conteudo_expansao = $VBoxContainer/ScrollContainer/ConteudoExpansao
@onready var conteudo_conscientizacao = $VBoxContainer/ScrollContainer/ConteudoConscientizacao
@onready var conteudo_formacao = $VBoxContainer/ScrollContainer/ConteudoFormacao

# Dicionário para facilitar o gerenciamento
var botoes = {}
var conteudos = {}
var aba_atual = ""

func _ready():
	# Preencher os dicionários
	botoes = {
		"expansao": btn_expansao,
		"conscientizacao": btn_conscientizacao,
		"formacao": btn_formacao
	}
	
	conteudos = {
		"expansao": conteudo_expansao,
		"conscientizacao": conteudo_conscientizacao,
		"formacao": conteudo_formacao
	}
	
	# Conectar os sinais dos botões
	for nome in botoes:
		botoes[nome].pressed.connect(_on_aba_pressed.bind(nome))
	
	# Iniciar com a primeira aba visível
	mostrar_aba_com_animacao("expansao")

func _on_aba_pressed(nome: String):
	mostrar_aba_com_animacao(nome)

func atualizar_estilo_botoes(aba_ativa: String):
	for nome in botoes:
		var botao = botoes[nome]
		var estilo = StyleBoxFlat.new()
		
		if nome == aba_ativa:
			# Estilo do botão ativo
			estilo.bg_color = Color(0.3, 0.5, 0.8)  # Azul mais claro
			estilo.border_width_bottom = 3
			estilo.border_color = Color(1, 1, 1)
		else:
			# Estilo do botão inativo
			estilo.bg_color = Color(0.2, 0.2, 0.3)  # Mais escuro
			estilo.border_width_bottom = 0
		
		botao.add_theme_stylebox_override("normal", estilo)
		botao.add_theme_stylebox_override("hover", estilo)
		botao.add_theme_stylebox_override("pressed", estilo)

func mostrar_aba_com_animacao(nome: String):
	# Se já está nessa aba, não faz nada
	if aba_atual == nome:
		return
	
	# Guardar a aba atual
	aba_atual = nome
	
	# Para cada conteúdo
	for chave in conteudos:
		var conteudo = conteudos[chave]
		
		if chave == nome:
			# ABA SELECIONADA: fazer fade in
			animar_entrada(conteudo)
		else:
			# OUTRAS ABAS: fazer fade out
			animar_saida(conteudo)
	atualizar_estilo_botoes(nome)
	
func animar_entrada(conteudo: Node):
	# Garantir que o nó está visível
	conteudo.visible = true
	
	# Criar um Tween
	var tween = create_tween()
	tween.set_parallel(true)  # Permite animar múltiplas propriedades ao mesmo tempo
	
	# Animação de fade in (transparência)
	tween.tween_property(conteudo, "modulate:a", 1.0, 0.3)


func animar_saida(conteudo: Node):
	# Criar um Tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animação de fade out
	tween.tween_property(conteudo, "modulate:a", 0.0, 0.3)
	
	# Quando a animação terminar, esconder o nó
	tween.tween_callback(func(): conteudo.visible = false)
