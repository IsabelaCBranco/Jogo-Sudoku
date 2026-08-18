extends GutTest
## Testes do sistema de dicas.

const SOLUCAO := [
	[5, 3, 4, 6, 7, 8, 9, 1, 2],
	[6, 7, 2, 1, 9, 5, 3, 4, 8],
	[1, 9, 8, 3, 4, 2, 5, 6, 7],
	[8, 5, 9, 7, 6, 1, 4, 2, 3],
	[4, 2, 6, 8, 5, 3, 7, 9, 1],
	[7, 1, 3, 9, 2, 4, 8, 5, 6],
	[9, 6, 1, 5, 3, 7, 2, 8, 4],
	[2, 8, 7, 4, 1, 9, 6, 3, 5],
	[3, 4, 5, 2, 8, 6, 1, 7, 9],
]

const PUZZLE := [
	[5, 3, 0, 0, 7, 0, 0, 0, 0],
	[6, 0, 0, 1, 9, 5, 0, 0, 0],
	[0, 9, 8, 0, 0, 0, 0, 6, 0],
	[8, 0, 0, 0, 6, 0, 0, 0, 3],
	[4, 0, 0, 8, 0, 3, 0, 0, 1],
	[7, 0, 0, 0, 2, 0, 0, 0, 6],
	[0, 6, 0, 0, 0, 0, 2, 8, 0],
	[0, 0, 0, 4, 1, 9, 0, 0, 5],
	[0, 0, 0, 0, 8, 0, 0, 7, 9],
]


func _grade() -> Array:
	var grade: Array = []
	for i in 9:
		var fileira: Array = []
		for j in 9:
			fileira.append(0)
		grade.append(fileira)
	return grade


func _mascara(puzzle: Array) -> Array:
	var resultado := _grade()
	for l in 9:
		for c in 9:
			resultado[l][c] = 1 if puzzle[l][c] != 0 else 0
	return resultado


func _board(puzzle: Array = PUZZLE) -> SudokuBoard:
	return SudokuBoard.new(puzzle, SOLUCAO, _mascara(puzzle))


func _board_com_uma_vazia() -> SudokuBoard:
	var puzzle := _grade()
	for l in 9:
		for c in 9:
			puzzle[l][c] = SOLUCAO[l][c]
	puzzle[0][2] = 0
	return _board(puzzle)


func _board_completo() -> SudokuBoard:
	return _board(SOLUCAO)


# --- Contar ---

func test_contar_celula_com_poucos_candidatos() -> void:
	var board := _board_com_uma_vazia()
	var info := HintSystem.get_contagem_candidatos(board, Vector2i(0, 2))
	assert_false(info.is_empty())
	assert_eq(info["celula"], Vector2i(0, 2))
	assert_eq(info["quantidade"], 1)


func test_contar_sem_alvo_retorna_celula_vazia() -> void:
	var board := _board_com_uma_vazia()
	var info := HintSystem.get_contagem_candidatos(board, Vector2i(-1, -1))
	assert_false(info.is_empty())
	assert_eq(info["celula"], Vector2i(0, 2))
	assert_eq(info["quantidade"], 1)


func test_contar_ignora_alvo_bloqueado() -> void:
	var board := _board()
	var alvo := Vector2i(0, 0)
	var info := HintSystem.get_contagem_candidatos(board, alvo)
	assert_false(info.is_empty())
	var celula: Vector2i = info["celula"]
	assert_true(board.esta_vazia(celula.x, celula.y))
	assert_gt(info["quantidade"], 0)


func test_contar_sem_celulas_vazias_retorna_vazio() -> void:
	var board := _board_completo()
	var info := HintSystem.get_contagem_candidatos(board, Vector2i(-1, -1))
	assert_true(info.is_empty())


# --- Candidato ---

func test_candidato_com_alvo_vazio() -> void:
	var board := _board()
	var info := HintSystem.get_candidato(board, Vector2i(0, 2))
	assert_false(info.is_empty())
	assert_eq(info["celula"], Vector2i(0, 2))
	assert_eq(int(info["valor"]), SOLUCAO[0][2])


func test_candidato_com_alvo_bloqueado_faz_fallback() -> void:
	var board := _board()
	var info := HintSystem.get_candidato(board, Vector2i(0, 0))
	assert_false(info.is_empty())
	var celula: Vector2i = info["celula"]
	assert_true(board.esta_vazia(celula.x, celula.y))
	assert_eq(int(info["valor"]), SOLUCAO[celula.x][celula.y])


func test_candidato_sem_celulas_vazias() -> void:
	var board := _board_completo()
	var info := HintSystem.get_candidato(board, Vector2i(0, 0))
	assert_true(info.is_empty())


# --- Resolver ---

func test_resolver_alvo_vazio() -> void:
	var board := _board()
	var celula := HintSystem.get_celula_resolvivel(board, Vector2i(0, 2))
	assert_eq(celula, Vector2i(0, 2))


func test_resolver_alvo_bloqueado_faz_fallback() -> void:
	var board := _board()
	var celula := HintSystem.get_celula_resolvivel(board, Vector2i(0, 0))
	assert_ne(celula, HintSystem.CELULA_INVALIDA)
	assert_true(board.esta_vazia(celula.x, celula.y))


func test_resolver_sem_celulas_vazias() -> void:
	var board := _board_completo()
	var celula := HintSystem.get_celula_resolvivel(board, Vector2i(-1, -1))
	assert_eq(celula, HintSystem.CELULA_INVALIDA)
