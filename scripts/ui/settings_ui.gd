extends Control
## Tela de configurações (apresentação apenas).
##
## Cada alternância altera o GameSettings e persiste. A navegação é feita
## pelo callable `navegador`, injetável para testes.

signal configuracoes_salvas

const CENA_MENU := "res://scenes/main_menu/main_menu.tscn"

var navegador: Callable = _navegar_padrao


func _ready() -> void:
	_carregar_valores()
	%BtnVidas.toggled.connect(_ao_vidas)
	%BtnSom.toggled.connect(_ao_som)
	%BtnMusica.toggled.connect(_ao_musica)
	%BtnAnotacoes.toggled.connect(_ao_anotacoes)
	%BtnErros.toggled.connect(_ao_erros)
	%BtnPadroes.pressed.connect(_ao_padroes)
	%BtnVoltar.pressed.connect(_ao_voltar)


func _carregar_valores() -> void:
	%BtnVidas.button_pressed = GameSettings.vidas_ativadas
	%BtnSom.button_pressed = GameSettings.som_ativado
	%BtnMusica.button_pressed = GameSettings.musica_ativada
	%BtnAnotacoes.button_pressed = GameSettings.anotacoes_ativadas
	%BtnErros.button_pressed = GameSettings.exibir_erros


func _ao_vidas(ativadas: bool) -> void:
	GameSettings.definir_vidas(ativadas)
	configuracoes_salvas.emit()
	GameSettings.salvar()


func _ao_som(ativado: bool) -> void:
	GameSettings.definir_som(ativado)
	configuracoes_salvas.emit()
	GameSettings.salvar()


func _ao_musica(ativada: bool) -> void:
	GameSettings.definir_musica(ativada)
	configuracoes_salvas.emit()
	GameSettings.salvar()


func _ao_anotacoes(ativadas: bool) -> void:
	GameSettings.definir_anotacoes(ativadas)
	configuracoes_salvas.emit()
	GameSettings.salvar()


func _ao_erros(ativado: bool) -> void:
	GameSettings.definir_exibir_erros(ativado)
	configuracoes_salvas.emit()
	GameSettings.salvar()


func _ao_padroes() -> void:
	GameSettings.restaurar_padroes()
	GameSettings.salvar()
	_carregar_valores()
	configuracoes_salvas.emit()


func _ao_voltar() -> void:
	navegador.call(CENA_MENU)


func _navegar_padrao(rota: String) -> void:
	var erro := get_tree().change_scene_to_file(rota)
	if erro != OK:
		push_error("Falha ao abrir a cena %s (erro %s)." % [rota, erro])
