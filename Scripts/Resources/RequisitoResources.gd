class_name RequisitoResource
extends Resource

enum TipoRequisito { FISICAS, PATRIMONIAIS, PSICOLOGICAS, MORAIS }

@export var tipo: TipoRequisito = TipoRequisito.FISICAS
@export var icone: Texture2D
@export var custo: int = 0

# Deixe assim, sem @export (já que ela muda dinamicamente no jogo)
var atual: int = 0
