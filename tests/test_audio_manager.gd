extends GutTest
## Testes do gerenciador de efeitos sonoros procedurais (AudioManager).

const TIPOS := [
	AudioManager.Tipo.SELECIONAR,
	AudioManager.Tipo.INSERIR,
	AudioManager.Tipo.APAGAR,
	AudioManager.Tipo.ERRO,
	AudioManager.Tipo.DICA,
	AudioManager.Tipo.DESFAZER,
	AudioManager.Tipo.REFAZER,
	AudioManager.Tipo.VITORIA,
	AudioManager.Tipo.DERROTA,
]


func before_each() -> void:
	AudioManager.ultimo_efeito = AudioManager.Tipo.NENHUM
	AudioManager.reproduziu = false
	GameSettings.definir_som(true)


func test_streams_gerados_para_todos_os_efeitos() -> void:
	for tipo in TIPOS:
		var stream := AudioManager.get_stream(tipo)
		assert_not_null(stream, "Stream ausente para o tipo %d" % tipo)
		assert_gt(stream.data.size(), 0, "Stream vazio para o tipo %d" % tipo)


func test_tocar_efeito_registra_ultimo() -> void:
	AudioManager.tocar_efeito(AudioManager.Tipo.INSERIR)
	assert_eq(AudioManager.ultimo_efeito, AudioManager.Tipo.INSERIR)


func test_som_desativado_nao_reproduz() -> void:
	GameSettings.definir_som(false)
	AudioManager.tocar_efeito(AudioManager.Tipo.ERRO)
	assert_eq(AudioManager.ultimo_efeito, AudioManager.Tipo.ERRO)
	assert_false(AudioManager.reproduziu)


func test_som_reativado_volta_a_registrar() -> void:
	GameSettings.definir_som(false)
	AudioManager.tocar_efeito(AudioManager.Tipo.ERRO)
	GameSettings.definir_som(true)
	AudioManager.tocar_efeito(AudioManager.Tipo.VITORIA)
	assert_eq(AudioManager.ultimo_efeito, AudioManager.Tipo.VITORIA)
