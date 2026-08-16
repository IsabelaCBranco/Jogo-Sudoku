extends GutTest
## Testes do progresso persistente de dicas (HintProgression).

var _dir: String = ""


func before_each() -> void:
	_dir = OS.get_environment("TEMP") + "/gut_dicas_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(_dir)
	SaveManager.set_caminho_base(_dir)
	HintProgression.reset()


func after_each() -> void:
	SaveManager.set_caminho_base("user://")


func test_estoque_inicial_vazio() -> void:
	assert_eq(HintProgression.get_total(), 0)
	assert_false(HintProgression.pode_usar(HintSystem.DICA_DESTACAR))
	assert_false(HintProgression.pode_usar(HintSystem.DICA_CANDIDATO))
	assert_false(HintProgression.pode_usar(HintSystem.DICA_RESOLVER))


func test_vitoria_muito_facil_nao_concede() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.MUITO_FACIL)
	assert_eq(HintProgression.get_total(), 0)


func test_vitoria_facil_concede_sinalizar() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.FACIL)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_DESTACAR), 1)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_CANDIDATO), 0)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_RESOLVER), 0)


func test_vitoria_medio_concede_revelar() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.MEDIO)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_CANDIDATO), 1)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_DESTACAR), 0)


func test_vitoria_dificil_concede_preencher() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.DIFICIL)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_RESOLVER), 1)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_CANDIDATO), 0)


func test_vitoria_especialista_concede_uma_de_cada() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.ESPECIALISTA)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_DESTACAR), 1)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_CANDIDATO), 1)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_RESOLVER), 1)
	assert_eq(HintProgression.get_total(), 3)


func test_vitorias_acumulam_entre_partidas() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.FACIL)
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.FACIL)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_DESTACAR), 2)

	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.MEDIO)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_DESTACAR), 2)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_CANDIDATO), 1)


func test_consumo_decrementa_estoque() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.ESPECIALISTA)
	assert_true(HintProgression.consumir(HintSystem.DICA_RESOLVER))
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_RESOLVER), 0)
	assert_eq(HintProgression.get_total(), 2)


func test_consumo_sem_estoque_bloqueado() -> void:
	assert_false(HintProgression.consumir(HintSystem.DICA_DESTACAR))
	assert_eq(HintProgression.get_total(), 0)


func test_registrar_vitoria_emite_sinal() -> void:
	watch_signals(HintProgression)
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.FACIL)
	assert_signal_emitted(HintProgression, "dicas_alteradas")


func test_consumir_emite_sinal() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.FACIL)
	watch_signals(HintProgression)
	HintProgression.consumir(HintSystem.DICA_DESTACAR)
	assert_signal_emitted(HintProgression, "dicas_alteradas")


func test_persistencia_restaura_estoque() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.ESPECIALISTA)
	HintProgression.consumir(HintSystem.DICA_CANDIDATO)

	HintProgression.reset()
	assert_eq(HintProgression.get_total(), 0)

	HintProgression.carregar()
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_DESTACAR), 1)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_CANDIDATO), 0)
	assert_eq(HintProgression.get_disponiveis(HintSystem.DICA_RESOLVER), 1)


func test_reset_limpa_estoque() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.ESPECIALISTA)
	HintProgression.reset()
	assert_eq(HintProgression.get_total(), 0)
