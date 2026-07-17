extends MarginContainer

# Declaração do sinal personalizado que envia o tipo de violência conscientizada
signal violencia_conscientizada(tipo: String)
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

	randomize() 
	
	progress_bar.max_value = timer.wait_time
	progress_bar.min_value = 0.0
	
	# Conectando o clique de cada botão à nossa função de validação
	# Usamos o 'bind' para passar como argumento qual tipo de violência aquele botão representa
	btn_fisica.pressed.connect(_on_botao_violencia_pressionado.bind("Física"))
	btn_psicologica.pressed.connect(_on_botao_violencia_pressionado.bind("Psicológica"))
	btn_moral.pressed.connect(_on_botao_violencia_pressionado.bind("Moral"))
	btn_patrimonial.pressed.connect(_on_botao_violencia_pressionado.bind("Patrimonial"))
	
	# Também vamos escutar se o tempo do Timer acabar!
	timer.timeout.connect(_on_tempo_esgotado)
	
	carregar_novo_relato()

func _process(_delta: float) -> void:
	# Se o timer estiver rodando, atualizamos a interface visual
	if timer.time_left > 0:
		# Atualiza a barra verde decrescendo
		progress_bar.value = timer.time_left
		
		# Atualiza o texto (ceilf arredonda para cima: 9.2s vira 10s)
		lbl_tempo.text = str(ceilf(timer.time_left)) + "s"

func iniciar_novo_tempo() -> void:
	timer.start()

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

	if lista_de_relatos.is_empty():
		lbl_relato.text = "Todos os relatos foram analisados!"
		timer.stop()
		return

	# (O restante do seu código original de sorteio continua igual daqui para baixo...)
	var indice_aleatorio = randi() % lista_de_relatos.size()
	
	# COMENTADO PARA NÃO APAGAR O RELATO DA LISTA:
	relato_atual = lista_de_relatos.pop_at(indice_aleatorio)
	
	# NOVA LINHA: Apenas pega o relato usando o índice, mantendo-o na lista
	#relato_atual = lista_de_relatos[indice_aleatorio]
	lbl_relato.text = relato_atual["texto"]
	lbl_relato_titulo.text = "RELATO RECEBIDO"
	iniciar_novo_tempo()

func _on_botao_violencia_pressionado(tipo_escolhido: String) -> void:
	timer.stop()

	if tipo_escolhido == relato_atual["tipo"]:
		print("Acertou! Tipo conscientizado: ", tipo_escolhido)
		# Emite o sinal antigo (que seu jogo já usa)
		violencia_conscientizada.emit(tipo_escolhido)
		# --- NOVO: Avisa que a resposta foi um ACERTO ---
		emit_signal("tentativa_respondida", ResultadoRodada.CORRETO)
	else:
		print("Errou! O correto era: ", relato_atual["tipo"])
		# --- NOVO: Avisa que a resposta foi um ERRO ---
		emit_signal("tentativa_respondida", ResultadoRodada.ERRADO)

	relato_respondido.emit()
	carregar_novo_relato()

func _on_tempo_esgotado() -> void:
	print("O tempo acabou antes de responder!")
	# --- NOVO: Tempo esgotado conta como erro ---
	emit_signal("tentativa_respondida", ResultadoRodada.TIMEOUT)

	relato_respondido.emit()
	carregar_novo_relato()
