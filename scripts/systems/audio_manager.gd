extends Node
## Efeitos sonoros procedurais (SFX), sem assets externos.
##
## Autoload: sintetiza os streams uma única vez e os toca conforme os eventos
## do jogo. Respeita `GameSettings.som_ativado` e ignora o modo headless
## (para permitir testes determinísticos sem dispositivo de áudio).

enum Tipo {
	NENHUM = 0,
	SELECIONAR = 1,
	INSERIR = 2,
	APAGAR = 3,
	ERRO = 4,
	DICA = 5,
	DESFAZER = 6,
	REFAZER = 7,
	VITORIA = 8,
	DERROTA = 9,
}

enum Forma {
	SENO = 0,
	QUADRADA = 1,
	SERRADA = 2,
}

const MIX_RATE: int = 22050

var ultimo_efeito: Tipo = Tipo.NENHUM
var reproduziu: bool = false

var _player: AudioStreamPlayer
var _streams: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

	_streams[Tipo.SELECIONAR] = _gerar_stream(Forma.QUADRADA, 1400.0, 1400.0, 0.04, 0.25)
	_streams[Tipo.INSERIR] = _gerar_stream(Forma.SENO, 660.0, 660.0, 0.09, 0.5)
	_streams[Tipo.APAGAR] = _gerar_stream(Forma.SENO, 440.0, 330.0, 0.1, 0.4)
	_streams[Tipo.ERRO] = _gerar_stream(Forma.SERRADA, 150.0, 150.0, 0.2, 0.4)
	_streams[Tipo.DICA] = _gerar_sequencia([
		{"frequencia": 880.0, "duracao": 0.08, "volume": 0.4},
		{"frequencia": 1320.0, "duracao": 0.1, "volume": 0.4},
	])
	_streams[Tipo.DESFAZER] = _gerar_stream(Forma.SENO, 520.0, 400.0, 0.08, 0.4)
	_streams[Tipo.REFAZER] = _gerar_stream(Forma.SENO, 400.0, 520.0, 0.08, 0.4)
	_streams[Tipo.VITORIA] = _gerar_sequencia([
		{"frequencia": 523.0, "duracao": 0.12, "volume": 0.5},
		{"frequencia": 659.0, "duracao": 0.12, "volume": 0.5},
		{"frequencia": 784.0, "duracao": 0.12, "volume": 0.5},
		{"frequencia": 1047.0, "duracao": 0.2, "volume": 0.5},
	])
	_streams[Tipo.DERROTA] = _gerar_stream(Forma.SENO, 392.0, 196.0, 0.5, 0.4)


## Registra o efeito solicitado e o reproduz quando o som está ativado e o
## dispositivo de áudio está disponível.
func tocar_efeito(tipo: Tipo) -> void:
	ultimo_efeito = tipo
	reproduziu = false
	if not GameSettings.som_ativado:
		return
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStreamWAV = _streams.get(tipo)
	if stream != null:
		_player.stream = stream
		_player.play()
		reproduziu = true


func get_stream(tipo: Tipo) -> AudioStreamWAV:
	return _streams.get(tipo)


func _gerar_stream(forma: Forma, freq_inicial: float, freq_final: float,
		duracao: float, volume: float) -> AudioStreamWAV:
	var total_amostras: int = maxi(1, int(duracao * MIX_RATE))
	var dados := PackedByteArray()
	dados.resize(total_amostras * 2)
	var fase := 0.0
	for i in total_amostras:
		var progresso := float(i) / total_amostras
		var frequencia := lerpf(freq_inicial, freq_final, progresso)
		fase += TAU * frequencia / MIX_RATE
		var valor := _forma_onda(forma, fase)
		var envelope := 1.0 - progresso
		var amostra := int(clampf(valor * envelope * volume, -1.0, 1.0) * 32767.0)
		dados.encode_s16(i * 2, amostra)
	return _montar_stream(dados)


func _gerar_sequencia(notas: Array) -> AudioStreamWAV:
	var dados := PackedByteArray()
	for nota in notas:
		var frequencia: float = nota["frequencia"]
		var duracao: float = nota["duracao"]
		var volume: float = nota.get("volume", 0.5)
		var n: int = maxi(1, int(duracao * MIX_RATE))
		var buffer := PackedByteArray()
		buffer.resize(n * 2)
		var fase := 0.0
		var incremento := TAU * frequencia / MIX_RATE
		for i in n:
			fase += incremento
			var envelope := 1.0 - float(i) / n
			var amostra := int(clampf(sin(fase) * envelope * volume, -1.0, 1.0) * 32767.0)
			buffer.encode_s16(i * 2, amostra)
		dados.append_array(buffer)
	return _montar_stream(dados)


func _forma_onda(forma: Forma, fase: float) -> float:
	match forma:
		Forma.QUADRADA:
			return 1.0 if sin(fase) >= 0.0 else -1.0
		Forma.SERRADA:
			return 2.0 * ((fase / TAU) - floor(fase / TAU + 0.5))
		_:
			return sin(fase)


func _montar_stream(dados: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = dados
	return stream
