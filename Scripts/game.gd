extends Control

# 1. Carrega a cena do popup na raiz do jogo
const POPUP_NOTIFICACAO_SCENE = preload("res://Scenes/popup_notificacao.tscn")

# Cenas dos Eventos Extras mapeadas por porcentagem da barra (25%, 50%, 75%)
# Ajuste os caminhos das cenas de 50% e 75% conforme suas pastas
const EVENTOS_EXTRAS = {
	25.0: preload("res://Scenes/Eventos/evento_25.tscn"),
	50.0: preload("res://Scenes/Eventos/evento_50.tscn"), # Substitua pela cena do evento de 50%
	75.0: preload("res://Scenes/Eventos/evento_75.tscn")  # Substitua pela cena do evento de 75%
}

const CENA_VITORIA_DERROTA := "res://Scenes/Paineis/Painel_Vitoria_Derrota.tscn"

# Constantes de impacto na conscientização da população
const CORRECT_GAIN: float = 3.0
const WRONG_PENALTY: float = -1.0
const TIMEOUT_PENALTY: float = -0.5

@onready var painel_topo: Control = $Painel_Topo_Inicial
@onready var painel_atendimento: Control = $Painel_Atendimento
@onready var painel_fila_mulheres = $Painel_Fila_Mulheres
@onready var pnl_conscientizacao: Control = $Painel_Tipos_Conscientizados
@onready var pnl_barra_conscientizacao: Control = $Painel_Barra_Conscientizacao
@onready var painel_resultado_acoes: Control = $Painel_ResultadoAcoes

@onready var jogo_pausado: MarginContainer = $JogoPausado

@onready var lbl_animacao_dia: Label = $LabelAnimacaoDia

# Variáveis para controle das estatísticas do Topo
var total_tentativas: int = 0
var total_acertos: int = 0

var dias_totais: int = 30
var dias_restantes: int = 30 #------ COLOQUE AQUI O VALOR DOS DIAS RESTANTES

# Estado global da conscientização (0.0 a 100.0)
var conscientizacao_atual: float = 0.0

# Registro dos eventos extras que já foram acionados para não repetir
var eventos_disparados: Array[float] = []

var pressed = false

var contador_relatos_loja: int = 0

var jogo_finalizado: bool = false
var tempo_jogo_segundos: float = 0.0
var total_ligacoes: int = 0

func _ready() -> void:
# --- ADICIONE ESTA LINHA AQUI ---
	if get_node_or_null("/root/UpgradesManager"):
		if not UpgradesManager.ponto_passivo_gerado.is_connected(_on_ponto_passivo_gerado):
			UpgradesManager.ponto_passivo_gerado.connect(_on_ponto_passivo_gerado)

	# Conecta a atualização dos Upgrades ao fluxo do Game
	UpgradesManager.atributos_atualizados.connect(_on_atributos_upgrades_atualizados)
	_on_atributos_upgrades_atualizados() # Aplica os valores iniciais
	carregar_tutorial()
	# Conecta o sinal global do minigame vindo do EventBus
	EventBus.minigame_finalizado.connect(_on_minigame_extra_concluido)

	painel_atendimento.violencia_conscientizada.connect(_on_violencia_computada)
	painel_atendimento.relato_respondido.connect(_on_relato_concluido)
	painel_atendimento.painel_fila = painel_fila_mulheres
	painel_atendimento.carregar_novo_relato()
	jogo_pausado.jogo_retomado.connect(_on_jogo_retomado)

	# --- CONEXÕES PARA O PAINEL SUPERIOR ---
	painel_atendimento.tentativa_respondida.connect(_on_tentativa_atendimento_processada)

	if pnl_conscientizacao:
		pnl_conscientizacao.pontos_atualizados.connect(_on_pontos_conscientizacao_atualizados)

	if painel_topo:
		painel_topo.atualizar_dias(dias_restantes, dias_totais)

	var loja = get_tree().get_first_node_in_group("loja_principal")
	if loja:
		loja.compra_finalizada_com_sucesso.connect(criar_popup_na_tela_cheia)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		conscientizacao_atual+=15
	if not jogo_finalizado:
		tempo_jogo_segundos += delta
	


func _on_violencia_computada(tipo: String) -> void:
	# 1. Normaliza a string para minúsculas e sem acentos para o EventBus
	var tipo_limpo := tipo.to_lower()
	if "fisic" in tipo_limpo:
		tipo_limpo = "fisica"
	elif "psico" in tipo_limpo:
		tipo_limpo = "psicologica"
	elif "mora" in tipo_limpo:
		tipo_limpo = "moral"
	elif "patri" in tipo_limpo:
		tipo_limpo = "patrimonial"

	# 2. Atualiza o painel visual
	if pnl_conscientizacao and pnl_conscientizacao.has_method("atualizar_contador"):
		pnl_conscientizacao.atualizar_contador(tipo)
	
	# 3. Registra o ponto acumulado no EventBus usando a chave padronizada (sem acento)
	EventBus.adicionar_registro(tipo_limpo, 1)

func _on_botao_pausa_pressed() -> void:
	get_tree().paused = true
	jogo_pausado.abrir()

func _on_jogo_retomado() -> void:
	get_tree().paused = false 

func criar_popup_na_tela_cheia(texto_recebido: String, com_animacao: bool = true) -> void:
	var novo_popup = POPUP_NOTIFICACAO_SCENE.instantiate()
	add_child(novo_popup) 
	novo_popup.mostrar_mensagem(texto_recebido, com_animacao)

func _on_relato_concluido():
	painel_fila_mulheres.avancar_fila()

# Chamado sempre que o jogador clica em um botão ou o tempo esgota
# Substitua a sua _on_tentativa_atendimento_processada por esta:
func _on_tentativa_atendimento_processada(resultado: int) -> void:
	total_tentativas += 1
	var delta: float = 0.0
	var acertou: bool = false
	
	match resultado:
		0: # CORRETO (ResultadoRodada.CORRETO)
			total_acertos += 1
			delta = CORRECT_GAIN
			acertou = true
			EventBus.atendimento_classificacao_correta.emit()
		1: # ERRADO (ResultadoRodada.ERRADO)
			delta = WRONG_PENALTY
			acertou = false
			EventBus.atendimento_classificacao_errada.emit()
		2: # TIMEOUT (ResultadoRodada.TIMEOUT)
			delta = TIMEOUT_PENALTY
			acertou = false
			EventBus.atendimento_ligacao_perdida.emit()

	if painel_resultado_acoes and painel_atendimento.relato_atual:
		var categoria: String = painel_atendimento.relato_atual.get("tipo", "Ação")
		painel_resultado_acoes.mostrar_acao(categoria, resultado, delta)

	# 1. Atualiza a precisão geral do topo
	var precisao_atual: float = 100.0
	if total_tentativas > 0:
		precisao_atual = (float(total_acertos) / float(total_tentativas)) * 100.0
	
	if painel_topo:
		painel_topo.atualizar_precisao(precisao_atual)
	
	# 2. Atualiza a barra de conscientização da população
	conscientizacao_atual = clamp(conscientizacao_atual + delta, 0.0, 100.0)
	
	if pnl_barra_conscientizacao:
		pnl_barra_conscientizacao.definir_conscientizacao(conscientizacao_atual)
	
	EventBus.conscientizacao_alterada.emit(conscientizacao_atual)

	# 3. CHAMA O FEEDBACK NO PAINEL COM O VALOR DAS CONSTANTES DO MAIN:
	if painel_atendimento and painel_atendimento.has_method("exibir_feedback"):
		# Aguarda a animação do Fade In e Fade Out terminar
		await painel_atendimento.exibir_feedback(acertou, delta)

		if conscientizacao_atual >= 100.0:
			await _finalizar_jogo(true)
			return
		
		# Avança a fila visual de mulheres
		_on_relato_concluido()
		
		# INCREMENTA O CONTADOR
		contador_relatos_loja += 1

		# 🛒 A CADA 4 RELATOS: ABRE A LOJA
		if contador_relatos_loja >= 4:
			contador_relatos_loja = 0 # Reseta o contador para os próximos 4
			abrir_loja_automatica()
		else:
			# Se ainda não completou 4, carrega o próximo relato normalmente
			painel_atendimento.carregar_novo_relato()
		
	# 4. Verifica os gatilhos dos eventos extras (25%, 50%, 75%)
	verificar_eventos_extras()

# --- SISTEMA GENÉRICO DE EVENTOS EXTRAS ---

func verificar_eventos_extras() -> void:
	for limiar in EVENTOS_EXTRAS.keys():
		if conscientizacao_atual >= limiar and not limiar in eventos_disparados:
			eventos_disparados.append(limiar)
			disparar_alerta_evento_extra(limiar)
			break # Dispara apenas um por rodada para evitar sobreposição

func disparar_alerta_evento_extra(limiar: float) -> void:
	print("ALERTA: Evento extra de %d%% será iniciado em 3 segundos!" % int(limiar))
	
	# Exibe o aviso sem a animação de popup de compra
	criar_popup_na_tela_cheia("⚠️ AVISO: LIGAÇÃO INTERCEPTADA!", false)
	
	# O segundo argumento (process_always = false) garante que o timer de 3s
	# rode mesmo se o jogo estiver com paused = true
	await get_tree().create_timer(3.0, false, false, false).timeout
	
	iniciar_minigame_extra(limiar)

func iniciar_minigame_extra(limiar: float) -> void:
	var cena_evento: PackedScene = EVENTOS_EXTRAS[limiar]
	var minigame = cena_evento.instantiate()
	
	# Passa o limiar para o minigame saber qual porcentagem ele representa
	if "limiar_evento" in minigame:
		minigame.limiar_evento = limiar
		
	add_child(minigame)


func _on_minigame_extra_concluido(sucesso: bool, limiar: float) -> void:
	if sucesso:
		print("Sucesso no evento de %d%%! Ação rápida acionada." % int(limiar))
		conscientizacao_atual = clamp(conscientizacao_atual + 5.0, 0.0, 100.0)
	else:
		print("Falha no evento de %d%%! Demora na resposta." % int(limiar))
		conscientizacao_atual = clamp(conscientizacao_atual - 3.0, 0.0, 100.0)
	
	EventBus.conscientizacao_alterada.emit(conscientizacao_atual)
	
	if pnl_barra_conscientizacao:
		pnl_barra_conscientizacao.definir_conscientizacao(conscientizacao_atual)
		
	# RETOMADA FORÇADA: Garante que o painel volte a contar o tempo do relato ativo
	if painel_atendimento and painel_atendimento.has_method("retomar_atendimento"):
		painel_atendimento.retomar_atendimento()


func _on_pontos_conscientizacao_atualizados(total_pontos: int) -> void:
	total_ligacoes = total_pontos
	if painel_topo:
		painel_topo.atualizar_ligacoes(total_pontos)

func abrir_loja_automatica() -> void:
	var loja = get_tree().get_first_node_in_group("loja_principal")
	
	# Busca por nó caso a loja ainda não esteja no grupo
	if not loja and has_node("Painel_Main_Loja"):
		loja = $Painel_Main_Loja

	if loja:
		# Conecta o sinal de fechamento da loja para saber quando retomar os atendimentos
		if loja.has_signal("loja_fechada") and not loja.loja_fechada.is_connected(_on_loja_fechada_retomar):
			loja.loja_fechada.connect(_on_loja_fechada_retomar)
		
		# Pausa o tempo do atendimento enquanto a loja estiver aberta
		if painel_atendimento and painel_atendimento.timer:
			painel_atendimento.timer.paused = true
			
		loja.show()
		
		# Atualiza os valores dos recursos dentro da loja ao abrir
		if loja.has_method("_atualizar_todos_os_itens"):
			loja._atualizar_todos_os_itens()


# Chamado automaticamente quando o jogador clica no botão "Fechar" da loja
# Chamado automaticamente quando o jogador clica no botão "Fechar" da loja
func _on_loja_fechada_retomar() -> void:
	print("🛍️ Loja fechada. Reduzindo dia e retomando os atendimentos...")
	
	await animar_reducao_de_dia()

	if jogo_finalizado:
		return
	
	if painel_atendimento:
		painel_atendimento.carregar_novo_relato()


func animar_reducao_de_dia() -> void:
	# 1. Reduz a lógica do dia
	dias_restantes -= 1
	
	# Caso os nós de interface não existam por segurança, interrompe
	if not lbl_animacao_dia or not painel_topo:
		return

	# 2. Configura o texto e a posição inicial (Centro da Tela)
	lbl_animacao_dia.text = "-1 Dia" # Ou "Dia " + str(dias_restantes)
	lbl_animacao_dia.visible = true
	
	var tamanho_tela = get_viewport_rect().size
	lbl_animacao_dia.global_position = (tamanho_tela / 2) - (lbl_animacao_dia.size / 2)
	lbl_animacao_dia.scale = Vector2(2.5, 2.5) # Começa bem grande
	lbl_animacao_dia.modulate.a = 1.0          # Transparência 100%
	
	# 3. Pega a posição exata de destino lá no Label do Painel Topo
	var destino = painel_topo.lbl_dias.global_position
	
	# 4. Criando a animação simultânea
	var tween = create_tween().set_parallel(true)
	
	# Move do centro até o topo em 1.2 segundos com transição suave
	tween.tween_property(lbl_animacao_dia, "global_position", destino, 1.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# Diminui a escala ao mesmo tempo (de 2.5x para 1.0x)
	tween.tween_property(lbl_animacao_dia, "scale", Vector2(1.0, 1.0), 1.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# Faz desaparecer suavemente nos últimos instantes da animação
	tween.tween_property(lbl_animacao_dia, "modulate:a", 0.0, 0.4).set_delay(0.8)
	
	# 5. Espera a animação acabar para ocultar o Label e atualizar o topo de fato
	await tween.finished
	lbl_animacao_dia.visible = false
	
	# Atualiza o contador oficial no topo após a animação chegar lá
	painel_topo.atualizar_dias(dias_restantes, dias_totais)

	if dias_restantes <= 0:
		await _finalizar_jogo(false)


func _finalizar_jogo(vitoria: bool) -> void:
	if jogo_finalizado:
		return

	jogo_finalizado = true

	if painel_atendimento and painel_atendimento.timer:
		painel_atendimento.timer.paused = true

	var tipo_resultado := "vitória" if vitoria else "derrota"
	print("Fim de jogo (%s)! Transição em 3 segundos..." % tipo_resultado)
	criar_popup_na_tela_cheia("Fim de Jogo! Computando Resultados...", false)

	await get_tree().create_timer(3.0, false, false, false).timeout

	var precisao_atual := 100.0
	if total_tentativas > 0:
		precisao_atual = (float(total_acertos) / float(total_tentativas)) * 100.0

	EventBus.fim_de_jogo_vitoria = vitoria
	EventBus.fim_de_jogo_stats = {
		"tempo": int(tempo_jogo_segundos),
		"ligacoes": total_ligacoes,
		"precisao": int(precisao_atual),
		"dias_restantes": dias_restantes,
	}

	TransitionScreen.transition_to_scene(CENA_VITORIA_DERROTA)

var tutorial_node: CanvasLayer = null



func carregar_tutorial() -> void:
	var tutorial_scene = preload("res://Scenes/tutorial_manager.tscn")
	tutorial_node = tutorial_scene.instantiate()
	add_child(tutorial_node)
	tutorial_node.tutorial_concluido.connect(_on_tutorial_finalizado)

func _on_tutorial_finalizado() -> void:
	print("Tutorial finalizado!")

func _on_atributos_upgrades_atualizados() -> void:
	# 1. Aplica tempo de tolerância no Painel de Atendimento
	if painel_atendimento and "tempo_limite" in painel_atendimento:
		painel_atendimento.tempo_limite = UpgradesManager.tempo_limite_chamada + UpgradesManager.tempo_tolerancia_extra

	# 2. Atualiza a meta de vitória no jogo
	if UpgradesManager.meta_consciencia_vitoria < 100.0:
		print("🎯 Meta de Vitória reduzida para: ", UpgradesManager.meta_conscientizacao_vitoria, "%")

# Em Game.gd:
func _on_ponto_passivo_gerado(tipo: String, quantidade: int) -> void:
	if pnl_conscientizacao and pnl_conscientizacao.has_method("adicionar_pontos_por_tipo"):
		pnl_conscientizacao.adicionar_pontos_por_tipo(tipo, quantidade)


# Exemplo de fluxo quando a rodada encerra/inicia no Game:
func preparar_proxima_rodada() -> void:
	# 1. Aqui você usa a SUA variável/função real que já passa para a barra
	# Exemplo: painel_barra_conscientizacao.definir_conscientizacao(sua_variavel_de_porcentagem)
	
	# 2. Chama o UpgradesManager para verificar a barra e definir se libera 1 ou 2 compras
	if UpgradesManager:
		UpgradesManager.iniciar_nova_rodada()
