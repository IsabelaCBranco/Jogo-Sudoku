extends GutTest
## Testes do gerador de Sudoku (SudokuGenerator).

func _contar_preenchidas(grade: Array) -> int:
	var total: int = 0
	for linha in grade:
		for valor in linha:
			if valor != 0:
				total += 1
	return total


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


# --- Tabuleiro válido ---

func test_tabuleiro_gerado_e_valido() -> void:
	var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.FACIL, 1234)
	var tabuleiro: Array = resultado["tabuleiro"]
	var solucao: Array = resultado["solucao"]
	assert_eq(tabuleiro.size(), 9)
	assert_eq(solucao.size(), 9)
	assert_true(_e_solucao_valida(solucao))
	# Células fornecidas do puzzle devem coincidir com a solução.
	for l in 9:
		for c in 9:
			if tabuleiro[l][c] != 0:
				assert_eq(tabuleiro[l][c], solucao[l][c])


func test_puzzle_gera_solucao() -> void:
	var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.MEDIO, 7)
	assert_true(SudokuSolver.tem_solucao(resultado["tabuleiro"]))


# --- Solução única ---

func test_puzzle_possui_solucao_unica() -> void:
	var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.DIFICIL, 99)
	assert_true(SudokuSolver.tem_solucao_unica(resultado["tabuleiro"]))


func test_puzzle_unicidade_em_varias_seeds() -> void:
	for seed in range(1, 11):
		var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.ESPECIALISTA, seed)
		assert_true(
			SudokuSolver.tem_solucao_unica(resultado["tabuleiro"]),
			"Falhou com seed %d" % seed
		)


# --- Dificuldade ---

func test_dificuldade_respeita_faixa() -> void:
	var por_nivel := {
		DifficultyManager.Dificuldade.MUITO_FACIL: 10,
		DifficultyManager.Dificuldade.FACIL: 20,
		DifficultyManager.Dificuldade.MEDIO: 30,
		DifficultyManager.Dificuldade.DIFICIL: 40,
		DifficultyManager.Dificuldade.ESPECIALISTA: 50,
	}
	for dificuldade in por_nivel.keys():
		var resultado := SudokuGenerator.gerar(dificuldade, por_nivel[dificuldade])
		var preenchidas: int = resultado["preenchidas"]
		var faixa := DifficultyManager.pegar_faixa(dificuldade)
		assert_gte(preenchidas, faixa.x, "Nível %d preencheu %d (mínimo %d)" % [dificuldade, preenchidas, faixa.x])
		assert_lte(preenchidas, faixa.y, "Nível %d preencheu %d (máximo %d)" % [dificuldade, preenchidas, faixa.y])


func test_mascara_originais_coincide_com_celulas_preenchidas() -> void:
	var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.FACIL, 42)
	var tabuleiro: Array = resultado["tabuleiro"]
	var originais: Array = resultado["originais"]
	for l in 9:
		for c in 9:
			assert_eq(originais[l][c], 1 if tabuleiro[l][c] != 0 else 0)


# --- Complexidade ---

func test_gerar_retorna_complexidade_positiva() -> void:
	for seed in [1, 2, 3]:
		var resultado := SudokuGenerator.gerar(DifficultyManager.Dificuldade.MEDIO, seed)
		assert_gt(resultado["complexidade"], 0, "Seed %d retornou complexidade não positiva" % seed)


func test_gerar_aceita_complexidade_dentro_da_faixa() -> void:
	var por_nivel := {
		DifficultyManager.Dificuldade.MUITO_FACIL: [1, 2, 3],
		DifficultyManager.Dificuldade.FACIL: [1, 2, 3],
		DifficultyManager.Dificuldade.MEDIO: [1, 2, 3],
		DifficultyManager.Dificuldade.DIFICIL: [1, 2, 3],
		DifficultyManager.Dificuldade.ESPECIALISTA: [1, 2, 3, 42, 2024],
	}
	for dificuldade in por_nivel.keys():
		for seed in por_nivel[dificuldade]:
			var resultado := SudokuGenerator.gerar(dificuldade, seed)
			assert_true(
				DifficultyManager.complexidade_na_faixa(dificuldade, resultado["complexidade"]),
				"Nível %d com seed %d saiu da faixa: %d" % [dificuldade, seed, resultado["complexidade"]]
			)


func test_mesma_seed_gera_mesma_complexidade() -> void:
	var a: Dictionary = SudokuGenerator.gerar(DifficultyManager.Dificuldade.ESPECIALISTA, 2024)
	var b: Dictionary = SudokuGenerator.gerar(DifficultyManager.Dificuldade.ESPECIALISTA, 2024)
	assert_eq(a["complexidade"], b["complexidade"])


func test_complexidade_de_uma_geracao_e_reproduzivel() -> void:
	assert_eq(
		SudokuGenerator.complexidade_de_uma_geracao(DifficultyManager.Dificuldade.FACIL, 123),
		SudokuGenerator.complexidade_de_uma_geracao(DifficultyManager.Dificuldade.FACIL, 123)
	)


# --- Determinismo ---

func test_mesma_seed_gera_mesmo_puzzle() -> void:
	var a: Array = SudokuGenerator.gerar(DifficultyManager.Dificuldade.MEDIO, 4321)["tabuleiro"]
	var b: Array = SudokuGenerator.gerar(DifficultyManager.Dificuldade.MEDIO, 4321)["tabuleiro"]
	assert_eq(a, b)


func test_seeds_diferentes_geram_puzzles_diferentes() -> void:
	var a: Array = SudokuGenerator.gerar(DifficultyManager.Dificuldade.MEDIO, 1)["tabuleiro"]
	var b: Array = SudokuGenerator.gerar(DifficultyManager.Dificuldade.MEDIO, 2)["tabuleiro"]
	assert_ne(a, b)
