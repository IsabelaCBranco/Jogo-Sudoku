extends GutTest
## Testes do resolvedor de Sudoku (SudokuSolver).

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

# Puzzle clássico com solução única (igual a SOLUCAO).
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

# Tabuleiro consistente (sem duplicatas) porém sem solução:
# (0,8) precisa ser 9, mas a coluna 8 já possui 9 em (1,8).
const SEM_SOLUCAO := [
	[1, 2, 3, 4, 5, 6, 7, 8, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 9],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
]

# Tabuleiro com duplicata na primeira linha (inválido).
const INVALIDO := [
	[5, 5, 0, 0, 7, 0, 0, 0, 0],
	[6, 0, 0, 1, 9, 5, 0, 0, 0],
	[0, 9, 8, 0, 0, 0, 0, 6, 0],
	[8, 0, 0, 0, 6, 0, 0, 0, 3],
	[4, 0, 0, 8, 0, 3, 0, 0, 1],
	[7, 0, 0, 0, 2, 0, 0, 0, 6],
	[0, 6, 0, 0, 0, 0, 2, 8, 0],
	[0, 0, 0, 4, 1, 9, 0, 0, 5],
	[0, 0, 0, 0, 8, 0, 0, 7, 9],
]


func _grade_vazia() -> Array:
	var grade: Array = []
	for i in 9:
		grade.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
	return grade


func _e_solucao_valida(grade: Array) -> bool:
	for i in 9:
		var linha: Array = grade[i]
		var coluna: Array = []
		for j in 9:
			coluna.append(grade[j][i])
		var bloco: Array = []
		var inicio_linha: int = (i / 3) * 3
		var inicio_coluna: int = (i % 3) * 3
		for l in 3:
			for c in 3:
				bloco.append(grade[inicio_linha + l][inicio_coluna + c])
		for grupo in [linha, coluna, bloco]:
			for valor in range(1, 10):
				if not grupo.has(valor):
					return false
	return true


# --- Sudoku válido ---

func test_resolver_tabuleiro_completo_valido() -> void:
	var resultado: Array = SudokuSolver.resolver(SOLUCAO)
	assert_eq(resultado.size(), 9)
	assert_true(_e_solucao_valida(resultado))


func test_resolver_puzzle_com_solucao() -> void:
	var resultado: Array = SudokuSolver.resolver(PUZZLE)
	assert_eq(resultado.size(), 9)
	assert_eq(resultado, SOLUCAO)


func test_tem_solucao_para_puzzle_valido() -> void:
	assert_true(SudokuSolver.tem_solucao(PUZZLE))


func test_resolver_nao_modifica_a_entrada() -> void:
	var copia: Array = []
	for linha in PUZZLE:
		copia.append(linha.duplicate())
	SudokuSolver.resolver(PUZZLE)
	assert_eq(PUZZLE, copia)


# --- Solução única ---

func test_puzzle_possui_solucao_unica() -> void:
	assert_true(SudokuSolver.tem_solucao_unica(PUZZLE))
	assert_eq(SudokuSolver.contar_solucoes(PUZZLE), 1)


func test_tabuleiro_completo_valido_tem_uma_solucao() -> void:
	assert_eq(SudokuSolver.contar_solucoes(SOLUCAO), 1)


# --- Múltiplas soluções ---

func test_tabuleiro_com_multiplas_solucoes() -> void:
	var tabuleiro := _grade_vazia()
	tabuleiro[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	assert_eq(SudokuSolver.contar_solucoes(tabuleiro, 2), 2)
	assert_false(SudokuSolver.tem_solucao_unica(tabuleiro))


func test_contagem_para_ao_atingir_limite() -> void:
	var tabuleiro := _grade_vazia()
	var total: int = SudokuSolver.contar_solucoes(tabuleiro, 5)
	assert_eq(total, 5)


# --- Sem solução ---

func test_sudoku_sem_solucao() -> void:
	assert_eq(SudokuSolver.contar_solucoes(SEM_SOLUCAO), 0)
	assert_false(SudokuSolver.tem_solucao(SEM_SOLUCAO))
	assert_eq(SudokuSolver.resolver(SEM_SOLUCAO).size(), 0)


# --- Inválido ---

func test_sudoku_invalido_nao_tem_solucao() -> void:
	assert_eq(SudokuSolver.contar_solucoes(INVALIDO), 0)
	assert_false(SudokuSolver.tem_solucao(INVALIDO))
	assert_false(SudokuSolver.tem_solucao_unica(INVALIDO))
	assert_eq(SudokuSolver.resolver(INVALIDO).size(), 0)


# --- Complexidade (contar_decisoes) ---

func test_complexidade_de_tabuleiro_completo_e_zero() -> void:
	assert_eq(SudokuSolver.contar_decisoes(SOLUCAO), 0)


func test_complexidade_de_puzzle_e_maior_que_zero() -> void:
	assert_gt(SudokuSolver.contar_decisoes(PUZZLE), 0)


func test_complexidade_nao_modifica_a_entrada() -> void:
	var copia: Array = []
	for linha in PUZZLE:
		copia.append(linha.duplicate())
	SudokuSolver.contar_decisoes(PUZZLE)
	assert_eq(PUZZLE, copia)


func test_tabuleiro_vazio_e_mais_complexo_que_puzzle() -> void:
	var vazio := _grade_vazia()
	assert_gt(SudokuSolver.contar_decisoes(vazio), SudokuSolver.contar_decisoes(PUZZLE))
