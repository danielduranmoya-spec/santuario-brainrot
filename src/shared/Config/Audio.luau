--!strict
-- Música y efectos de sonido. Todos son audios gratuitos y públicos del Creator Store de Roblox:
--   * "Roblox" = subidos por la cuenta oficial de Roblox (licencia para cualquier experiencia).
--   * APMOfficial, ProSoundEffects, DistrokidOfficial = socios de audio de Roblox (de uso libre en Roblox).
-- Para cambiar uno: busca en el Creator Store (pestaña Audio), copia su ID y ponlo aquí.
-- Volúmenes moderados (0-1); la música va baja para no cansar.

export type Sound = { id: number, volume: number, note: string }

local Audio = {}

-- Música clásica (las obras son de dominio público y estas grabaciones son de la biblioteca de
-- audio de Roblox, de socios con licencia para cualquier experiencia). Una de día y otra de noche;
-- el cliente hace un fundido al cambiar (Config/Events.DayNight.musicFadeSeconds).
Audio.Music = {
	-- Día: alegre y ligera. Alternativa: 1843596713 (Mozart, Eine kleine Nachtmusik III. Menuetto, APMOfficial, 2:03)
	dia = {
		id = 1837488380,
		volume = 0.22,
		note = "Mozart · Eine kleine Nachtmusik KV 525, IV. Rondo: Allegro · APMOfficial · 2:48",
	},
	-- Noche: tranquila, piano. Alternativa: 1838457617 (Debussy, Clair de lune, APMOfficial, 4:22)
	noche = {
		id = 9045766377,
		volume = 0.28,
		note = "Satie · Gymnopédie n.º 1 (piano) · APMOfficial · 2:32",
	},
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
	-- Aviso de que quedan 10 s para la noche. Alternativa: 9113421646 (Bell Rings 1, ProSoundEffects)
	alerta_noche = { id = 9116395089, volume = 0.6, note = "Magic Glows Soft Clusters Of Chiming Hits 4 · ProSoundEffects" },
	-- Fiesta al capturar (suena junto con captura_ok). Remate corto de premio.
	confeti = { id = 9040476898, volume = 0.35, note = "Early Bird - Hit1 · APMOfficial" },
}

Audio.coinSoundMinGapSeconds = 0.35 -- evita que el tintineo suene en ráfaga al cobrar seguido

return Audio
