extends Control

# Recebe o limiar quando for instanciado (ex: 25.0)
var limiar_evento: float = 25.0

@onready var progress_bar: ProgressBar = $MarginContainer2/VBoxContainer2/ProgressBarAtendimento
@onready var timer: Timer = $TimerProgresso
@onready var botao_acionar: Button = $MarginContainer2/VBoxContainer2/BotaoAcionar

var progresso_atual: float = 0.0
const FORCA_CLIQUE: float = 8.0     
const DECAIMENTO: float = 12.0     

func _ready() -> void:
	# ESSENCIAL: Permite que este nó rode durante a pausa do jogo
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pausa o jogo ao abrir o minigame
	get_tree().paused = true
	
	progress_bar.max_value = 100.0
	progress_bar.value = 0
	
	if botao_acionar:
		botao_acionar.pressed.connect(_on_botao_acionar_pressed)
		
	if timer:
		# Timer precisa processar durante a pausa
		timer.process_callback = Timer.TIMER_PROCESS_IDLE
		timer.timeout.connect(_on_timer_progresso_timeout)
		timer.start()

func _process(_delta: float) -> void:
	if is_instance_valid(timer) and timer.time_left > 0:
		$PanelTimer/LabelTimer.text = "%0.1f" % timer.time_left + "s"

func _on_botao_acionar_pressed() -> void:
	progresso_atual += FORCA_CLIQUE
	progress_bar.value = progresso_atual

	if progresso_atual >= 100.0:
		finalizar_minigame(true)

func _on_timer_progresso_timeout() -> void:
	finalizar_minigame(false)

func finalizar_minigame(sucesso: bool) -> void:
	if is_instance_valid(timer):
		timer.stop()
	set_process(false)
	
	# 1. Notifica o EventBus global sobre a conclusão
	EventBus.minigame_finalizado.emit(sucesso, limiar_evento)
	
	# 2. Despausa o jogo ANTES de se remover da memória
	get_tree().paused = false
	
	# 3. Remove da memória
	queue_free()
