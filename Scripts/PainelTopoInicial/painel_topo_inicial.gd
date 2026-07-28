extends MarginContainer # Ou MarginContainer/Control, dependendo do tipo do seu nó raiz

signal jogo_pausado

# Referências baseadas na hierarquia da sua imagem
@onready var lbl_dias = $HBoxConteudo/VBoxDiasRestantes/BotaoDiasRestantes/CenterContainer/VBoxContainer/Num
@onready var lbl_ligacoes = $HBoxConteudo/HBoxLigacoesTotais/BotaoLigacoesTotais/CenterContainer/VBoxContainer/Num
@onready var lbl_precisao = $HBoxConteudo/HBoxPrecisao/BotaoPrecisao/CenterContainer/VBoxContainer/Num
@onready var container_dias = $HBoxConteudo/VBoxDiasRestantes/BotaoDiasRestantes

# Variável para guardar a cor original 
var cor_original_dias: Color

func _ready() -> void:
	# Salva a cor que você definiu no Editor 
	if lbl_dias:
		cor_original_dias = lbl_dias.modulate
		
	# Valores iniciais de exibição padrão
	atualizar_dias(30, 30)
	atualizar_ligacoes(0)
	atualizar_precisao(100.0)

## Atualiza o texto dos dias no formato "atuais/totais" (ex: 30/30)
func atualizar_dias(dias_restantes: int, dias_totais: int, animar: bool = true) -> void:
	if lbl_dias:
		lbl_dias.text = str(dias_restantes) + "/" + str(dias_totais)
		# --- NOVO: Só pisca se for pedido (para não piscar no _ready) ---
		if animar:
			piscar_label_rapido()

## Atualiza as ligações totais exibidas
func atualizar_ligacoes(total: int) -> void:
	if lbl_ligacoes:
		lbl_ligacoes.text = str(total)

## Atualiza a precisão calculada em porcentagem formatada
func atualizar_precisao(porcentagem: float) -> void:
	if lbl_precisao:
		# "%.0f%%" formata o float sem casas decimais e adiciona o símbolo de %
		lbl_precisao.text = "%.0f%%" % porcentagem

# Função que faz o efeito de brilho/piscar
func piscar_label_rapido() -> void:
	if not lbl_dias: return

	# 1. Escolha a cor do impacto/dano:
	# - Color.RED (Vermelho para dano/redução de dia)
	# - Color(1.0, 0.2, 0.2) (Vermelho vívido)
	# - Color.YELLOW (Amarelo de destaque)
	var cor_impacto = Color.RED

	# 2. Cria o Tween com execução paralela ativada
	var tween = create_tween().set_parallel(true)

	# --- A) MUDANÇA DE COR ---
	# Muda instantaneamente para vermelho no momento do impacto (0.05s)
	tween.tween_property(lbl_dias, "modulate", cor_impacto, 0.05)
	
	# Volta suavemente para a cor original do tema (0.3s)
	tween.tween_property(lbl_dias, "modulate", cor_original_dias, 0.3)\
		.set_delay(0.05)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# --- B) POP DE ESCALA (Aumenta e encolhe) ---
	tween.tween_property(lbl_dias, "scale", Vector2(1.35, 1.35), 0.08)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(lbl_dias, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_SPRING)\
		.set_ease(Tween.EASE_OUT)\
		.set_delay(0.08)

	# --- C) CHACOALHADA DE IMPACTO (Via rotação, compatível com Containers) ---
	tween.tween_property(lbl_dias, "rotation_degrees", -10.0, 0.04)
	tween.tween_property(lbl_dias, "rotation_degrees", 10.0, 0.04).set_delay(0.04)
	tween.tween_property(lbl_dias, "rotation_degrees", -5.0, 0.04).set_delay(0.08)
	tween.tween_property(lbl_dias, "rotation_degrees", 0.0, 0.04).set_delay(0.12)

func _on_botao_pausa_pressed() -> void:
	emit_signal("jogo_pausado")
