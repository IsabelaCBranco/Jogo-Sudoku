extends GutTest
## Testes do sistema de pontuação.

func test_dificuldade_maior_gera_base_maior() -> void:
	var facil := ScoreSystem.new()
	facil.iniciar(DifficultyManager.Dificuldade.FACIL)
	var muito_facil := ScoreSystem.new()
	muito_facil.iniciar(DifficultyManager.Dificuldade.MUITO_FACIL)
	assert_gt(facil.get_pontuacao(), muito_facil.get_pontuacao())


func test_erro_aplica_penalidade() -> void:
	var score := ScoreSystem.new()
	score.iniciar(DifficultyManager.Dificuldade.FACIL)
	var base := score.get_pontuacao()
	score.registrar_erro()
	assert_eq(score.get_pontuacao(), base - score.PENALIDADE_ERRO)


func test_dica_aplica_penalidade_por_nivel() -> void:
	var score := ScoreSystem.new()
	score.iniciar(DifficultyManager.Dificuldade.FACIL)
	var base := score.get_pontuacao()
	score.registrar_dica(HintSystem.DICA_DESTACAR)
	assert_eq(score.get_pontuacao(), base - score.PENALIDADES_DICA[HintSystem.DICA_DESTACAR])
	score.registrar_dica(HintSystem.DICA_CANDIDATO)
	assert_eq(score.get_pontuacao(), base - score.PENALIDADES_DICA[HintSystem.DICA_DESTACAR] - score.PENALIDADES_DICA[HintSystem.DICA_CANDIDATO])
	score.registrar_dica(HintSystem.DICA_RESOLVER)
	assert_eq(score.get_pontuacao(), base - score.PENALIDADES_DICA[HintSystem.DICA_DESTACAR] - score.PENALIDADES_DICA[HintSystem.DICA_CANDIDATO] - score.PENALIDADES_DICA[HintSystem.DICA_RESOLVER])


func test_tempo_influencia_pontuacao() -> void:
	var score := ScoreSystem.new()
	score.iniciar(DifficultyManager.Dificuldade.FACIL)
	var base := score.get_pontuacao()
	score.atualizar_tempo(60)
	assert_eq(score.get_pontuacao(), base - 60 * score.PENALIDADE_POR_SEGUNDO)


func test_pontuacao_minima_zero() -> void:
	var score := ScoreSystem.new()
	score.iniciar(DifficultyManager.Dificuldade.MUITO_FACIL)
	for i in 100:
		score.registrar_erro()
	assert_eq(score.get_pontuacao(), 0)


func test_vidas_restantes_bonus_no_final() -> void:
	var score := ScoreSystem.new()
	score.iniciar(DifficultyManager.Dificuldade.FACIL)
	var pontos_muitas_vidas := score.calcular_final(3)
	var pontos_zero_vidas := score.calcular_final(0)
	assert_gt(pontos_muitas_vidas, pontos_zero_vidas)


func test_reiniciar_restaura_base() -> void:
	var score := ScoreSystem.new()
	score.iniciar(DifficultyManager.Dificuldade.FACIL)
	score.registrar_erro()
	score.reiniciar()
	assert_eq(score.get_pontuacao(), 1000 * DifficultyManager.Dificuldade.FACIL)
	assert_eq(score.get_erros(), 0)
