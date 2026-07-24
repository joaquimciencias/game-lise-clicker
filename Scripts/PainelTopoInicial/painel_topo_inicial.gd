extends MarginContainer # Ou MarginContainer/Control, dependendo do tipo do seu nó raiz

signal jogo_pausado

# Referências baseadas na hierarquia da sua imagem
@onready var lbl_dias = $HBoxConteudo/VBoxDiasRestantes/BotaoDiasRestantes/CenterContainer/VBoxContainer/Num
@onready var lbl_ligacoes = $HBoxConteudo/HBoxLigacoesTotais/BotaoLigacoesTotais/CenterContainer/VBoxContainer/Num
@onready var lbl_precisao = $HBoxConteudo/HBoxPrecisao/BotaoPrecisao/CenterContainer/VBoxContainer/Num

func _ready() -> void:
	# Valores iniciais de exibição padrão
	atualizar_dias(30, 30)
	atualizar_ligacoes(0)
	atualizar_precisao(100.0)

## Atualiza o texto dos dias no formato "atuais/totais" (ex: 30/30)
func atualizar_dias(dias_restantes: int, dias_totais: int) -> void:
	if lbl_dias:
		lbl_dias.text = str(dias_restantes) + "/" + str(dias_totais)

## Atualiza as ligações totais exibidas
func atualizar_ligacoes(total: int) -> void:
	if lbl_ligacoes:
		lbl_ligacoes.text = str(total)

## Atualiza a precisão calculada em porcentagem formatada
func atualizar_precisao(porcentagem: float) -> void:
	if lbl_precisao:
		# "%.0f%%" formata o float sem casas decimais e adiciona o símbolo de %
		lbl_precisao.text = "%.0f%%" % porcentagem


func _on_botao_pausa_pressed() -> void:
	emit_signal("jogo_pausado")
