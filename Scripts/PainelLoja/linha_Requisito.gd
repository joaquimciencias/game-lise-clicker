extends HBoxContainer

var icone_status: Label
var lbl_texto: Label

func _ready():
	_obter_referencias()

func _obter_referencias():
	if not icone_status:
		icone_status = get_node_or_null("IconeStatus") as Label
	if not lbl_texto:
		lbl_texto = get_node_or_null("LblTexto") as Label

func configurar(texto: String, cumprido: bool = true):
	_obter_referencias()
	if lbl_texto:
		lbl_texto.text = texto
	if icone_status:
		icone_status.text = "✔" if cumprido else "✖"
		icone_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2) if cumprido else Color(0.9, 0.2, 0.2))
