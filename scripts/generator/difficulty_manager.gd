class_name DifficultyManager
extends RefCounted
## Gerencia as dificuldades do jogo.
##
## Cada dificuldade possui uma faixa de células preenchidas, usada como
## parâmetro inicial pelo gerador. A classificação pode evoluir para incluir
## métricas de complexidade, mas a interface permanece estável.

enum Dificuldade {
	MUITO_FACIL = 1,
	FACIL = 2,
	MEDIO = 3,
	DIFICIL = 4,
	ESPECIALISTA = 5,
}

const NOMES := {
	Dificuldade.MUITO_FACIL: "Muito Fácil",
	Dificuldade.FACIL: "Fácil",
	Dificuldade.MEDIO: "Médio",
	Dificuldade.DIFICIL: "Difícil",
	Dificuldade.ESPECIALISTA: "Especialista",
}

# Faixas de células preenchidas (x = mínimo, y = máximo).
const FAIXAS := {
	Dificuldade.MUITO_FACIL: Vector2i(45, 50),
	Dificuldade.FACIL: Vector2i(36, 44),
	Dificuldade.MEDIO: Vector2i(32, 35),
	Dificuldade.DIFICIL: Vector2i(28, 31),
	Dificuldade.ESPECIALISTA: Vector2i(22, 27),
}

# Faixas de complexidade em decisões do solver (medida por `contar_decisoes`).
# Calibradas empiricamente sobre a distribuição natural de cada dificuldade;
# a geração aceita puzzles dentro da faixa e re-tenta com sub-seed quando fora.
const FAIXAS_COMPLEXIDADE := {
	Dificuldade.MUITO_FACIL: Vector2i(0, 40),
	Dificuldade.FACIL: Vector2i(30, 70),
	Dificuldade.MEDIO: Vector2i(45, 100),
	Dificuldade.DIFICIL: Vector2i(50, 220),
	Dificuldade.ESPECIALISTA: Vector2i(120, 999999),
}

# Ordem do nível mais preenchido para o menos preenchido, usada na classificação.
const _ORDEM_CLASSIFICACAO := [
	Dificuldade.MUITO_FACIL,
	Dificuldade.FACIL,
	Dificuldade.MEDIO,
	Dificuldade.DIFICIL,
	Dificuldade.ESPECIALISTA,
]


static func get_nome(dificuldade: int) -> String:
	return NOMES.get(dificuldade, "Desconhecida")


static func pegar_faixa(dificuldade: int) -> Vector2i:
	return FAIXAS.get(dificuldade, FAIXAS[Dificuldade.MEDIO])


static func pegar_faixa_complexidade(dificuldade: int) -> Vector2i:
	return FAIXAS_COMPLEXIDADE.get(dificuldade, FAIXAS_COMPLEXIDADE[Dificuldade.MEDIO])


static func complexidade_na_faixa(dificuldade: int, complexidade: int) -> bool:
	var faixa := pegar_faixa_complexidade(dificuldade)
	return complexidade >= faixa.x and complexidade <= faixa.y


## Escolhe uma quantidade de células preenchidas dentro da faixa da dificuldade.
static func selecionar_preenchidas(dificuldade: int, rng: RandomNumberGenerator) -> int:
	var faixa := pegar_faixa(dificuldade)
	return rng.randi_range(faixa.x, faixa.y)


## Classifica uma quantidade de células preenchidas em uma dificuldade.
static func classificar(qtd_preenchidas: int) -> int:
	for dificuldade in _ORDEM_CLASSIFICACAO:
		var faixa := pegar_faixa(dificuldade)
		if qtd_preenchidas >= faixa.x:
			return dificuldade
	return Dificuldade.ESPECIALISTA
