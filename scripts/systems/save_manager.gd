extends Node
## Persistência do jogo em arquivos JSON (user:// por padrão).
##
## O caminho base é injetável para permitir testes determinísticos sem
## poluir os dados reais do jogador.

const ARQUIVO_CONFIGURACOES := "settings.json"
const ARQUIVO_ESTATISTICAS := "statistics.json"
const ARQUIVO_PARTIDA := "savegame.json"
const ARQUIVO_DICAS := "hints.json"

var _caminho_base: String = "user://"


func set_caminho_base(caminho: String) -> void:
	_caminho_base = caminho


func get_caminho_base() -> String:
	return _caminho_base


func salvar_configuracoes(dados: Dictionary) -> bool:
	return _salvar_json(ARQUIVO_CONFIGURACOES, dados)


func carregar_configuracoes() -> Dictionary:
	return _carregar_json(ARQUIVO_CONFIGURACOES)


func salvar_estatisticas(dados: Dictionary) -> bool:
	return _salvar_json(ARQUIVO_ESTATISTICAS, dados)


func carregar_estatisticas() -> Dictionary:
	return _carregar_json(ARQUIVO_ESTATISTICAS)


func salvar_dicas(dados: Dictionary) -> bool:
	return _salvar_json(ARQUIVO_DICAS, dados)


func carregar_dicas() -> Dictionary:
	return _carregar_json(ARQUIVO_DICAS)


func salvar_partida(dados: Dictionary) -> bool:
	return _salvar_json(ARQUIVO_PARTIDA, dados)


func carregar_partida() -> Dictionary:
	return _carregar_json(ARQUIVO_PARTIDA)


func existe_partida_salva() -> bool:
	return FileAccess.file_exists(_caminho_completo(ARQUIVO_PARTIDA))


func apagar_partida() -> void:
	if not FileAccess.file_exists(_caminho_completo(ARQUIVO_PARTIDA)):
		return
	if DirAccess.remove_absolute(_caminho_completo(ARQUIVO_PARTIDA)) != OK:
		push_warning("Não foi possível remover a partida salva.")


func _salvar_json(nome: String, dados: Dictionary) -> bool:
	var arquivo := FileAccess.open(_caminho_completo(nome), FileAccess.WRITE)
	if arquivo == null:
		push_error("Falha ao abrir %s para escrita (erro %s)." % [nome, FileAccess.get_open_error()])
		return false
	arquivo.store_string(JSON.stringify(dados))
	arquivo.close()
	return true


func _carregar_json(nome: String) -> Dictionary:
	if not FileAccess.file_exists(_caminho_completo(nome)):
		return {}
	var arquivo := FileAccess.open(_caminho_completo(nome), FileAccess.READ)
	if arquivo == null:
		return {}
	var texto := arquivo.get_as_text()
	arquivo.close()
	var dados: Variant = JSON.parse_string(texto)
	if dados is Dictionary:
		return dados
	return {}


func _caminho_completo(nome: String) -> String:
	return _caminho_base.path_join(nome)
