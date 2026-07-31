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

@onready var som_acerto: AudioStreamPlayer = $SomAcerto
@onready var som_erro: AudioStreamPlayer = $SomErro

# Variável para controlar o Tween da barra
var tween_barra: Tween

var painel_fila: MarginContainer

# Puxa todos os relatos lá de dentro do 'RelatosData'
var lista_de_relatos: Array[Dictionary] = RelatosData.get_todos_os_relatos()

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
	
	# Embaralha a lista inicial para que o jogo comece com uma ordem aleatória
	lista_de_relatos.shuffle()
	
	# Configura o timer para processar corretamente no tempo do jogo (idle process)
	if timer:
		timer.process_callback = Timer.TIMER_PROCESS_IDLE
		timer.timeout.connect(_on_tempo_esgotado)

	# Configuração essencial da barra
	progress_bar.max_value = timer.wait_time
	progress_bar.min_value = 0.0
	progress_bar.step = 0.0 
	progress_bar.value = timer.wait_time 

	# Configura a cor inicial (Verde #4ade80)
	atualizar_cor_barra(1.0)
	
	btn_fisica.pressed.connect(_on_botao_violencia_pressionado.bind("Física"))
	btn_psicologica.pressed.connect(_on_botao_violencia_pressionado.bind("Psicológica"))
	btn_moral.pressed.connect(_on_botao_violencia_pressionado.bind("Moral"))
	btn_patrimonial.pressed.connect(_on_botao_violencia_pressionado.bind("Patrimonial"))
	
	carregar_novo_relato()

func _process(_delta: float) -> void:
	if timer and timer.time_left > 0:
		lbl_tempo.text = str(ceilf(timer.time_left)) + "s"
		atualizar_cor_barra(timer.time_left / timer.wait_time)


func atualizar_cor_barra(porcentagem: float) -> void:
	var style_fill = progress_bar.get_theme_stylebox("fill")
	
	if style_fill is StyleBoxFlat:
		if porcentagem > 0.5:
			style_fill.bg_color = Color("4ade80")
		elif porcentagem > 0.25:
			style_fill.bg_color = Color("facc15")
		else:
			style_fill.bg_color = Color("f87171")


func retomar_atendimento() -> void:
	if timer.is_paused():
		timer.paused = false
	elif timer.is_stopped() and not lista_de_relatos.is_empty():
		iniciar_novo_tempo()


func iniciar_novo_tempo() -> void:
	timer.paused = false
	timer.start()
	
	progress_bar.value = timer.wait_time
	
	if tween_barra:
		tween_barra.kill()
		
	tween_barra = create_tween()
	tween_barra.tween_property(progress_bar, "value", 0.0, timer.wait_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func carregar_novo_relato() -> void:
	if lista_de_relatos.is_empty():
		lbl_relato.text = "Nenhum atendimento pendente. Aguardando novos relatos..."
		lbl_relato_titulo.text = "PAINEL VAZIO"
		timer.stop()
		btn_fisica.disabled = true
		btn_psicologica.disabled = true
		btn_moral.disabled = true
		btn_patrimonial.disabled = true
		return

	btn_fisica.disabled = false
	btn_psicologica.disabled = false
	btn_moral.disabled = false
	btn_patrimonial.disabled = false

	# =========================================================================
	# MUDANÇA AQUI: Pegamos sempre o primeiro relato da fila atual.
	# O relato atual é retirado temporariamente da frente.
	# =========================================================================
	relato_atual = lista_de_relatos.pop_front()
	
	# Joga o relato que acabou de sair para o ÚLTIMO lugar da fila.
	# Assim, ele só vai poder ser sorteado de novo quando todos os outros 
	# passarem pela tela primeiro.
	lista_de_relatos.append(relato_atual)

	lbl_relato.text = relato_atual["texto"]
	lbl_relato_titulo.text = "RELATO RECEBIDO"


func _on_botao_violencia_pressionado(tipo_escolhido: String) -> void:
	timer.stop()
	
	if tween_barra:
		tween_barra.kill()

	if tipo_escolhido == relato_atual["tipo"]:
		print("Acertou! Tipo conscientizado: ", tipo_escolhido)
		violencia_conscientizada.emit(tipo_escolhido)
		emit_signal("tentativa_respondida", ResultadoRodada.CORRETO)
	else:
		print("Errou! O correto era: ", relato_atual["tipo"])
		emit_signal("tentativa_respondida", ResultadoRodada.ERRADO)


func _on_tempo_esgotado() -> void:
	if tween_barra:
		tween_barra.kill()
	print("O tempo acabou antes de responder!")
	emit_signal("tentativa_respondida", ResultadoRodada.TIMEOUT)


func exibir_feedback(correto: bool, valor_conscientizacao: float) -> void:
	definir_botoes_ativos(false)

	var cor_feedback: Color
	if correto:
		cor_feedback = Color("47d162")
		lbl_resposta.text = "Correto!"
		lbl_valor_conscientizacao.text = "+" + str(valor_conscientizacao) + "% Conscientização"
		som_acerto.play()
	else:
		cor_feedback = Color("e63946")
		lbl_resposta.text = "Incorreto!"
		lbl_valor_conscientizacao.text = str(valor_conscientizacao) + "% Conscientização"
		som_erro.play()

	lbl_resposta.modulate = cor_feedback
	lbl_valor_conscientizacao.modulate = cor_feedback

	panel_resposta.visible = true
	panel_resposta.modulate.a = 0.0

	var tween_in = create_tween()
	tween_in.tween_property(panel_resposta, "modulate:a", 1.0, 0.3)
	await tween_in.finished

	await get_tree().create_timer(1.0).timeout

	var tween_out = create_tween()
	tween_out.tween_property(panel_resposta, "modulate:a", 0.0, 0.3)
	await tween_out.finished

	panel_resposta.visible = false

	definir_botoes_ativos(true)

	carregar_novo_relato()
	iniciar_novo_tempo()


func definir_botoes_ativos(ativo: bool) -> void:
	btn_fisica.disabled = not ativo
	btn_psicologica.disabled = not ativo
	btn_moral.disabled = not ativo
	btn_patrimonial.disabled = not ativo
