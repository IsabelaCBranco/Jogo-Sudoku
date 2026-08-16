extends GutTest
## Testes da persistência em arquivo (SaveManager).

var _dir_atual: String = ""


func before_each() -> void:
	_dir_atual = OS.get_environment("TEMP") + "/gut_save_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(_dir_atual)
	SaveManager.set_caminho_base(_dir_atual)


func after_each() -> void:
	SaveManager.set_caminho_base("user://")
	_remover_dir(_dir_atual)


func test_carregar_arquivo_inexistente() -> void:
	assert_true(SaveManager.carregar_configuracoes().is_empty())
	assert_true(SaveManager.carregar_estatisticas().is_empty())
	assert_true(SaveManager.carregar_dicas().is_empty())
	assert_true(SaveManager.carregar_partida().is_empty())


func test_round_trip_configuracoes() -> void:
	var dados := {
		"vidas_ativadas": false,
		"som_ativado": true,
		"musica_ativada": false,
		"anotacoes_ativadas": true,
		"exibir_erros": false,
	}
	assert_true(SaveManager.salvar_configuracoes(dados))
	assert_eq(SaveManager.carregar_configuracoes(), dados)


func test_round_trip_estatisticas() -> void:
	var dados := {
		"partidas_iniciadas": 5.0,
		"partidas_vencidas": 3.0,
		"melhores": [
			{"dificuldade": 2.0, "tempo": 300.0, "pontuacao": 2500.0},
			{"dificuldade": 4.0, "tempo": 0.0, "pontuacao": 900.0},
		],
	}
	assert_true(SaveManager.salvar_estatisticas(dados))
	assert_eq(SaveManager.carregar_estatisticas(), dados)


func test_round_trip_dicas() -> void:
	var dados := {
		"estoque": {1: 2.0, 2: 0.0, 3: 1.0},
	}
	assert_true(SaveManager.salvar_dicas(dados))
	var carregado := SaveManager.carregar_dicas()
	assert_eq(carregado["estoque"]["1"], 2.0)
	assert_eq(carregado["estoque"]["2"], 0.0)
	assert_eq(carregado["estoque"]["3"], 1.0)


func test_round_trip_partida() -> void:
	var dados := {
		"tabuleiro": [[5.0, 3.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]],
		"dificuldade": 2.0,
		"tempo": 42.0,
	}
	assert_true(SaveManager.salvar_partida(dados))
	assert_eq(SaveManager.carregar_partida(), dados)


func test_partida_salva_e_apagada() -> void:
	assert_false(SaveManager.existe_partida_salva())
	SaveManager.salvar_partida({"chave": 1})
	assert_true(SaveManager.existe_partida_salva())
	SaveManager.apagar_partida()
	assert_false(SaveManager.existe_partida_salva())


func _remover_dir(pasta: String) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	dir.list_dir_begin()
	var arquivo := dir.get_next()
	while arquivo != "":
		var caminho := pasta + arquivo
		if dir.current_is_dir():
			_remover_dir(caminho + "/")
		else:
			DirAccess.remove_absolute(caminho)
		arquivo = dir.get_next()
	dir.list_dir_end()
	dir.remove(pasta)
