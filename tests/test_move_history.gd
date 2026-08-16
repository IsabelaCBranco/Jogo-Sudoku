extends GutTest
## Testes do histórico de movimentos (desfazer/refazer).

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


func _mascara(puzzle: Array) -> Array:
	var resultado: Array = []
	for l in 9:
		var fileira: Array = []
		for c in 9:
			fileira.append(1 if puzzle[l][c] != 0 else 0)
		resultado.append(fileira)
	return resultado


func _board() -> SudokuBoard:
	return SudokuBoard.new(PUZZLE, SOLUCAO, _mascara(PUZZLE))


func test_desfazer_restaura_valor() -> void:
	var board := _board()
	var history := MoveHistory.new(board)
	var antes := history.snapshot()
	board.definir_valor(0, 3, 6)
	history.registrar(antes)

	assert_true(history.pode_desfazer())
	assert_true(history.desfazer())
	assert_true(board.esta_vazia(0, 3))
	assert_eq(board.get_valor(0, 3), 0)


func test_refazer_reaplica_valor() -> void:
	var board := _board()
	var history := MoveHistory.new(board)
	var antes := history.snapshot()
	board.definir_valor(0, 3, 6)
	history.registrar(antes)
	history.desfazer()

	assert_true(history.pode_refazer())
	assert_true(history.refazer())
	assert_eq(board.get_valor(0, 3), 6)
	assert_true(history.pode_desfazer())
	assert_false(history.pode_refazer())


func test_desfazer_restaura_anotacoes() -> void:
	var board := _board()
	var history := MoveHistory.new(board)
	var antes := history.snapshot()
	board.adicionar_anotacao(0, 3, 7)
	board.adicionar_anotacao(0, 3, 9)
	history.registrar(antes)

	history.desfazer()
	assert_false(board.tem_anotacao(0, 3, 7))
	assert_false(board.tem_anotacao(0, 3, 9))

	history.refazer()
	assert_true(board.tem_anotacao(0, 3, 7))
	assert_true(board.tem_anotacao(0, 3, 9))


func test_desfazer_vazio_retorna_falso() -> void:
	var board := _board()
	var history := MoveHistory.new(board)
	assert_false(history.pode_desfazer())
	assert_false(history.desfazer())


func test_novo_movimento_limpa_refazer() -> void:
	var board := _board()
	var history := MoveHistory.new(board)

	var antes := history.snapshot()
	board.definir_valor(0, 3, 6)
	history.registrar(antes)
	history.desfazer()
	assert_true(history.pode_refazer())

	var antes2 := history.snapshot()
	board.definir_valor(0, 4, 8)
	history.registrar(antes2)
	assert_false(history.pode_refazer())
	assert_true(history.pode_desfazer())


func test_limpar_esvazia_historico() -> void:
	var board := _board()
	var history := MoveHistory.new(board)
	var antes := history.snapshot()
	board.definir_valor(0, 3, 6)
	history.registrar(antes)
	assert_true(history.pode_desfazer())

	history.limpar()
	assert_false(history.pode_desfazer())
	assert_false(history.pode_refazer())


func test_limite_do_historico() -> void:
	var board := _board()
	var history := MoveHistory.new(board)
	for i in MoveHistory.LIMITE + 50:
		history.registrar(history.snapshot())
	assert_eq(history.tamanho_historico(), MoveHistory.LIMITE)
