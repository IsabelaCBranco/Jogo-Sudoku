extends Node
## Estatísticas agregadas do jogador, separadas da partida atual.
##
## Autoload: registra partidas, vitórias, derrotas, erros, dicas e os
## melhores resultados por dificuldade. Persistência via SaveManager.
## Os contadores de erros e dicas são agregados no encerramento da partida
## (vitória/derrota), evitando contagem dupla com eventos ao vivo.

signal estatisticas_alteradas

var partidas_iniciadas: int = 0
var partidas_concluidas: int = 0
var partidas_vencidas: int = 0
var partidas_perdidas: int = 0
var tempo_total_segundos: int = 0
var erros_total: int = 0
var dicas_total: int = 0

var _melhor_tempo_por_dificuldade: Dictionary = {}
var _melhor_pontuacao_por_dificuldade: Dictionary = {}


func _ready() -> void:
	carregar()


func registrar_partida_iniciada() -> void:
	partidas_iniciadas += 1
	estatisticas_alteradas.emit()
	salvar()


func registrar_vitoria(dificuldade: int, tempo_segundos: int, pontuacao: int, erros: int, dicas: int) -> void:
	partidas_concluidas += 1
	partidas_vencidas += 1
	tempo_total_segundos += tempo_segundos
	erros_total += erros
	dicas_total += dicas
	_atualizar_melhores(dificuldade, tempo_segundos, pontuacao)
	estatisticas_alteradas.emit()
	salvar()


func registrar_derrota(dificuldade: int, erros: int, dicas: int) -> void:
	partidas_concluidas += 1
	partidas_perdidas += 1
	erros_total += erros
	dicas_total += dicas
	estatisticas_alteradas.emit()
	salvar()


func get_melhor_tempo(dificuldade: int) -> int:
	return int(_melhor_tempo_por_dificuldade.get(dificuldade, 0))


func get_melhor_pontuacao(dificuldade: int) -> int:
	return int(_melhor_pontuacao_por_dificuldade.get(dificuldade, 0))


func get_tempo_medio() -> float:
	if partidas_concluidas == 0:
		return 0.0
	return tempo_total_segundos / float(partidas_concluidas)


func get_media_erros() -> float:
	if partidas_concluidas == 0:
		return 0.0
	return erros_total / float(partidas_concluidas)


func get_total_dicas() -> int:
	return dicas_total


func reset() -> void:
	partidas_iniciadas = 0
	partidas_concluidas = 0
	partidas_vencidas = 0
	partidas_perdidas = 0
	tempo_total_segundos = 0
	erros_total = 0
	dicas_total = 0
	_melhor_tempo_por_dificuldade.clear()
	_melhor_pontuacao_por_dificuldade.clear()
	estatisticas_alteradas.emit()


func salvar() -> void:
	SaveManager.salvar_estatisticas(serializar())


func carregar() -> void:
	var dados := SaveManager.carregar_estatisticas()
	if dados.is_empty():
		return
	partidas_iniciadas = int(dados.get("partidas_iniciadas", partidas_iniciadas))
	partidas_concluidas = int(dados.get("partidas_concluidas", partidas_concluidas))
	partidas_vencidas = int(dados.get("partidas_vencidas", partidas_vencidas))
	partidas_perdidas = int(dados.get("partidas_perdidas", partidas_perdidas))
	tempo_total_segundos = int(dados.get("tempo_total_segundos", tempo_total_segundos))
	erros_total = int(dados.get("erros_total", erros_total))
	dicas_total = int(dados.get("dicas_total", dicas_total))
	_reconstruir_melhores(dados)


func serializar() -> Dictionary:
	var melhores: Array = []
	for dificuldade in _melhor_tempo_por_dificuldade:
		melhores.append({
			"dificuldade": dificuldade,
			"tempo": _melhor_tempo_por_dificuldade[dificuldade],
			"pontuacao": _melhor_pontuacao_por_dificuldade.get(dificuldade, 0),
		})
	return {
		"partidas_iniciadas": partidas_iniciadas,
		"partidas_concluidas": partidas_concluidas,
		"partidas_vencidas": partidas_vencidas,
		"partidas_perdidas": partidas_perdidas,
		"tempo_total_segundos": tempo_total_segundos,
		"erros_total": erros_total,
		"dicas_total": dicas_total,
		"melhores": melhores,
	}


func _reconstruir_melhores(dados: Dictionary) -> void:
	_melhor_tempo_por_dificuldade.clear()
	_melhor_pontuacao_por_dificuldade.clear()
	for item in dados.get("melhores", []):
		var dificuldade: int = int(item.get("dificuldade", 0))
		var tempo: int = int(item.get("tempo", 0))
		var pontuacao: int = int(item.get("pontuacao", 0))
		_melhor_tempo_por_dificuldade[dificuldade] = tempo
		_melhor_pontuacao_por_dificuldade[dificuldade] = pontuacao


func _atualizar_melhores(dificuldade: int, tempo_segundos: int, pontuacao: int) -> void:
	var tempo_atual := get_melhor_tempo(dificuldade)
	if tempo_atual == 0 or tempo_segundos < tempo_atual:
		_melhor_tempo_por_dificuldade[dificuldade] = tempo_segundos
	var pontuacao_atual := get_melhor_pontuacao(dificuldade)
	if pontuacao > pontuacao_atual:
		_melhor_pontuacao_por_dificuldade[dificuldade] = pontuacao
