extends GutTest
## Testes do cronômetro.

func test_iniciar_zerado_e_rodando() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	assert_eq(timer.get_segundos(), 0)
	assert_true(timer.esta_rodando())


func test_acumula_tempo() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	timer.atualizar(1.5)
	timer.atualizar(1.5)
	assert_eq(timer.get_segundos(), 3)


func test_pausar_interrompe_acumulo() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	timer.atualizar(2.0)
	timer.pausar()
	assert_false(timer.esta_rodando())
	timer.atualizar(5.0)
	assert_eq(timer.get_segundos(), 2)


func test_retomar_continua_acumulo() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	timer.atualizar(2.0)
	timer.pausar()
	timer.atualizar(5.0)
	assert_eq(timer.get_segundos(), 2)
	timer.retomar()
	assert_true(timer.esta_rodando())
	timer.atualizar(3.0)
	assert_eq(timer.get_segundos(), 5)


func test_parar_congela_tempo() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	timer.atualizar(4.0)
	timer.parar()
	assert_false(timer.esta_rodando())
	timer.atualizar(10.0)
	assert_eq(timer.get_segundos(), 4)


func test_emite_sinal_ao_mudar_segundo() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	watch_signals(timer)
	timer.atualizar(0.5)
	timer.atualizar(0.6)
	assert_signal_emitted_with_parameters(timer, "tempo_alterado", [1])
