extends GutTest
## Testes das estatísticas agregadas (StatisticsSystem autoload).


func before_each() -> void:
	StatisticsSystem.reset()
	var dir := OS.get_environment("TEMP") + "/gut_stats_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)


func after_each() -> void:
	StatisticsSystem.reset()
	SaveManager.set_caminho_base("user://")


func test_partida_iniciada_incrementa() -> void:
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_partida_iniciada()
	assert_eq(StatisticsSystem.partidas_iniciadas, 2)


func test_vitoria_registra_dados_e_melhores() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 2500, 2, 1)
	assert_eq(StatisticsSystem.partidas_concluidas, 1)
	assert_eq(StatisticsSystem.partidas_vencidas, 1)
	assert_eq(StatisticsSystem.erros_total, 2)
	assert_eq(StatisticsSystem.dicas_total, 1)
	assert_eq(StatisticsSystem.get_melhor_tempo(DifficultyManager.Dificuldade.FACIL), 300)
	assert_eq(StatisticsSystem.get_melhor_pontuacao(DifficultyManager.Dificuldade.FACIL), 2500)


func test_melhor_tempo_atualizado_quando_menor() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 2500, 0, 0)
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 200, 2400, 0, 0)
	assert_eq(StatisticsSystem.get_melhor_tempo(DifficultyManager.Dificuldade.FACIL), 200)
	assert_eq(StatisticsSystem.get_melhor_pontuacao(DifficultyManager.Dificuldade.FACIL), 2500)


func test_melhores_por_dificuldade_sao_separados() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 2500, 0, 0)
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.DIFICIL, 500, 3000, 0, 0)
	assert_eq(StatisticsSystem.get_melhor_tempo(DifficultyManager.Dificuldade.FACIL), 300)
	assert_eq(StatisticsSystem.get_melhor_tempo(DifficultyManager.Dificuldade.DIFICIL), 500)


func test_derrota_incrementa() -> void:
	StatisticsSystem.registrar_derrota(DifficultyManager.Dificuldade.MEDIO, 3, 0)
	assert_eq(StatisticsSystem.partidas_concluidas, 1)
	assert_eq(StatisticsSystem.partidas_perdidas, 1)
	assert_eq(StatisticsSystem.erros_total, 3)


func test_medias_sobre_partidas_concluidas() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 1000, 2, 1)
	StatisticsSystem.registrar_derrota(DifficultyManager.Dificuldade.FACIL, 4, 0)
	assert_eq(StatisticsSystem.get_tempo_medio(), 150.0)
	assert_eq(StatisticsSystem.get_media_erros(), 3.0)


func test_media_zero_sem_partidas() -> void:
	assert_eq(StatisticsSystem.get_tempo_medio(), 0.0)
	assert_eq(StatisticsSystem.get_media_erros(), 0.0)


func test_round_trip_persistencia() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 2500, 2, 1)
	StatisticsSystem.registrar_derrota(DifficultyManager.Dificuldade.FACIL, 3, 0)
	StatisticsSystem.salvar()

	StatisticsSystem.reset()
	StatisticsSystem.carregar()
	assert_eq(StatisticsSystem.partidas_iniciadas, 0)
	assert_eq(StatisticsSystem.partidas_concluidas, 2)
	assert_eq(StatisticsSystem.partidas_vencidas, 1)
	assert_eq(StatisticsSystem.partidas_perdidas, 1)
	assert_eq(StatisticsSystem.erros_total, 5)
	assert_eq(StatisticsSystem.dicas_total, 1)
	assert_eq(StatisticsSystem.get_melhor_tempo(DifficultyManager.Dificuldade.FACIL), 300)
	assert_eq(StatisticsSystem.get_melhor_pontuacao(DifficultyManager.Dificuldade.FACIL), 2500)


func test_registrar_partida_iniciada_persiste_automaticamente() -> void:
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_partida_iniciada()

	StatisticsSystem.reset()
	StatisticsSystem.carregar()
	assert_eq(StatisticsSystem.partidas_iniciadas, 2)


func test_registrar_vitoria_persiste_automaticamente() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 2500, 2, 1)

	StatisticsSystem.reset()
	StatisticsSystem.carregar()
	assert_eq(StatisticsSystem.partidas_concluidas, 1)
	assert_eq(StatisticsSystem.partidas_vencidas, 1)
	assert_eq(StatisticsSystem.erros_total, 2)
	assert_eq(StatisticsSystem.dicas_total, 1)


func test_reset_limpa_tudo() -> void:
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 300, 2500, 2, 1)
	StatisticsSystem.reset()
	assert_eq(StatisticsSystem.partidas_iniciadas, 0)
	assert_eq(StatisticsSystem.partidas_concluidas, 0)
	assert_eq(StatisticsSystem.get_melhor_tempo(DifficultyManager.Dificuldade.FACIL), 0)
