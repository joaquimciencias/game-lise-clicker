extends Control

const CENA_GAME = "res://Scenes/01-game.tscn"
const CENA_OPTIONS = "res://Scenes/02-options.tscn"

@onready var lbl_toquejogar := $LiseLogo2
@onready var lbl_liselogo := $LiseLogo

# Banco de frases de conscientização
var banco_de_frases = [
	"[center]Denuncie. Ligue 180.[/center]",
	"[center]A violência doméstica não tem desculpa.[/center]",
	"[center]Respeito é um direito de todas.[/center]",
	"[center]O silêncio é cúmplice da agressão.[/center]",
	"[center]Não é amor, é controle.[/center]",
	"[center]A culpa nunca é da vítima.[/center]",
	"[center]Violência contra a mulher é crime.[/center]",
	"[center]Sua voz pode salvar uma vida.[/center]",
	"[center]Amor verdadeiro não machuca nem humilha.[/center]",
	"[center]Apoie, escute e acredite nas mulheres.[/center]",
	"[center]Liberdade e segurança para todas as mulheres.[/center]"
]

var ultima_frase_index = -1

# Variáveis para guardar a posição e rotação originais do LiseLogo e controlar o tempo de flutuação dele
var logo_pos_inicial: Vector2
var logo_rot_inicial: float = 0.0
var tempo_logo: float = 0.0

func _ready() -> void:
	# Salva a posição e rotação originais do logo para ele flutuar em volta do seu lugar certo
	if lbl_liselogo:
		logo_pos_inicial = lbl_liselogo.position
		logo_rot_inicial = lbl_liselogo.rotation
		# Define o pivô no centro para a micro-rotação ficar natural (caso ainda não esteja no Inspector)
		lbl_liselogo.pivot_offset = lbl_liselogo.size / 2.0

	piscar_label_infinito()
	
	var timer = Timer.new()
	timer.wait_time = 2.5
	timer.autostart = true
	timer.timeout.connect(_criar_frase_fluida)
	add_child(timer)

func _process(delta: float) -> void:
	# Movimento orgânico, super suave e quase imperceptível para o LiseLogo
	if lbl_liselogo:
		tempo_logo += delta
		
		# Sobe e desce bem de leve (usando seno com frequência baixa e amplitude minúscula de 3 pixels)
		var flutuacao_y = sin(tempo_logo * 1.2) * 3.0
		# Balanço lateral ainda mais sutil (amplitude de 1.5 pixels)
		var flutuacao_x = cos(tempo_logo * 0.8) * 1.5
		
		lbl_liselogo.position = logo_pos_inicial + Vector2(flutuacao_x, flutuacao_y)
		
		# Micro-rotação quase imperceptível para dar vida (inclinando frações de grau)
		lbl_liselogo.rotation = logo_rot_inicial + (sin(tempo_logo * 0.8) * 0.008)

func _on_jogar_pressed() -> void:
	TransitionScreen.transition_to_scene(CENA_GAME)

func _on_opcoes_pressed() -> void:
	TransitionScreen.transition_to_scene(CENA_OPTIONS)

func piscar_label_infinito() -> void:
	var intervalo = 0.15
	while true:
		lbl_toquejogar.visible = not lbl_toquejogar.visible
		await get_tree().create_timer(intervalo).timeout

func _criar_frase_fluida() -> void:
	var frase = RichTextLabel.new()
	frase.bbcode_enabled = true
	frase.fit_content = true
	frase.custom_minimum_size = Vector2(400, 50)
	frase.pivot_offset = Vector2(200, 25)
	
	var indice_aleatorio = randi() % banco_de_frases.size()
	while indice_aleatorio == ultima_frase_index and banco_de_frases.size() > 1:
		indice_aleatorio = randi() % banco_de_frases.size()
	
	ultima_frase_index = indice_aleatorio
	frase.text = banco_de_frases[indice_aleatorio]
	
	var viewport_size = get_viewport_rect().size
	var random_x = randf_range(50, viewport_size.x - 450)
	var pos_y_inicial = randf_range(viewport_size.y - 150, viewport_size.y - 80)
	frase.position = Vector2(random_x, pos_y_inicial)
	
	add_child(frase)
	
	var tempo_vida = 6.0
	var velocidade_subida = 35.0
	var amplitude_onda = randf_range(40.0, 70.0)
	var frequencia_onda = randf_range(0.4, 0.8)
	var posicao_x_original = random_x
	var tempo_decorrido = 0.0
	
	frase.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(frase, "modulate:a", 1.0, 1.0)
	
	while tempo_decorrido < tempo_vida:
		var delta = get_process_delta_time()
		tempo_decorrido += delta
		
		frase.position.y -= velocidade_subida * delta
		
		var deslocamento_x = sin(tempo_decorrido * frequencia_onda + random_x) * amplitude_onda
		frase.position.x = posicao_x_original + deslocamento_x
		
		frase.rotation = cos(tempo_decorrido * frequencia_onda + random_x) * 0.035
		
		if tempo_decorrido > (tempo_vida - 1.5):
			frase.modulate.a = remap(tempo_decorrido, tempo_vida - 1.5, tempo_vida, 1.0, 0.0)
		
		await get_tree().process_frame
		
	frase.queue_free()
