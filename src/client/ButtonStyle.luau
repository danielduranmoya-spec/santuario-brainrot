--!strict
-- Aplica a un botón uno de los tres estilos de Config/UiStyle ("Caramelo", "Pegatina" o "Neon").
-- Uso: ButtonStyle.text(boton, "Ahora", color) para botones de texto, y ButtonStyle.setColor(boton,
-- color) para cambiarle el color después (por ejemplo, gris cuando no te llega el dinero): cada
-- estilo pone el color donde le toca (fondo, o borde y letras en el neón).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiStyle = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("UiStyle"))

export type Style = UiStyle.Style

local ButtonStyle = {}

local NEON_BACKGROUND = Color3.fromRGB(18, 16, 30)
local OUTLINE_DARK = Color3.fromRGB(20, 20, 30)

local function child<T>(button: Instance, className: string, name: string): T
	local existing = button:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing :: any
	end
	local created = Instance.new(className :: any)
	created.Name = name
	created.Parent = button
	return created :: any
end

-- Mezcla un color con blanco (amount 0-1): para letras de neón más claras que el borde.
local function lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

function ButtonStyle.styleOf(button: GuiObject): Style
	return (button:GetAttribute("EstiloBoton") :: Style?) or UiStyle.default
end

function ButtonStyle.font(style: Style): Enum.Font
	return UiStyle.Fonts[style]
end

-- Pone el color principal del botón según su estilo.
function ButtonStyle.setColor(button: GuiObject, color: Color3)
	local style = ButtonStyle.styleOf(button)
	button:SetAttribute("ColorBoton", color)
	local stroke = button:FindFirstChild("Contorno")
	if style == "Neon" then
		button.BackgroundColor3 = NEON_BACKGROUND
		if stroke and stroke:IsA("UIStroke") then
			stroke.Color = color
		end
		if button:IsA("TextButton") then
			button.TextColor3 = lighten(color, 0.35)
		end
		local glow = button:FindFirstChild("Brillo")
		if glow and glow:IsA("Frame") then
			glow.BackgroundColor3 = color
		end
	else
		button.BackgroundColor3 = color
	end
end

-- Estilo para un botón de texto. `key` es su nombre en Config/UiStyle.Buttons.
function ButtonStyle.text(button: TextButton, key: string, color: Color3)
	local style = UiStyle.styleFor(key)
	button:SetAttribute("EstiloBoton", style)
	button.Font = UiStyle.Fonts[style]
	button.AutoButtonColor = true

	local corner = child(button, "UICorner", "Esquinas") :: UICorner
	local stroke = child(button, "UIStroke", "Contorno") :: UIStroke
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local textStroke = child(button, "UIStroke", "ContornoTexto") :: UIStroke
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	if style == "Caramelo" then
		corner.CornerRadius = UDim.new(0.3, 0)
		stroke.Thickness = 3
		stroke.Color = OUTLINE_DARK
		stroke.Transparency = 0
		textStroke.Thickness = 1.5
		textStroke.Color = OUTLINE_DARK
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundTransparency = 0
		local gradient = child(button, "UIGradient", "Degradado") :: UIGradient
		-- El degradado multiplica el color de fondo: arriba tal cual y abajo más oscuro.
		gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))
		gradient.Rotation = 90
	elseif style == "Pegatina" then
		corner.CornerRadius = UDim.new(0.45, 0)
		stroke.Thickness = 4
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0
		textStroke.Thickness = 2
		textStroke.Color = OUTLINE_DARK
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundTransparency = 0
		button.Rotation = -2
	else -- Neon
		corner.CornerRadius = UDim.new(0.2, 0)
		stroke.Thickness = 3
		stroke.Transparency = 0
		textStroke.Thickness = 1
		textStroke.Color = Color3.fromRGB(0, 0, 0)
		textStroke.Transparency = 0.4
		button.BackgroundTransparency = 0.2
		-- Brillo: una franja fina de color en la parte de abajo, como un tubo de neón.
		local glow = child(button, "Frame", "Brillo") :: Frame
		glow.AnchorPoint = Vector2.new(0.5, 1)
		glow.Position = UDim2.fromScale(0.5, 0.96)
		glow.Size = UDim2.fromScale(0.7, 0.06)
		glow.BorderSizePixel = 0
		glow.BackgroundTransparency = 0.2
		local glowCorner = child(glow, "UICorner", "Esquinas") :: UICorner
		glowCorner.CornerRadius = UDim.new(1, 0)
	end
	ButtonStyle.setColor(button, color)
end

return ButtonStyle
