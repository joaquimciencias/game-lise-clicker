extends Control

# 1. Carrega a cena do popup na raiz do jogo
const POPUP_NOTIFICACAO_SCENE = preload("res://Scenes/popup_notificacao.tscn")

# Cenas dos Eventos Extras mapeadas por porcentagem da barra (25%, 50%, 75%)
# Ajuste os caminhos das cenas de 50% e 75% conforme suas pastas
const EVENTOS_EXTRAS = {
	25.0: preload("res://Scenes/Paineis/Painel_Main_Loja.tscn"),
	50.0: preload("res://Scenes/Eventos/evento_violencia_sexual.tscn"), # Substitua pela cena do evento de 50%
	75.0: preload("res://Scenes/Eventos/evento_violencia_sexual.tscn")  # Substitua pela cena do evento de 75%
}

# Constantes de impacto na conscientização da população
const CORRECT_GAIN: float = 3.0
const WRONG_PENALTY: float = -1.0
const TIMEOUT_PENALTY: float = -0.5

@onready var painel_topo: Control = $Painel_Topo_Inicial
@onready var painel_atendimento: Control = $Painel_Atendimento
@onready var painel_fila_mulheres = $Painel_Fila_Mulheres
@onready var pnl_conscientizacao: Control = $Painel_Tipos_Conscientizados
@onready var pnl_barra_conscientizacao: Control = $Painel_Barra_Conscientizacao
@onready var jogo_pausado: MarginContainer = $JogoPausado


# Variáveis para controle das estatísticas do Topo
var total_tentativas: int = 0
var total_acertos: int = 0

var dias_totais: int = 30
var dias_restantes: int = 28

# Estado global da conscientização (0.0 a 100.0)
var conscientizacao_atual: float = 0.0

# Registro dos eventos extras que já foram acionados para não repetir
var eventos_disparados: Array[float] = []

var pressed = false

var contador_relatos_loja: int = 0

func _ready() -> void:
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

func _on_violencia_computada(tipo: String) -> void:
	if pnl_conscientizacao.has_method("atualizar_contador"):
		pnl_conscientizacao.atualizar_contador(tipo)

func _on_botao_pausa_pressed() -> void:
	get_tree().paused = true
	jogo_pausado.abrir()

func _on_jogo_retomado() -> void:
	get_tree().paused = false 

func criar_popup_na_tela_cheia(texto_recebido: String) -> void:
	var novo_popup = POPUP_NOTIFICACAO_SCENE.instantiate()
	add_child(novo_popup) 
	novo_popup.mostrar_mensagem(texto_recebido)

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
		1: # ERRADO (ResultadoRodada.ERRADO)
			delta = WRONG_PENALTY
			acertou = false
		2: # TIMEOUT (ResultadoRodada.TIMEOUT)
			delta = TIMEOUT_PENALTY
			acertou = false

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

	# 3. CHAMA O FEEDBACK NO PAINEL COM O VALOR DAS CONSTANTES DO MAIN:
	if painel_atendimento and painel_atendimento.has_method("exibir_feedback"):
		# Aguarda a animação do Fade In e Fade Out terminar
		await painel_atendimento.exibir_feedback(acertou, delta)
		
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

	# 5. Verificação de Fim de Jogo / Vitória
	if conscientizacao_atual >= 100.0:
		print("Vitória! População totalmente conscientizada!")

# --- SISTEMA GENÉRICO DE EVENTOS EXTRAS ---

func verificar_eventos_extras() -> void:
	for limiar in EVENTOS_EXTRAS.keys():
		if conscientizacao_atual >= limiar and not limiar in eventos_disparados:
			eventos_disparados.append(limiar)
			disparar_alerta_evento_extra(limiar)
			break # Dispara apenas um por rodada para evitar sobreposição

func disparar_alerta_evento_extra(limiar: float) -> void:
	print("ALERTA: Evento extra de %d%% será iniciado em 3 segundos!" % int(limiar))
	
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
	
	if pnl_barra_conscientizacao:
		pnl_barra_conscientizacao.definir_conscientizacao(conscientizacao_atual)
		
	# RETOMADA FORÇADA: Garante que o painel volte a contar o tempo do relato ativo
	if painel_atendimento and painel_atendimento.has_method("retomar_atendimento"):
		painel_atendimento.retomar_atendimento()


func _on_pontos_conscientizacao_atualizados(total_pontos: int) -> void:
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
func _on_loja_fechada_retomar() -> void:
	print("🛍️ Loja fechada. Retomando os atendimentos...")
	if painel_atendimento:
		painel_atendimento.carregar_novo_relato()
