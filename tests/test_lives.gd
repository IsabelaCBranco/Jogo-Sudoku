extends GutTest
## Testes do sistema de vidas.

func test_comeca_com_3_vidas() -> void:
	var lives := LivesSystem.new()
	lives.iniciar()
	assert_eq(lives.get_vidas(), 3)


func test_perder_vida_remove_uma_e_emite_sinal() -> void:
	var lives := LivesSystem.new()
	lives.iniciar()
	watch_signals(lives)
	assert_true(lives.perder_vida())
	assert_eq(lives.get_vidas(), 2)
	assert_signal_emitted_with_parameters(lives, "vidas_alteradas", [2])


func test_acerto_nao_remove_vida() -> void:
	var lives := LivesSystem.new()
	lives.iniciar()
	assert_eq(lives.get_vidas(), 3)
	assert_eq(lives.get_vidas(), 3)


func test_derrota_ao_chegar_a_zero() -> void:
	var lives := LivesSystem.new()
	lives.iniciar()
	watch_signals(lives)
	lives.perder_vida()
	lives.perder_vida()
	lives.perder_vida()
	assert_eq(lives.get_vidas(), 0)
	assert_signal_emit_count(lives, "vidas_zeradas", 1)
	assert_false(lives.perder_vida())
	assert_eq(lives.get_vidas(), 0)


func test_sistema_desativado_nao_desconta() -> void:
	var lives := LivesSystem.new()
	lives.iniciar(false)
	assert_false(lives.perder_vida())
	assert_eq(lives.get_vidas(), 3)


func test_reiniciar_restaura_vidas() -> void:
	var lives := LivesSystem.new()
	lives.iniciar()
	lives.perder_vida()
	lives.perder_vida()
	assert_eq(lives.get_vidas(), 1)
	lives.reiniciar()
	assert_eq(lives.get_vidas(), 3)
