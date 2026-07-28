extends Control

const TOAST_SCENE := preload("res://Scenes/toast_acao.tscn")

const MAX_TOASTS := 4
const TEMPO_EXIBICAO := 2.0

@onready var stack: VBoxContainer = $MarginContainer/Stack


func mostrar_acao(categoria: String, resultado: int, pontos: float) -> void:
	var tipo := _mapear_resultado(resultado)
	var toast: PanelContainer = TOAST_SCENE.instantiate()
	stack.add_child(toast)
	stack.move_child(toast, 0)

	toast.configurar(categoria, tipo, pontos)
	await get_tree().process_frame
	toast.animar_entrada()

	_limitar_quantidade()
	_atualizar_opacidades_stack()

	_ciclo_de_vida_toast(toast)


func _mapear_resultado(resultado: int) -> ToastAcao.TipoResultado:
	match resultado:
		0:
			return ToastAcao.TipoResultado.CORRETO
		2:
			return ToastAcao.TipoResultado.TIMEOUT
		_:
			return ToastAcao.TipoResultado.INCORRETO


func _ciclo_de_vida_toast(toast: PanelContainer) -> void:
	await get_tree().create_timer(TEMPO_EXIBICAO).timeout

	if not is_instance_valid(toast):
		return

	await toast.animar_saida()

	if is_instance_valid(toast):
		toast.queue_free()
		_atualizar_opacidades_stack()


func _limitar_quantidade() -> void:
	while stack.get_child_count() > MAX_TOASTS:
		var mais_antigo := stack.get_child(stack.get_child_count() - 1)
		mais_antigo.queue_free()


func _atualizar_opacidades_stack() -> void:
	var total := stack.get_child_count()
	for indice in total:
		var toast: PanelContainer = stack.get_child(indice)
		if not toast.has_method("definir_opacidade_base"):
			continue

		var opacidade := 1.0
		if indice > 0:
			opacidade = clampf(1.0 - (indice * 0.22), 0.35, 1.0)
		toast.definir_opacidade_base(opacidade)
