extends GutTest
## Testes do GameSession (dados transitórios da sessão).


func before_each() -> void:
	GameSession.limpar()


func test_valores_padrao() -> void:
	assert_eq(GameSession.dificuldade_selecionada, DifficultyManager.Dificuldade.FACIL)
	assert_false(GameSession.continuar)
	assert_eq(GameSession.resultado, GameSession.Resultado.NENHUM)


func test_definir_nova_partida_atualiza_dificuldade() -> void:
	GameSession.definir_nova_partida(DifficultyManager.Dificuldade.DIFICIL)
	assert_eq(GameSession.dificuldade_selecionada, DifficultyManager.Dificuldade.DIFICIL)
	assert_false(GameSession.continuar)


func test_definir_continuar() -> void:
	GameSession.definir_continuar()
	assert_true(GameSession.continuar)


func test_registrar_vitoria_preenche_resultado() -> void:
	GameSession.registrar_vitoria(4200, 90, 2, DifficultyManager.Dificuldade.MEDIO, 1, 2)
	assert_eq(GameSession.resultado, GameSession.Resultado.VITORIA)
	assert_eq(GameSession.resultado_pontos, 4200)
	assert_eq(GameSession.resultado_tempo_segundos, 90)
	assert_eq(GameSession.resultado_vidas, 2)
	assert_eq(GameSession.resultado_dificuldade, DifficultyManager.Dificuldade.MEDIO)
	assert_eq(GameSession.resultado_erros, 1)
	assert_eq(GameSession.resultado_dicas, 2)


func test_registrar_derrota_preenche_resultado() -> void:
	GameSession.registrar_derrota(45, DifficultyManager.Dificuldade.FACIL, 3, 0)
	assert_eq(GameSession.resultado, GameSession.Resultado.DERROTA)
	assert_eq(GameSession.resultado_pontos, 0)
	assert_eq(GameSession.resultado_tempo_segundos, 45)
	assert_eq(GameSession.resultado_vidas, 0)
	assert_eq(GameSession.resultado_erros, 3)
	assert_eq(GameSession.resultado_dicas, 0)


func test_limpar_reseta_sessao() -> void:
	GameSession.registrar_vitoria(100, 10, 3, DifficultyManager.Dificuldade.FACIL, 0, 0)
	GameSession.definir_continuar()
	GameSession.limpar()
	assert_false(GameSession.continuar)
	assert_eq(GameSession.resultado, GameSession.Resultado.NENHUM)
	assert_eq(GameSession.resultado_pontos, 0)
