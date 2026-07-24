extends MarginContainer

# Declaração do sinal personalizado que envia o tipo de violência conscientizada
signal violencia_conscientizada(tipo: String)
@warning_ignore("unused_signal")
signal relato_respondido
# O sinal agora envia o estado do resultado em vez de apenas um booleano
signal tentativa_respondida(resultado: ResultadoRodada)
# Define os três estados possíveis para o fim de uma rodada
enum ResultadoRodada { CORRETO, ERRADO, TIMEOUT }

# Referências aos nós de UI (Ajuste os caminhos se necessário)
@onready var progress_bar: ProgressBar = $HBoxContainer/VBoxContainer/HBoxContainer/ProgressBar
@onready var lbl_tempo: Label = $HBoxContainer/VBoxContainer/HBoxContainer/lbl_tempo
@onready var timer: Timer = $TempoAtendimento

@onready var btn_fisica: Button = $HBoxContainer/VBoxContainer/GridContainer/ButtonFisica
@onready var btn_psicologica: Button = $HBoxContainer/VBoxContainer/GridContainer/ButtonPsicologica
@onready var btn_moral: Button = $HBoxContainer/VBoxContainer/GridContainer/ButtonMoral
@onready var btn_patrimonial: Button = $HBoxContainer/VBoxContainer/GridContainer/ButtonPatrimonial

@onready var panel_resposta: Panel = $HBoxContainer/VBoxContainer/Panel/PanelResposta
@onready var lbl_resposta: Label = $HBoxContainer/VBoxContainer/Panel/PanelResposta/MarginContainer/VBoxContainer/Resposta
@onready var lbl_valor_conscientizacao: Label = $HBoxContainer/VBoxContainer/Panel/PanelResposta/MarginContainer/VBoxContainer/ValorConscientizacao

# Variável para controlar o Tween da barra
var tween_barra: Tween

var painel_fila: MarginContainer

# Lista que guardará todos os relatos do jogo
var lista_de_relatos: Array[Dictionary] = [
	{
		"texto": "Ao tentar me separar, descobri que meu marido havia transferido todos os bens do casal para o nome da família dele sem meu conhecimento.",
		"tipo": "Patrimonial"
	},
	{
		"texto": "Ele me empurrou contra a parede e segurou meus braços com tanta força que ficaram marcas roxas, dizendo que eu não sairia de casa.",
		"tipo": "Física"
	},
	{
		"texto": "Ele vive me insultando na frente dos nossos amigos, dizendo que sou incapaz, burra e que ninguém nunca vai me aceitar além dele.",
		"tipo": "Psicológica"
	},
	{
		"texto": "Ele inventou mentiras maldosas sobre o meu comportamento no trabalho e espalhou para todos os vizinhos para destruir a minha reputação.",
		"tipo": "Moral"
	}
]

# Variáveis para controlar o relato atual
var relato_atual: Dictionary
@onready var lbl_relato_titulo: Label = $HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/lblRelatoTitulo
@onready var lbl_relato: Label = $HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/lblRelato

func _ready():
# ESSENCIAL: Faz o painel responder às mudanças do jogo ou continuar em standby
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	panel_resposta.visible = false
	panel_resposta.modulate.a = 0.0
	randomize() 
	
	# Configura o timer para processar corretamente no tempo do jogo (idle process)
	if timer:
		timer.process_callback = Timer.TIMER_PROCESS_IDLE
		timer.timeout.connect(_on_tempo_esgotado)

# Configuração essencial da barra
	progress_bar.max_value = timer.wait_time
	progress_bar.min_value = 0.0
	progress_bar.step = 0.0 # Garante que não haja travas de arredondamento
	progress_bar.value = timer.wait_time # Começa cheia

	# Configura a cor inicial (Verde #4ade80)
	atualizar_cor_barra(1.0)
	
	btn_fisica.pressed.connect(_on_botao_violencia_pressionado.bind("Física"))
	btn_psicologica.pressed.connect(_on_botao_violencia_pressionado.bind("Psicológica"))
	btn_moral.pressed.connect(_on_botao_violencia_pressionado.bind("Moral"))
	btn_patrimonial.pressed.connect(_on_botao_violencia_pressionado.bind("Patrimonial"))
	
	carregar_novo_relato()

func _process(_delta: float) -> void:
# A animação da BARRA é controlada pelo iniciar_novo_tempo()
	if timer and timer.time_left > 0:
		lbl_tempo.text = str(ceilf(timer.time_left)) + "s"
		
		# Atualiza a cor baseada na porcentagem REAL do timer
		atualizar_cor_barra(timer.time_left / timer.wait_time)


func atualizar_cor_barra(porcentagem: float) -> void:
	var style_fill = progress_bar.get_theme_stylebox("fill")
	
	if style_fill is StyleBoxFlat:
		if porcentagem > 0.5:
			# Verde principal #4ade80
			style_fill.bg_color = Color("4ade80")
		elif porcentagem > 0.25:
			# Amarelo harmonizado #facc15
			style_fill.bg_color = Color("facc15")
		else:
			# Vermelho harmonizado #f87171
			style_fill.bg_color = Color("f87171")


func retomar_atendimento() -> void:
	if timer.is_paused():
		timer.paused = false
		# Retoma o tween também se necessário (embora o iniciar_novo_tempo() costume resolver)
		if tween_barra:
			tween_barra.paused = false
	elif timer.is_stopped() and not lista_de_relatos.is_empty():
		iniciar_novo_tempo()


func iniciar_novo_tempo() -> void:
	timer.paused = false
	timer.start()
	
	# Garante que a barra comece cheia visualmente antes de descer suavemente
	progress_bar.value = timer.wait_time
	
	# Mata o tween anterior se houver para não sobrecarregar
	if tween_barra:
		tween_barra.kill()
		
	# Cria um novo Tween para animar a descida suave
	tween_barra = create_tween()
	
	# Anima a propriedade 'value' da progress_bar do valor atual até 0
	# durante o tempo exato do timer (timer.wait_time).
	# TRANS_SINE + EASE_OUT criam o efeito de "água fluida" que desacelera suavemente.
	tween_barra.tween_property(progress_bar, "value", 0.0, timer.wait_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)



func carregar_novo_relato() -> void:
	# CASO DE TESTE: Se não houver referência da fila ou a fila estiver vazia, limpa a tela e para
	if painel_fila == null or painel_fila.esta_vazia():
		lbl_relato.text = "Nenhum atendimento pendente. Aguardando novos relatos..."
		lbl_relato_titulo.text = "PAINEL VAZIO"
		timer.stop()
		# Bloqueia/Desativa os botões para o jogador não clicar no vazio
		btn_fisica.disabled = true
		btn_psicologica.disabled = true
		btn_moral.disabled = true
		btn_patrimonial.disabled = true
		return

	# Se houver mulheres, reativa os botões e segue o fluxo normal
	btn_fisica.disabled = false
	btn_psicologica.disabled = false
	btn_moral.disabled = false
	btn_patrimonial.disabled = false

	#if lista_de_relatos.is_empty():
		#lbl_relato.text = "Todos os relatos foram analisados!"
		#timer.stop()
		#return

	# (O restante do seu código original de sorteio continua igual daqui para baixo...)
	var indice_aleatorio = randi() % lista_de_relatos.size()
	
	# COMENTADO PARA NÃO APAGAR O RELATO DA LISTA:
	#relato_atual = lista_de_relatos.pop_at(indice_aleatorio) #NÃO COMENTE QUER QUE APAGUE
	
	# NOVA LINHA: Apenas pega o relato usando o índice, mantendo-o na lista
	relato_atual = lista_de_relatos[indice_aleatorio] #DESCOMENTE SE QUER QUE SEJA ALEATORIO E NÃO APAGUE
	lbl_relato.text = relato_atual["texto"]
	lbl_relato_titulo.text = "RELATO RECEBIDO"
	iniciar_novo_tempo()

func _on_botao_violencia_pressionado(tipo_escolhido: String) -> void:
	timer.stop()
	
	# Para a animação da barra instantaneamente
	if tween_barra:
		tween_barra.kill()

	if tipo_escolhido == relato_atual["tipo"]:
		print("Acertou! Tipo conscientizado: ", tipo_escolhido)
		violencia_conscientizada.emit(tipo_escolhido)
		emit_signal("tentativa_respondida", ResultadoRodada.CORRETO)
	else:
		print("Errou! O correto era: ", relato_atual["tipo"])
		emit_signal("tentativa_respondida", ResultadoRodada.ERRADO)

	# IMPORTANTE: A chamada para carregar_novo_relato() será controlada após o feedback!


func _on_tempo_esgotado() -> void:
	# Para a animação da barra (embora ela já deva estar em 0)
	if tween_barra:
		tween_barra.kill()
	print("O tempo acabou antes de responder!")
	emit_signal("tentativa_respondida", ResultadoRodada.TIMEOUT)

# Função genérica de feedback que recebe a flag de acerto e o valor que veio do Main
func exibir_feedback(correto: bool, valor_conscientizacao: float) -> void:
	# 🔒 DESATIVA os botões assim que o feedback inicia
	definir_botoes_ativos(false)

	# Define a cor e os textos do feedback
	var cor_feedback: Color
	if correto:
		cor_feedback = Color("47d162") # Verde
		lbl_resposta.text = "Correto!"
		lbl_valor_conscientizacao.text = "+" + str(valor_conscientizacao) + "% Conscientização"
	else:
		cor_feedback = Color("e63946") # Vermelho
		lbl_resposta.text = "Incorreto!"
		lbl_valor_conscientizacao.text = str(valor_conscientizacao) + "% Conscientização"

	lbl_resposta.modulate = cor_feedback
	lbl_valor_conscientizacao.modulate = cor_feedback

	# Exibe o painel de resposta com fade in
	panel_resposta.visible = true
	panel_resposta.modulate.a = 0.0

	var tween_in = create_tween()
	tween_in.tween_property(panel_resposta, "modulate:a", 1.0, 0.3)
	await tween_in.finished

	# Tempo de leitura do feedback
	await get_tree().create_timer(1.0).timeout

	# Oculta o painel de resposta com fade out
	var tween_out = create_tween()
	tween_out.tween_property(panel_resposta, "modulate:a", 0.0, 0.3)
	await tween_out.finished

	panel_resposta.visible = false

	# 🔓 REATIVA os botões somente depois que o feedback sumir completamente
	# (Note que a função carregar_novo_relato também validará se há itens na fila)
	definir_botoes_ativos(true)

# Ativa ou desativa a interação com os botões de resposta
func definir_botoes_ativos(ativo: bool) -> void:
	btn_fisica.disabled = not ativo
	btn_psicologica.disabled = not ativo
	btn_moral.disabled = not ativo
	btn_patrimonial.disabled = not ativo
