class_name HintSystem
extends RefCounted
## Sistema de dicas.
##
## O jogador seleciona uma célula e pede a dica; quando nenhuma célula está
## selecionada (alvo = Vector2i(-1, -1)), o sistema escolhe uma célula vazia
## editável aleatoriamente. Toda dica aplicada gera penalidade na pontuação.

const DICA_CONTAR: int = 1
const DICA_CANDIDATO: int = 2
const DICA_RESOLVER: int = 3

const NOMES_DICA := {
	DICA_CONTAR: "Contar",
	DICA_CANDIDATO: "Revelar",
	DICA_RESOLVER: "Preencher",
}

const CELULA_INVALIDA := Vector2i(-1, -1)


## Nome legível da dica, exibido na interface.
static func get_nome_dica(nivel: int) -> String:
	return NOMES_DICA.get(nivel, "Desconhecida")


## Contar: retorna { "celula": Vector2i, "quantidade": int } com a contagem
## de candidatos válidos para uma célula vazia. Respeita o alvo quando válido;
## senão procura outra célula vazia.
static func get_contagem_candidatos(board: SudokuBoard, alvo: Vector2i) -> Dictionary:
	var celula := _escolher_celula_alvo(board, alvo)
	if celula == CELULA_INVALIDA:
		return {}
	var candidatos := _candidatos(board, celula)
	return {
		"celula": celula,
		"quantidade": candidatos.size(),
	}


## Revelar: retorna um dicionário { celula, valor } com a solução da célula.
static func get_candidato(board: SudokuBoard, alvo: Vector2i) -> Dictionary:
	var celula := _escolher_celula_alvo(board, alvo)
	if celula == CELULA_INVALIDA:
		return {}
	return {
		"celula": celula,
		"valor": board.get_valor_solucao(celula.x, celula.y),
	}


## Preencher: retorna a célula que deve ser resolvida com a solução.
static func get_celula_resolvivel(board: SudokuBoard, alvo: Vector2i) -> Vector2i:
	return _escolher_celula_alvo(board, alvo)


static func _escolher_celula_alvo(board: SudokuBoard, alvo: Vector2i) -> Vector2i:
	if _e_alvo_valido(board, alvo):
		return alvo
	var vazias := _celulas_vazias(board)
	if vazias.is_empty():
		return CELULA_INVALIDA
	return vazias[randi() % vazias.size()]


static func _e_alvo_valido(board: SudokuBoard, alvo: Vector2i) -> bool:
	if alvo == CELULA_INVALIDA:
		return false
	return board.esta_vazia(alvo.x, alvo.y) and not board.esta_bloqueada(alvo.x, alvo.y)


static func _candidatos(board: SudokuBoard, celula: Vector2i) -> Array[int]:
	var resultado: Array[int] = []
	for valor in range(1, 10):
		if board.movimento_valido(celula.x, celula.y, valor):
			resultado.append(valor)
	return resultado


static func _celulas_vazias(board: SudokuBoard) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if board.esta_vazia(l, c):
				resultado.append(Vector2i(l, c))
	return resultado
