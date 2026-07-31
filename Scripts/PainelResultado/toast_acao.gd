extends PanelContainer
class_name ToastAcao

enum TipoResultado { CORRETO, INCORRETO, TIMEOUT }

const COR_SUCESSO := Color("4ade80")
const COR_ERRO := Color("f87171")
const COR_FUNDO_ICONE_SUCESSO := Color(0.08, 0.22, 0.12, 1)
const COR_FUNDO_ICONE_ERRO := Color(0.24, 0.08, 0.1, 1)
const COR_BORDA_ICONE_SUCESSO := Color("4ade80")
const COR_BORDA_ICONE_ERRO := Color("f87171")

@onready var icon_panel: Panel = $HBoxContainer/IconPanel
@onready var icon_label: Label = $HBoxContainer/IconPanel/Icon
@onready var lbl_categoria: Label = $HBoxContainer/Categoria


@onready var lbl_pontos: Label = $HBoxContainer/Pontos


func configurar(categoria: String, tipo: TipoResultado, pontos: float) -> void:
	lbl_categoria.text = categoria

	var sucesso := tipo == TipoResultado.CORRETO
	var cor_principal := COR_SUCESSO if sucesso else COR_ERRO

	match tipo:
		TipoResultado.CORRETO:
			icon_label.text = "✓"
		TipoResultado.INCORRETO:
			icon_label.text = "✗"
		TipoResultado.TIMEOUT:
			icon_label.text = "✗"

	_aplicar_estilo_icone(sucesso)
	lbl_pontos.modulate = cor_principal

	if pontos >= 0.0:
		lbl_pontos.text = "+%s%%" % _formatar_pontos(pontos)
	else:
		lbl_pontos.text = "%s%%" % _formatar_pontos(pontos)


func animar_entrada() -> void:
	var destino_x := position.x
	modulate.a = 0.0
	position.x = destino_x + 48.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", destino_x, 0.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)


func animar_saida() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN)
	await tween.finished


func definir_opacidade_base(valor: float) -> void:
	modulate.a = valor


func _formatar_pontos(valor: float) -> String:
	if is_equal_approx(fmod(absf(valor), 1.0), 0.0):
		return str(int(valor))
	return "%.1f" % valor


func _aplicar_estilo_icone(sucesso: bool) -> void:
	var estilo := icon_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if sucesso:
		estilo.bg_color = COR_FUNDO_ICONE_SUCESSO
		estilo.border_color = COR_BORDA_ICONE_SUCESSO
	else:
		estilo.bg_color = COR_FUNDO_ICONE_ERRO
		estilo.border_color = COR_BORDA_ICONE_ERRO
	icon_panel.add_theme_stylebox_override("panel", estilo)
