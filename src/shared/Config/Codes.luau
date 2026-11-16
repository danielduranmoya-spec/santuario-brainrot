--!strict
-- Códigos de recompensa. Se canjean en el botón CÓDIGOS. Cada jugador puede canjear cada código
-- una sola vez. Escríbelos en MAYÚSCULAS aquí; el jugador puede escribirlos como quiera.
--
-- Para añadir uno con cada actualización (GDD: "código de recompensa con cada actualización"):
--   NOMBRE = { coins = 500, baits = 1, luckMinutes = 0, expiresAt = <fecha UTC en segundos> },
-- expiresAt es opcional (sin él no caduca). Para calcularlo, en la barra de comandos de Studio:
--   print(os.time({ year = 2027, month = 1, day = 31, hour = 0 }))

export type Reward = {
	coins: number?,
	baits: number?,
	luckMinutes: number?, -- minutos de Suerte x2
	expiresAt: number?,
}

local Codes = {}

Codes.List = {
	BICHOS = { coins = 300, baits = 1 },
	LANZAMIENTO = { coins = 1_000, baits = 2, expiresAt = 1801353600 }, -- caduca el 31/01/2027 a las 00:00 UTC
	LLUVIA = { luckMinutes = 5 },
} :: { [string]: Reward }

Codes.maxLength = 24

return Codes
