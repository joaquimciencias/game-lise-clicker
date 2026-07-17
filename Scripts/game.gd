extends CanvasLayer

# 1. Carrega a cena do popup na raiz do jogo
const POPUP_NOTIFICACAO_SCENE = preload("res://Scenes/popup_notificacao.tscn") # Ajuste o caminho da pasta se necessário
const MINIGAME_CLIQUE_SCENE = preload("res://Scenes/Eventos/evento_violencia_sexual.tscn")

# Constantes de impacto na conscientização da população
const CORRECT_GAIN: float = 3.0
const WRONG_PENALTY: float = -1.0
const TIMEOUT_PENALTY: float = -0.5

@onready var painel_topo: Control = $Painel_Topo_Inicial
@onready var painel_atendimento: Control = $Painel_Atendimento
@onready var painel_fila_mulheres = $Painel_Fila_Mulheres
@onready var pnl_ligacoes_atendidas: Control = $Painel_Ligacoes_Atendidas
@onready var pnl_conscientizacao: Control = $Painel_Tipos_Conscientizados
@onready var pnl_barra_conscientizacao: Control = $Painel_Barra_Conscientizacao
@onready var jogo_pausado: MarginContainer = $JogoPausado

# Variáveis para controle das estatísticas do Topo
var total_tentativas: int = 0
var total_acertos: int = 0

var dias_totais: int = 30
var dias_restantes: int = 30

# Estado global da conscientização (0.0 a 100.0)
var conscientizacao_atual: float = 0.0

var evento_25_disparado: bool = false #conscientizacao 25%

func _ready() -> void:
	painel_atendimento.violencia_conscientizada.connect(_on_violencia_computada)
	painel_atendimento.relato_respondido.connect(_on_relato_concluido)
	painel_atendimento.painel_fila = painel_fila_mulheres
	painel_atendimento.carregar_novo_relato()
	jogo_pausado.jogo_retomado.connect(_on_jogo_retomado)

	# --- NOVAS CONEXÕES PARA O PAINEL SUPERIOR ---
	# 1. Escuta quando o jogador responde (para calcular Precisão)
	# Substitua ou atualize a conexão antiga por esta:
	painel_atendimento.tentativa_respondida.connect(_on_tentativa_atendimento_processada)

	# 2. Escuta quando o painel de conscientização muda (para atualizar Ligações Totais)
	if pnl_conscientizacao:
		pnl_conscientizacao.pontos_atualizados.connect(_on_pontos_conscientizacao_atualizados)

	# 3. Inicializa o topo com os dias padrões do jogo
	if painel_topo:
		painel_topo.atualizar_dias(dias_restantes, dias_totais)
	# ---------------------------------------------

	var loja = get_tree().get_first_node_in_group("loja_principal")
	if loja:
		loja.compra_finalizada_com_sucesso.connect(criar_popup_na_tela_cheia)

func _on_violencia_computada(tipo: String) -> void:

	# Aqui, a cena game chama uma função de dentro da sua cena de contadores
	# passando qual tipo deve ser somado!
	if pnl_conscientizacao.has_method("atualizar_contador"):
		pnl_conscientizacao.atualizar_contador(tipo)

func _on_botao_pausa_pressed() -> void:
	get_tree().paused = true
	jogo_pausado.abrir()

func _on_jogo_retomado() -> void:
	get_tree().paused = false 

# --- NOVA FUNÇÃO: Cria o popup no CanvasLayer raiz (Tela Inteira!) ---
func criar_popup_na_tela_cheia(texto_recebido: String) -> void:
	var novo_popup = POPUP_NOTIFICACAO_SCENE.instantiate()
	# Adiciona direto no CanvasLayer. Ele vai ignorar recortes e margens de qualquer painel!
	add_child(novo_popup) 
	novo_popup.mostrar_mensagem(texto_recebido)

func _on_relato_concluido():
	# A primeira mulher some e o rastro anda para a esquerda
	painel_fila_mulheres.avancar_fila()


# Chamado sempre que o jogador clica em um botão ou o tempo esgota
func _on_tentativa_atendimento_processada(resultado: int) -> void:
	total_tentativas += 1
	var delta: float = 0.0
	
	# Usamos o match para verificar qual foi o resultado da rodada
	match resultado:
		0: # CORRETO (Equivalente ao primeiro item do enum)
			total_acertos += 1
			delta = CORRECT_GAIN
		1: # ERRADO
			delta = WRONG_PENALTY
		2: # TIMEOUT
			delta = TIMEOUT_PENALTY

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
		
	# 3. Verificação de Fim de Jogo / Vitória
	if conscientizacao_atual >= 100.0:
		print("Vitória! População totalmente conscientizada!")
	if pnl_barra_conscientizacao:
		pnl_barra_conscientizacao.definir_conscientizacao(conscientizacao_atual)
	
	# GATILHO DO EVENTO EXTRA (25%)
	if conscientizacao_atual >= 25.0 and not evento_25_disparado:
		evento_25_disparado = true
		disparar_alerta_evento_extra()


# Chamado quando o painel lateral computa um ponto com sucesso
func _on_pontos_conscientizacao_atualizados(total_pontos: int) -> void:
	if painel_topo:
		painel_topo.atualizar_ligacoes(total_pontos)

func disparar_alerta_evento_extra() -> void:
	print("ALERTA: Um evento extra vai começar em 3 segundos!")
	
	# 1. Esconde temporariamente o quiz central para dar foco ao alerta
	if painel_atendimento:
		painel_atendimento.visible = false
		# Se o seu quiz central tiver um Timer próprio rodando, pare-o aqui:
		# painel_atendimento.parar_timer()
	
	# TODO: Aqui você pode tornar visível um nó de texto na tela dizendo: 
	# "ATENÇÃO! Primeiras denúncias estão surgindo de forma crítica!"
	
	# 2. Aguarda 3 segundos de forma assíncrona
	await get_tree().create_timer(3.0).timeout
	
	# 3. Esconde o texto de alerta e inicia o minigame de fato
	iniciar_minigame_25_porcento()


func iniciar_minigame_25_porcento() -> void:
	var minigame = MINIGAME_CLIQUE_SCENE.instantiate()
	
	# Adiciona o minigame na árvore de nós (pode ser dentro de um container central seu)
	add_child(minigame) 
	
	# Conecta o sinal do fim do minigame à lógica da Main
	minigame.minigame_concluido.connect(_on_minigame_25_concluido)

func _on_minigame_25_concluido(sucesso: bool) -> void:
	# Aplica o impacto do resultado do minigame na conscientização geral
	if sucesso:
		print("Sucesso! Rede de proteção acionada a tempo!")
		# Você pode dar um bônus extra na barra principal por ter vencido o evento
		conscientizacao_atual = clamp(conscientizacao_atual + 5.0, 0.0, 100.0)
	else:
		print("Fracasso! A rede demorou a responder.")
		# Ou aplicar uma penalidade severa se falhar no evento crítico
		conscientizacao_atual = clamp(conscientizacao_atual - 3.0, 0.0, 100.0)
	
	# Atualiza a barra global com o novo impacto
	if pnl_barra_conscientizacao:
		pnl_barra_conscientizacao.definir_conscientizacao(conscientizacao_atual)
	
	# Traz o quiz central de volta para continuar o jogo normal
	if painel_atendimento:
		painel_atendimento.visible = true
		# painel_atendimento.reiniciar_timer()
