--!strict
-- Música y efectos de sonido. Todos son audios gratuitos y públicos del Creator Store de Roblox:
--   * "Roblox" = subidos por la cuenta oficial de Roblox (licencia para cualquier experiencia).
--   * APMOfficial, ProSoundEffects, DistrokidOfficial = socios de audio de Roblox (de uso libre en Roblox).
-- Para cambiar uno: busca en el Creator Store (pestaña Audio), copia su ID y ponlo aquí.
-- Volúmenes moderados (0-1); la música va baja para no cansar.

export type Sound = { id: number, volume: number, note: string }

local Audio = {}

Audio.Music = {
	-- Alternativas: 92416269264338 (Whispering Ukulele Island Calm, DistrokidOfficial, 177 s)
	--               138455556975112 (Happy Tropical, DistrokidOfficial, 154 s)
	ambiente = { id = 15675069601, volume = 0.25, note = "Roblox_UI_Loop_Calm_Music · Roblox · bucle de 95 s" },
}

Audio.Sfx = {
	captura_ok = { id = 15675055424, volume = 0.6, note = "Roblox_UI_Cute_Pop · Roblox" },
	captura_fallo = { id = 15675062723, volume = 0.5, note = "Roblox_UI_Whistle_Low · Roblox" },
	barra_inicio = { id = 15674975792, volume = 0.4, note = "Roblox_UI_Whoosh_03 · Roblox" },
	monedas = { id = 9113849492, volume = 0.35, note = "Coins Or Keys Jingle 6 · ProSoundEffects" },
	deposito = { id = 15675043410, volume = 0.5, note = "Roblox_UI_Tonal_Stinger · Roblox" },
	desbloqueo = { id = 1848271884, volume = 0.5, note = "Fairytown Waltz - Tag2 · APMOfficial" },
	compra = { id = 1844692556, volume = 0.45, note = "Game Show · APMOfficial" },
	recompensa = { id = 1845411858, volume = 0.45, note = "Top Prize · APMOfficial" },
	click = { id = 15675059323, volume = 0.4, note = "Roblox_UI_Bright_Click · Roblox" },
}

Audio.coinSoundMinGapSeconds = 0.35 -- evita que el tintineo suene en ráfaga al cobrar seguido

return Audio
