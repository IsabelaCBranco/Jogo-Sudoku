class_name ScoreSystem
extends RefCounted
## Cálculo centralizado da pontuação.
##
## Fórmula:
##   base = 1000 * dificuldade
##   - 50 por erro
##   - 100/150/200 por dica nível 1/2/3
##   - 2 por segundo decorrido
##   + 25 por vida restante (somente no cálculo final)
## O resultado nunca é negativo.

signal pontuacao_alterada(pontos: int)

const BASE_POR_DIFICULDADE: int = 1000
const PENALIDADE_ERRO: int = 50
const PENALIDADE_POR_SEGUNDO: int = 2
const BONUS_POR_VIDA: int = 25
const PENALIDADES_DICA := {
	HintSystem.DICA_DESTACAR: 100,
	HintSystem.DICA_CANDIDATO: 150,
	HintSystem.DICA_RESOLVER: 200,
}

var dificuldade: int = DifficultyManager.Dificuldade.FACIL
var _erros: int = 0
var _dicas: Dictionary = {}
var _tempo_segundos: int = 0


func iniciar(dificuldade: int) -> void:
	self.dificuldade = dificuldade
	_erros = 0
	_dicas.clear()
	_tempo_segundos = 0
	pontuacao_alterada.emit(get_pontuacao())


func reiniciar() -> void:
	_erros = 0
	_dicas.clear()
	_tempo_segundos = 0
	pontuacao_alterada.emit(get_pontuacao())


func registrar_erro() -> void:
	_erros += 1
	pontuacao_alterada.emit(get_pontuacao())


func registrar_dica(nivel: int) -> void:
	_dicas[nivel] = int(_dicas.get(nivel, 0)) + 1
	pontuacao_alterada.emit(get_pontuacao())


func atualizar_tempo(segundos: int) -> void:
	_tempo_segundos = segundos
	pontuacao_alterada.emit(get_pontuacao())


func get_erros() -> int:
	return _erros


func serializar() -> Dictionary:
	return {
		"dificuldade": dificuldade,
		"erros": _erros,
		"dicas": _dicas,
		"tempo_segundos": _tempo_segundos,
	}


func carregar_estado(dados: Dictionary) -> void:
	if dados.is_empty():
		return
	dificuldade = int(dados.get("dificuldade", dificuldade))
	_erros = int(dados.get("erros", 0))
	_dicas.clear()
	var dicas: Dictionary = dados.get("dicas", {})
	for nivel in dicas:
		_dicas[int(nivel)] = int(dicas[nivel])
	_tempo_segundos = int(dados.get("tempo_segundos", 0))
	pontuacao_alterada.emit(get_pontuacao())


func get_total_dicas() -> int:
	var total: int = 0
	for valor in _dicas.values():
		total += int(valor)
	return total


func get_pontuacao() -> int:
	return maxi(0, _calcular_base())


func calcular_final(vidas_restantes: int) -> int:
	return maxi(0, _calcular_base() + vidas_restantes * BONUS_POR_VIDA)


func _calcular_base() -> int:
	var pontos := BASE_POR_DIFICULDADE * dificuldade
	pontos -= _erros * PENALIDADE_ERRO
	pontos -= _tempo_segundos * PENALIDADE_POR_SEGUNDO
	for nivel in _dicas:
		pontos -= int(_dicas[nivel]) * int(PENALIDADES_DICA.get(nivel, 100))
	return pontos
