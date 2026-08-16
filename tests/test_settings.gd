extends GutTest
## Testes das configurações globais (GameSettings autoload).


func before_each() -> void:
	GameSettings.restaurar_padroes()
	var dir := OS.get_environment("TEMP") + "/gut_settings_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)


func after_each() -> void:
	SaveManager.set_caminho_base("user://")


func test_valores_padrao() -> void:
	assert_true(GameSettings.vidas_ativadas)
	assert_true(GameSettings.som_ativado)
	assert_true(GameSettings.musica_ativada)
	assert_true(GameSettings.anotacoes_ativadas)
	assert_true(GameSettings.exibir_erros)


func test_alterar_configuracao_emite_sinal() -> void:
	watch_signals(GameSettings)
	GameSettings.definir_som(false)
	assert_false(GameSettings.som_ativado)
	assert_signal_emitted(GameSettings, "configuracoes_alteradas")


func test_alteracoes_afetam_cada_opcao() -> void:
	GameSettings.definir_vidas(false)
	GameSettings.definir_musica(false)
	GameSettings.definir_anotacoes(false)
	GameSettings.definir_exibir_erros(false)
	assert_false(GameSettings.vidas_ativadas)
	assert_false(GameSettings.musica_ativada)
	assert_false(GameSettings.anotacoes_ativadas)
	assert_false(GameSettings.exibir_erros)


func test_round_trip_persistencia() -> void:
	GameSettings.definir_vidas(false)
	GameSettings.definir_som(false)
	GameSettings.definir_musica(false)
	GameSettings.definir_anotacoes(false)
	GameSettings.definir_exibir_erros(false)
	GameSettings.salvar()

	GameSettings.restaurar_padroes()
	GameSettings.carregar()
	assert_false(GameSettings.vidas_ativadas)
	assert_false(GameSettings.som_ativado)
	assert_false(GameSettings.musica_ativada)
	assert_false(GameSettings.anotacoes_ativadas)
	assert_false(GameSettings.exibir_erros)


func test_carregar_sem_arquivo_mantem_estado() -> void:
	GameSettings.definir_som(false)
	GameSettings.carregar()
	assert_false(GameSettings.som_ativado)
