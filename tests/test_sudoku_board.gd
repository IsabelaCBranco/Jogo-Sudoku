extends GutTest
## Testes do modelo de tabuleiro (SudokuBoard / SudokuCell).

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

var _vazio: Array
var _nenhum_original: Array
var _tabuleiro_inicial: Array
var _originais: Array
var _board: SudokuBoard


func _grade_vazia() -> Array:
	var grade: Array = []
	for i in 9:
		var fileira: Array = []
		for j in 9:
			fileira.append(0)
		grade.append(fileira)
	return grade


func before_each() -> void:
	_vazio = _grade_vazia()
	_nenhum_original = _grade_vazia()
	# Estado inicial: somente os três primeiros números da linha 0 são dados.
	_tabuleiro_inicial = _grade_vazia()
	_tabuleiro_inicial[0][0] = 5
	_tabuleiro_inicial[0][1] = 3
	_tabuleiro_inicial[0][2] = 4
	_originais = _grade_vazia()
	_originais[0][0] = 1
	_originais[0][1] = 1
	_originais[0][2] = 1


func _novo_board() -> SudokuBoard:
	return SudokuBoard.new(_tabuleiro_inicial, SOLUCAO, _originais)


# --- Tabuleiro vazio ---

func test_tabuleiro_vazio() -> void:
	var board: SudokuBoard = SudokuBoard.new(_vazio, SOLUCAO, _nenhum_original)
	assert_eq(board.get_valor(4, 4), 0)
	assert_true(board.esta_vazia(4, 4))
	assert_false(board.esta_completa())
	assert_false(board.verificar_vitoria())
	assert_false(board.tem_erro(4, 4))


func test_nenhuma_celula_bloqueada_no_vazio() -> void:
	var board: SudokuBoard = SudokuBoard.new(_vazio, SOLUCAO, _nenhum_original)
	assert_false(board.esta_bloqueada(0, 0))


func test_contar_preenchidas() -> void:
	var board: SudokuBoard = SudokuBoard.new(_vazio, SOLUCAO, _nenhum_original)
	assert_eq(board.contar_preenchidas(), 0)

	var com_dados := _novo_board()
	assert_eq(com_dados.contar_preenchidas(), 3)

	com_dados.definir_valor(4, 4, 5)
	com_dados.definir_valor(4, 5, 1)
	assert_eq(com_dados.contar_preenchidas(), 5)


# --- Inserção válida ---

func test_insercao_valida() -> void:
	var board := _novo_board()
	assert_true(board.definir_valor(0, 3, 6))
	assert_eq(board.get_valor(0, 3), 6)
	assert_false(board.tem_erro(0, 3))


func test_insercao_valida_emite_sinal() -> void:
	var board := _novo_board()
	watch_signals(board)
	board.definir_valor(0, 3, 6)
	assert_signal_emitted_with_parameters(board, "celula_alterada", [0, 3, 6])


func test_movimento_valido() -> void:
	var board := _novo_board()
	assert_true(board.movimento_valido(0, 3, 6))


# --- Inserção inválida ---

func test_insercao_invalida_por_conflito() -> void:
	var board := _novo_board()
	# 5 já existe na linha 0 (coluna 0).
	assert_false(board.movimento_valido(0, 4, 5))


func test_conflito_de_regra_marca_erro() -> void:
	var board := _novo_board()
	# Solução correta de (0,4) é 7; inserir 5 duplica a linha e diverge da solução.
	assert_true(board.definir_valor(0, 4, 5))
	assert_true(board.tem_erro(0, 4))


func test_valor_incorreto_marca_erro() -> void:
	var board := _novo_board()
	board.definir_valor(0, 3, 9)  # Solução correta é 6.
	assert_true(board.tem_erro(0, 3))


func test_valor_incorreto_emite_sinal_de_erro() -> void:
	var board := _novo_board()
	watch_signals(board)
	board.definir_valor(0, 3, 9)
	assert_signal_emitted_with_parameters(board, "celula_errada", [0, 3, 9])


func test_valor_fora_do_range_nao_insere() -> void:
	var board := _novo_board()
	assert_false(board.definir_valor(0, 3, 10))
	assert_false(board.definir_valor(0, 3, 0))
	assert_true(board.esta_vazia(0, 3))


func test_remover_valor() -> void:
	var board := _novo_board()
	board.definir_valor(0, 3, 6)
	assert_true(board.remover_valor(0, 3))
	assert_true(board.esta_vazia(0, 3))
	assert_false(board.tem_erro(0, 3))


# --- Células bloqueadas ---

func test_celula_bloqueada_nao_aceita_alteracao() -> void:
	var board := _novo_board()
	assert_true(board.esta_bloqueada(0, 0))
	assert_false(board.definir_valor(0, 0, 1))
	assert_false(board.remover_valor(0, 0))
	assert_eq(board.get_valor(0, 0), 5)


func test_celula_editavel_nao_e_bloqueada() -> void:
	var board := _novo_board()
	assert_false(board.esta_bloqueada(0, 3))


func test_valores_linha_coluna_bloco() -> void:
	var board := _novo_board()
	assert_eq(board.get_valores_linha(0), [5, 3, 4])
	assert_eq(board.get_valores_coluna(0), [5])
	assert_eq(board.get_valores_bloco(0, 0), [5, 3, 4])


# --- Verificação de vitória ---

func test_vitoria_apenas_com_tabuleiro_igual_a_solucao() -> void:
	var board: SudokuBoard = SudokuBoard.new(_grade_vazia(), SOLUCAO, _nenhum_original)
	# Preenche tudo, mas com erro em uma célula: não é vitória.
	_preencher(board, SOLUCAO)
	board.definir_valor(0, 0, 9)  # Solução é 5.
	assert_true(board.esta_completa())
	assert_false(board.verificar_vitoria())


func test_vitoria_com_tabuleiro_igual_a_solucao() -> void:
	var board: SudokuBoard = SudokuBoard.new(_grade_vazia(), SOLUCAO, _nenhum_original)
	_preencher(board, SOLUCAO)
	assert_true(board.verificar_vitoria())


func test_vitoria_emite_sinal_uma_vez() -> void:
	var board: SudokuBoard = SudokuBoard.new(_grade_vazia(), SOLUCAO, _nenhum_original)
	watch_signals(board)
	_preencher(board, SOLUCAO)
	assert_signal_emit_count(board, "vitoria", 1)
	board.verificar_vitoria()
	board.verificar_vitoria()
	assert_signal_emit_count(board, "vitoria", 1)


# --- Anotações ---

func test_adicionar_remover_anotacao() -> void:
	var board := _novo_board()
	assert_true(board.adicionar_anotacao(0, 3, 1))
	assert_true(board.tem_anotacao(0, 3, 1))
	assert_false(board.adicionar_anotacao(0, 3, 1))
	assert_true(board.remover_anotacao(0, 3, 1))
	assert_false(board.tem_anotacao(0, 3, 1))


func test_insercao_definitiva_limpa_anotacoes_da_celula() -> void:
	var board := _novo_board()
	board.adicionar_anotacao(0, 3, 1)
	board.definir_valor(0, 3, 6)
	assert_eq(board.get_anotacoes(0, 3), [])


func test_insercao_remove_anotacao_incompativeis_relacionadas() -> void:
	var board := _novo_board()
	board.adicionar_anotacao(5, 3, 6)  # mesma coluna do valor inserido em (0,3)
	board.adicionar_anotacao(4, 4, 6)  # célula não relacionada a (0,3)
	board.definir_valor(0, 3, 6)
	assert_false(board.tem_anotacao(5, 3, 6))
	assert_true(board.tem_anotacao(4, 4, 6))


# --- Reinício ---

func test_reiniciar_restaura_estado_original() -> void:
	var board := _novo_board()
	board.definir_valor(0, 3, 6)
	board.definir_valor(1, 0, 6)
	board.reiniciar()
	assert_true(board.esta_vazia(0, 3))
	assert_true(board.esta_vazia(1, 0))
	assert_eq(board.get_valor(0, 0), 5)
	assert_eq(board.get_valor(0, 1), 3)


func test_grade_valores() -> void:
	var board := _novo_board()
	var atual: Array = board.get_tabuleiro_atual()
	assert_eq(atual[0][0], 5)
	assert_eq(atual[8][8], 0)
	var solucao: Array = board.get_solucao()
	assert_eq(solucao[8][8], 9)
	assert_eq(board.get_mascara_originais()[0][0], 1)
	assert_eq(board.get_mascara_originais()[8][8], 0)


# --- Helpers ---

func _preencher(board: SudokuBoard, grade: Array) -> void:
	for l in 9:
		for c in 9:
			board.definir_valor(l, c, grade[l][c])
