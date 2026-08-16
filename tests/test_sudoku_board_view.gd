extends GutTest
## Testes do feedback visual do tabuleiro (SudokuBoardView): limpeza
## automática de dicas e flash de erro.

var view: SudokuBoardView
var board: SudokuBoard


func before_each() -> void:
	view = SudokuBoardView.new()
	view.custom_minimum_size = Vector2(270, 270)
	add_child_autofree(view)

	var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.FACIL, 4242)
	board = SudokuBoard.new(resultado["tabuleiro"], resultado["solucao"], resultado["originais"])
	view.configurar(board)
	view.duracao_destaque = 0.2


func _primeira_celula_editavel_vazia() -> Vector2i:
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if not board.esta_bloqueada(l, c) and board.esta_vazia(l, c):
				return Vector2i(l, c)
	return Vector2i(-1, -1)


# --- Limpeza automática de dicas ---

func test_destacar_celula_marca_destaque() -> void:
	view.destacar_celula(Vector2i(2, 3))
	assert_eq(view._celula_destaque, Vector2i(2, 3))


func test_destaque_de_dica_e_limpo_apos_tempo() -> void:
	view.destacar_celula(Vector2i(2, 3))
	assert_eq(view._celula_destaque, Vector2i(2, 3))
	await wait_seconds(0.6)
	assert_eq(view._celula_destaque, Vector2i(-1, -1))


func test_dica_mais_recente_mantem_destaque() -> void:
	view.duracao_destaque = 0.5
	view.destacar_celula(Vector2i(0, 0))
	await wait_seconds(0.2)
	view.mostrar_candidato(Vector2i(1, 1), 5)
	await wait_seconds(0.3)
	assert_eq(view._celula_candidato, Vector2i(1, 1))
	assert_eq(view._celula_destaque, Vector2i(0, 0))
	await wait_seconds(0.5)
	assert_eq(view._celula_candidato, Vector2i(-1, -1))
	assert_eq(view._celula_destaque, Vector2i(-1, -1))


func test_limpar_dicas_visuais_limpa_tudo() -> void:
	view.destacar_celula(Vector2i(0, 0))
	view.mostrar_candidato(Vector2i(1, 1), 5)
	view.limpar_dicas_visuais()
	assert_eq(view._celula_destaque, Vector2i(-1, -1))
	assert_eq(view._celula_candidato, Vector2i(-1, -1))
	assert_eq(view._candidato_valor, 0)


# --- Flash de erro ---

func test_erro_dispara_flash_na_celula() -> void:
	var alvo := _primeira_celula_editavel_vazia()
	assert_ne(alvo, Vector2i(-1, -1))
	var solucao: int = board.get_valor_solucao(alvo.x, alvo.y)
	var errado := 2 if solucao == 1 else 1
	board.definir_valor(alvo.x, alvo.y, errado)
	assert_eq(view._flash_erro_pos, alvo)
	assert_gt(view._flash_erro_tempo, 0.0)


func test_acerto_nao_dispara_flash() -> void:
	var alvo := _primeira_celula_editavel_vazia()
	board.definir_valor(alvo.x, alvo.y, board.get_valor_solucao(alvo.x, alvo.y))
	assert_eq(view._flash_erro_pos, Vector2i(-1, -1))
	assert_eq(view._flash_erro_tempo, 0.0)


func test_erro_sem_flash_quando_exibicao_desativada() -> void:
	GameSettings.definir_exibir_erros(false)
	var alvo := _primeira_celula_editavel_vazia()
	var solucao: int = board.get_valor_solucao(alvo.x, alvo.y)
	board.definir_valor(alvo.x, alvo.y, 2 if solucao == 1 else 1)
	assert_eq(view._flash_erro_pos, Vector2i(-1, -1))
	assert_eq(view._flash_erro_tempo, 0.0)
	GameSettings.definir_exibir_erros(true)


func test_flash_de_erro_desaparece_apos_tempo() -> void:
	var alvo := _primeira_celula_editavel_vazia()
	var solucao: int = board.get_valor_solucao(alvo.x, alvo.y)
	board.definir_valor(alvo.x, alvo.y, 2 if solucao == 1 else 1)
	assert_gt(view._flash_erro_tempo, 0.0)
	await wait_seconds(0.9)
	assert_eq(view._flash_erro_pos, Vector2i(-1, -1))
	assert_eq(view._flash_erro_tempo, 0.0)


func test_configurar_novo_tabuleiro_desconecta_anterior() -> void:
	var alvo := _primeira_celula_editavel_vazia()
	var solucao: int = board.get_valor_solucao(alvo.x, alvo.y)

	var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.FACIL, 777)
	var outro := SudokuBoard.new(resultado["tabuleiro"], resultado["solucao"], resultado["originais"])
	view.configurar(outro)

	board.definir_valor(alvo.x, alvo.y, 2 if solucao == 1 else 1)
	assert_eq(view._flash_erro_pos, Vector2i(-1, -1))
