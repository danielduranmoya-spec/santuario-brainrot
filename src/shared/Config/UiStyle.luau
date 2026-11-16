--!strict
-- Estilo de los botones de la interfaz. Hay tres diseños para elegir (ver design/Botones.md):
--   "Caramelo" = degradado brillante, contorno oscuro y relieve abajo (el de siempre).
--   "Pegatina" = color plano, borde blanco grueso, letra de cómic y un poco inclinado.
--   "Neon"     = fondo oscuro translúcido, borde y letras de color que brillan.
-- Puedes elegir uno para todos (default) o uno distinto para cada botón (Buttons).

export type Style = "Caramelo" | "Pegatina" | "Neon"

local UiStyle = {}

UiStyle.default = "Caramelo" :: Style

-- Deja un botón en nil para que use el estilo por defecto.
UiStyle.Buttons = {
	Mejoras = nil, -- botón lateral MEJORAS
	Tienda = nil, -- botón lateral TIENDA
	Codigos = nil, -- botón lateral CÓDIGOS
	Ahora = nil, -- ¡AHORA! (minijuego de captura)
	Soltar = nil, -- SOLTAR (cuando llevas un bicho)
	Valla = nil, -- VALLA (cuando te ponen un cebo)
	Comprar = nil, -- botones de precio dentro de MEJORAS y TIENDA
	Canjear = nil, -- CANJEAR (dentro de CÓDIGOS)
	Cerrar = nil, -- X de los paneles
} :: { [string]: Style? }

-- Letra de cada estilo.
UiStyle.Fonts = {
	Caramelo = Enum.Font.GothamBlack,
	Pegatina = Enum.Font.LuckiestGuy,
	Neon = Enum.Font.Sarpanch,
} :: { [Style]: Enum.Font }

function UiStyle.styleFor(key: string): Style
	return UiStyle.Buttons[key] or UiStyle.default
end

return UiStyle
