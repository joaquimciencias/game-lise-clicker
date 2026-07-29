extends Node

@export var tempo_animacao: float = 0.35

func animar_abertura(painel: Control) -> void:
	if not painel: return
	painel.visible = true
	painel.modulate.a = 0.0
	painel.scale = Vector2(0.95, 0.95)
	
	var tween = painel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(painel, "modulate:a", 1.0, tempo_animacao).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(painel, "scale", Vector2.ONE, tempo_animacao).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animar_fechamento(painel: Control) -> void:
	if not painel: return
	var tween = painel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(painel, "modulate:a", 0.0, tempo_animacao).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(painel, "scale", Vector2(0.95, 0.95), tempo_animacao).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	painel.visible = false
