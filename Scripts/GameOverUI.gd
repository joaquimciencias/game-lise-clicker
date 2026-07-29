extends CanvasLayer

const CENA_GAME := "res://Scenes/01-game.tscn"
const CENA_MENU_GAME := "res://Scenes/00-main_menu.tscn"

@onready var label_vitoria: Label = $Control/VBoxContainer/LabelVitoria
@onready var label_derrota: Label = $Control/VBoxContainer/LabelDerrota
@onready var label_descricao_vitoria: Label = $Control/VBoxContainer/LabelDescricaoVitoria
@onready var label_descricao_derrota: Label = $Control/VBoxContainer/LabelDescricaoDerrota
@onready var btn_jogar_novamente: Button = $Control/VBoxContainer/Button
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var lbl_tempo: Label = $Control/VBoxContainer/HBoxContainer/VBoxContainer/MarginContainer/VBoxContainer/Num
@onready var lbl_ligacoes: Label = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/MarginContainer/VBoxContainer/Num
@onready var lbl_precisao: Label = $Control/VBoxContainer/HBoxContainer/VBoxContainer3/MarginContainer/VBoxContainer/Num
@onready var lbl_dias: Label = $Control/VBoxContainer/HBoxContainer/VBoxContainer4/MarginContainer/VBoxContainer/Num


func _ready() -> void:
	btn_jogar_novamente.pressed.connect(_on_jogar_novamente_pressed)
	_configurar_resultado(EventBus.fim_de_jogo_vitoria, EventBus.fim_de_jogo_stats)
	animation_player.play("chegando")


func _configurar_resultado(vitoria: bool, stats: Dictionary) -> void:
	label_vitoria.visible = vitoria
	label_descricao_vitoria.visible = vitoria

	label_derrota.visible = not vitoria
	label_descricao_derrota.visible = not vitoria

	lbl_tempo.text = str(stats.get("tempo", 0))
	lbl_ligacoes.text = str(stats.get("ligacoes", 0))
	lbl_precisao.text = str(stats.get("precisao", 0)) + "%"
	lbl_dias.text = str(stats.get("dias_restantes", 0))


func _on_jogar_novamente_pressed() -> void:
	if UpgradesManager:
		UpgradesManager.resetar_upgrades()
	
	EventBus.fim_de_jogo_vitoria = false
	EventBus.fim_de_jogo_stats = {}
	TransitionScreen.transition_to_scene(CENA_GAME)


func _on_button_2_pressed() -> void:
	if UpgradesManager:
		UpgradesManager.resetar_upgrades()
	
	EventBus.fim_de_jogo_vitoria = false
	EventBus.fim_de_jogo_stats = {}
	TransitionScreen.transition_to_scene(CENA_MENU_GAME)
