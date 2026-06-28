extends MarginContainer

enum TipoViolencia {FISICA, PSICOLOGICA, MORAL, PATRIMONIAL}

signal atendimento_concluido(tipo: TipoViolencia)

@onready var progress_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar
@onready var button: Button = $HBoxContainer/VBoxContainer/Button

# 1. Pegamos a referência do Label que mostra o nome do tipo (baseado na hierarquia da sua imagem)
@onready var lbl_nome_tipo: Label = $HBoxContainer/VBoxContainer/HBoxContainer/VBoxTipoViolencia/NomeViolencia

var tipo_atual: TipoViolencia

func _ready() -> void:
	progress_bar.value = 0
	sortear_nova_ligacao()

func sortear_nova_ligacao() -> void:
	tipo_atual = randi_range(0, 3) as TipoViolencia
	
	# 2. Atualiza o texto do Label dependendo do tipo sorteado para esta ligação
	match tipo_atual:
		TipoViolencia.FISICA:
			lbl_nome_tipo.text = "FÍSICA"
		TipoViolencia.PSICOLOGICA:
			lbl_nome_tipo.text = "PSICOLÓGICA"
		TipoViolencia.MORAL:
			lbl_nome_tipo.text = "MORAL"
		TipoViolencia.PATRIMONIAL:
			lbl_nome_tipo.text = "PATRIMONIAL"

func _on_button_pressed() -> void:
	progress_bar.value += 10 
	
	if progress_bar.value >= progress_bar.max_value:
		atendimento_concluido.emit(tipo_atual)
		progress_bar.value = 0
		sortear_nova_ligacao() # Aqui ele já sorteia o próximo e muda o texto na tela!
