extends Control

signal minigame_concluido(sucesso: bool)

@onready var progress_bar: ProgressBar = $MarginContainer2/VBoxContainer2/ProgressBarAtendimento
@onready var timer: Timer = $TimerProgresso
@onready var botao_acionar: Button = $MarginContainer2/VBoxContainer2/BotaoAcionar # Adicione a referência ao botão

var progresso_atual: float = 0.0
const FORCA_CLIQUE: float = 8.0     
const DECAIMENTO: float = 12.0       


func _ready() -> void:
	progress_bar.max_value = 100.0
	progress_bar.value = 0
	
	# --- CONEXÃO MANUAL DE SINAIS ---
	# Garante que o clique no botão chame a função correta
	if botao_acionar:
		botao_acionar.pressed.connect(_on_botao_acionar_pressed)
		
	# Garante que o estouro do timer chame a função correta
	if timer:
		timer.timeout.connect(_on_timer_progresso_timeout)
		timer.start()

func _process(_delta: float) -> void:
	$LabelTimer.text = "%0.1f" % $TimerProgresso.time_left + "s"

## Função chamada quando o botão é clicado (Garante o progresso)
func _on_botao_acionar_pressed() -> void:
	print("Botão pressionado! Progresso: ", progresso_atual)
	progresso_atual += FORCA_CLIQUE
	progress_bar.value = progresso_atual

	if progresso_atual >= 100.0:
		finalizar_minigame(true)

## ESSA É A FUNÇÃO QUE ESTAVA FALTANDO OU COM NOME DIFERENTE:
func _on_timer_progresso_timeout() -> void:
	print("O tempo acabou!")
	# Se o tempo acabou e a barra não chegou a 100%, o jogador falhou
	finalizar_minigame(false)

## Função central que encerra o minigame e limpa a memória
func finalizar_minigame(sucesso: bool) -> void:
	timer.stop()
	set_process(false) # Para o decaimento da barra no _process
	emit_signal("minigame_concluido",sucesso) 
	queue_free() # Remove o popup da cena e libera a memória
