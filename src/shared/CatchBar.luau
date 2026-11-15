--!strict
-- Matemáticas del minijuego de captura. Las usan el cliente (para dibujar) y el servidor
-- (para decidir si acertaste), así los dos ven exactamente la misma barra.

local CatchBar = {}

-- Posición del marcador (0 = izquierda, 1 = derecha) tras `elapsed` segundos.
-- Va y vuelve una vez cada `cycle` segundos.
function CatchBar.markerAt(elapsed: number, cycle: number): number
	local phase = (elapsed % cycle) / cycle
	if phase < 0.5 then
		return phase * 2
	end
	return 2 - phase * 2
end

function CatchBar.isInZone(position: number, zoneCenter: number, zoneWidth: number): boolean
	return math.abs(position - zoneCenter) <= zoneWidth / 2
end

return CatchBar
