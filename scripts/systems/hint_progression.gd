extends Node
## Progresso persistente das dicas (autoload).
##
## As dicas são desbloqueadas permanentemente ao vencer partidas. Cada vitória
## concede usos que se acumulam entre partidas e sessões. Usar uma dica
## consome uma unidade do estoque, que nunca reseta. Persistência via SaveManager.

signal dicas_alteradas

const RECOMPENSAS := {
	DifficultyManager.Dificuldade.MUITO_FACIL: [],
	DifficultyManager.Dificuldade.FACIL: [HintSystem.DICA_DESTACAR],
	DifficultyManager.Dificuldade.MEDIO: [HintSystem.DICA_CANDIDATO],
	DifficultyManager.Dificuldade.DIFICIL: [HintSystem.DICA_RESOLVER],
	DifficultyManager.Dificuldade.ESPECIALISTA: [
		HintSystem.DICA_DESTACAR,
		HintSystem.DICA_CANDIDATO,
		HintSystem.DICA_RESOLVER,
	],
}

var _estoque: Dictionary = {}


func _ready() -> void:
	carregar()


## Concede os usos da dificuldade vencida. A recompensa é salva imediatamente.
func registrar_vitoria(dificuldade: int) -> void:
	for nivel in RECOMPENSAS.get(dificuldade, []):
		var tipo: int = int(nivel)
		_estoque[tipo] = get_disponiveis(tipo) + 1
	salvar()
	dicas_alteradas.emit()


func pode_usar(nivel: int) -> bool:
	return get_disponiveis(nivel) > 0


## Consome uma dica do estoque. Retorna false quando indisponível.
func consumir(nivel: int) -> bool:
	if not pode_usar(nivel):
		return false
	_estoque[nivel] = get_disponiveis(nivel) - 1
	salvar()
	dicas_alteradas.emit()
	return true


func get_disponiveis(nivel: int) -> int:
	return int(_estoque.get(nivel, 0))


func get_total() -> int:
	var total: int = 0
	for valor in _estoque.values():
		total += int(valor)
	return total


func serializar() -> Dictionary:
	return {
		"estoque": _estoque.duplicate(),
	}


func salvar() -> void:
	SaveManager.salvar_dicas(serializar())


func carregar() -> void:
	var dados := SaveManager.carregar_dicas()
	if dados.is_empty():
		return
	_estoque.clear()
	var estoque: Dictionary = dados.get("estoque", {})
	for nivel in estoque:
		_estoque[int(nivel)] = int(estoque[nivel])
	dicas_alteradas.emit()


## Restaura o estado padrão (uso em testes).
func reset() -> void:
	_estoque.clear()
	dicas_alteradas.emit()
