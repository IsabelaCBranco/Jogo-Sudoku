extends GutTest
## Testes do gerenciador de dificuldades (DifficultyManager).

func test_pegar_faixa_de_cada_dificuldade() -> void:
	assert_eq(DifficultyManager.pegar_faixa(DifficultyManager.Dificuldade.MUITO_FACIL), Vector2i(45, 50))
	assert_eq(DifficultyManager.pegar_faixa(DifficultyManager.Dificuldade.FACIL), Vector2i(36, 44))
	assert_eq(DifficultyManager.pegar_faixa(DifficultyManager.Dificuldade.MEDIO), Vector2i(32, 35))
	assert_eq(DifficultyManager.pegar_faixa(DifficultyManager.Dificuldade.DIFICIL), Vector2i(28, 31))
	assert_eq(DifficultyManager.pegar_faixa(DifficultyManager.Dificuldade.ESPECIALISTA), Vector2i(22, 27))


func test_pegar_faixa_invalida_usa_padrao() -> void:
	var padrao := DifficultyManager.pegar_faixa(DifficultyManager.Dificuldade.MEDIO)
	assert_eq(DifficultyManager.pegar_faixa(99), padrao)


func test_pegar_faixa_complexidade_de_cada_dificuldade() -> void:
	assert_eq(DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.MUITO_FACIL), Vector2i(0, 40))
	assert_eq(DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.FACIL), Vector2i(30, 70))
	assert_eq(DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.MEDIO), Vector2i(45, 100))
	assert_eq(DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.DIFICIL), Vector2i(50, 220))
	assert_eq(DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.ESPECIALISTA), Vector2i(120, 999999))


func test_pegar_faixa_complexidade_invalida_usa_padrao() -> void:
	var padrao := DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.MEDIO)
	assert_eq(DifficultyManager.pegar_faixa_complexidade(99), padrao)


func test_complexidade_na_faixa_respeita_limites() -> void:
	var faixa := DifficultyManager.pegar_faixa_complexidade(DifficultyManager.Dificuldade.MEDIO)
	assert_false(DifficultyManager.complexidade_na_faixa(DifficultyManager.Dificuldade.MEDIO, faixa.x - 1))
	assert_true(DifficultyManager.complexidade_na_faixa(DifficultyManager.Dificuldade.MEDIO, faixa.x))
	assert_true(DifficultyManager.complexidade_na_faixa(DifficultyManager.Dificuldade.MEDIO, faixa.y))
	assert_false(DifficultyManager.complexidade_na_faixa(DifficultyManager.Dificuldade.MEDIO, faixa.y + 1))


func test_faixas_de_complexidade_sao_crescentes() -> void:
	var centro_anterior: float = 0.0
	for dificuldade in [DifficultyManager.Dificuldade.MUITO_FACIL, DifficultyManager.Dificuldade.FACIL,
			DifficultyManager.Dificuldade.MEDIO, DifficultyManager.Dificuldade.DIFICIL,
			DifficultyManager.Dificuldade.ESPECIALISTA]:
		var faixa := DifficultyManager.pegar_faixa_complexidade(dificuldade)
		var centro: float = (faixa.x + faixa.y) / 2.0
		assert_gt(centro, centro_anterior, "Nível %d deve ser mais complexo que o anterior" % dificuldade)
		centro_anterior = centro


func test_selecionar_preenchidas_dentro_da_faixa() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for dificuldade in [DifficultyManager.Dificuldade.MUITO_FACIL, DifficultyManager.Dificuldade.FACIL,
			DifficultyManager.Dificuldade.MEDIO, DifficultyManager.Dificuldade.DIFICIL,
			DifficultyManager.Dificuldade.ESPECIALISTA]:
		var faixa := DifficultyManager.pegar_faixa(dificuldade)
		for i in 50:
			var escolhido: int = DifficultyManager.selecionar_preenchidas(dificuldade, rng)
			assert_gte(escolhido, faixa.x)
			assert_lte(escolhido, faixa.y)


func test_classificacao_dos_limites() -> void:
	assert_eq(DifficultyManager.classificar(45), DifficultyManager.Dificuldade.MUITO_FACIL)
	assert_eq(DifficultyManager.classificar(50), DifficultyManager.Dificuldade.MUITO_FACIL)
	assert_eq(DifficultyManager.classificar(44), DifficultyManager.Dificuldade.FACIL)
	assert_eq(DifficultyManager.classificar(36), DifficultyManager.Dificuldade.FACIL)
	assert_eq(DifficultyManager.classificar(35), DifficultyManager.Dificuldade.MEDIO)
	assert_eq(DifficultyManager.classificar(32), DifficultyManager.Dificuldade.MEDIO)
	assert_eq(DifficultyManager.classificar(31), DifficultyManager.Dificuldade.DIFICIL)
	assert_eq(DifficultyManager.classificar(28), DifficultyManager.Dificuldade.DIFICIL)
	assert_eq(DifficultyManager.classificar(27), DifficultyManager.Dificuldade.ESPECIALISTA)
	assert_eq(DifficultyManager.classificar(22), DifficultyManager.Dificuldade.ESPECIALISTA)


func test_classificacao_fora_das_faixas() -> void:
	assert_eq(DifficultyManager.classificar(51), DifficultyManager.Dificuldade.MUITO_FACIL)
	assert_eq(DifficultyManager.classificar(21), DifficultyManager.Dificuldade.ESPECIALISTA)


func test_seed_reproduz_escolha() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 4242
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 4242
	assert_eq(
		DifficultyManager.selecionar_preenchidas(DifficultyManager.Dificuldade.MEDIO, rng_a),
		DifficultyManager.selecionar_preenchidas(DifficultyManager.Dificuldade.MEDIO, rng_b)
	)


func test_nomes() -> void:
	assert_eq(DifficultyManager.get_nome(DifficultyManager.Dificuldade.MUITO_FACIL), "Muito Fácil")
	assert_eq(DifficultyManager.get_nome(DifficultyManager.Dificuldade.FACIL), "Fácil")
	assert_eq(DifficultyManager.get_nome(DifficultyManager.Dificuldade.MEDIO), "Médio")
	assert_eq(DifficultyManager.get_nome(DifficultyManager.Dificuldade.DIFICIL), "Difícil")
	assert_eq(DifficultyManager.get_nome(DifficultyManager.Dificuldade.ESPECIALISTA), "Especialista")
