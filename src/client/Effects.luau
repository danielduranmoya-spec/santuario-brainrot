--!strict
-- Efectos del cliente: sonidos, música ambiente, partículas y pequeños tweens de interfaz.
-- El servidor avisa con Remotes.Effect(tipo, posición, dato); aquí solo se dibuja y suena.
-- Pensado para móvil: ráfagas cortas de partículas que se borran solas.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Audio = require(Config:WaitForChild("Audio"))
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))
local Events = require(Config:WaitForChild("Events"))
local Format = require(Shared:WaitForChild("Format"))

local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"
local CONFETTI = "rbxasset://textures/particles/SquareParticle.png"
local GOLD = Art.colors.gold

local Effects = {}

local sounds: { [string]: Sound } = {}
local lastCoinSound = 0
local effectsFolder: Folder

local function makeSound(name: string, id: number, volume: number, parent: Instance): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = volume
	sound.Parent = parent
	return sound
end

function Effects.Play(name: string)
	local sound = sounds[name]
	if not sound then
		return
	end
	if name == "monedas" then
		local now = os.clock()
		if now - lastCoinSound < Audio.coinSoundMinGapSeconds then
			return
		end
		lastCoinSound = now
	end
	SoundService:PlayLocalSound(sound)
end

-- Pieza invisible y anclada en un punto, que se borra sola, para colgar partículas.
local function anchorAt(position: Vector3, lifetime: number): BasePart
	local holder = Instance.new("Part")
	holder.Name = "Efecto"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = position
	holder.Parent = effectsFolder
	Debris:AddItem(holder, lifetime)
	return holder
end

local function burst(position: Vector3, color: Color3, count: number, speed: number, gravity: number, size: number)
	local holder = anchorAt(position, 3)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLES
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(speed * 0.6, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -gravity, 0)
	emitter.Size = NumberSequence.new(size, 0)
	emitter.Rate = 0
	emitter.Parent = holder
	emitter:Emit(count)
end

local function flash(position: Vector3, color: Color3, range: number)
	local holder = anchorAt(position, 1)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 6
	light.Parent = holder
	TweenService:Create(light, TweenInfo.new(0.6), { Brightness = 0 }):Play()
end

-- Monedas que saltan del cofre (piezas doradas con física, se borran solas).
local function coinFountain(position: Vector3, amount: number)
	local coins = math.clamp(math.ceil(math.log10(amount + 1) * 2), 1, 6)
	for _ = 1, coins do
		local coin = Instance.new("Part")
		coin.Name = "Moneda"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.15, 0.9, 0.9)
		coin.Color = GOLD
		coin.Material = Enum.Material.Neon
		coin.CanCollide = false
		coin.CanQuery = false
		coin.CanTouch = false
		coin.CastShadow = false
		coin.CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
		coin.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), math.random(18, 26), math.random(-8, 8))
		coin.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
		coin.Parent = effectsFolder
		Debris:AddItem(coin, 1.2)
	end
	-- "+N" que sube y se desvanece.
	local holder = anchorAt(position + Vector3.new(0, 3, 0), 1.3)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(6, 0, 2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = holder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = GOLD
	label.TextStrokeTransparency = 0
	label.Text = "+" .. Format.number(amount)
	label.Parent = gui
	TweenService:Create(gui, TweenInfo.new(1.2), { StudsOffsetWorldSpace = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
end

-- Destello blanco en toda la pantalla (desbloqueo de zona).
local screenFlash: Frame? = nil
local function flashScreen()
	local frame = screenFlash
	if not frame then
		return
	end
	frame.BackgroundTransparency = 0.2
	frame.Visible = true
	local tween = TweenService:Create(frame, TweenInfo.new(0.8), { BackgroundTransparency = 1 })
	tween.Completed:Connect(function()
		frame.Visible = false
	end)
	tween:Play()
end

-- Confeti de colores: papelitos cuadrados que saltan, giran y caen (un emisor por color).
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 80, 110),
	Color3.fromRGB(255, 200, 50),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(120, 230, 110),
	Color3.fromRGB(190, 120, 255),
}
local function confetti(position: Vector3, count: number)
	local holder = anchorAt(position + Vector3.new(0, 1, 0), 4)
	local perColor = math.max(1, math.floor(count / #CONFETTI_COLORS))
	for _, color in CONFETTI_COLORS do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = CONFETTI
		emitter.Color = ColorSequence.new(color)
		emitter.LightEmission = 0.3
		emitter.Lifetime = NumberRange.new(1.6, 2.6)
		emitter.Speed = NumberRange.new(16, 26)
		emitter.SpreadAngle = Vector2.new(40, 40)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.new(0, -28, 0)
		emitter.Drag = 2.5
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-400, 400)
		emitter.Size = NumberSequence.new(0.45)
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		emitter.Rate = 0
		emitter.Parent = holder
		emitter:Emit(perColor)
	end
end

-- Onda de choque: un aro del color de la rareza que se abre en el suelo y se desvanece.
local function shockwave(position: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Name = "Onda"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(position.X, position.Y - 1, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.2
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Parent = effectsFolder
	Debris:AddItem(ring, 1)
	TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.2, 22, 22), Transparency = 1 }):Play()
end

-- Columna de luz hacia el cielo (Raro o más).
local function lightColumn(position: Vector3, color: Color3)
	local column = Instance.new("Part")
	column.Name = "Columna"
	column.Shape = Enum.PartType.Cylinder
	column.Size = Vector3.new(60, 1, 1)
	column.CFrame = CFrame.new(position.X, position.Y + 29, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	column.Color = color
	column.Material = Enum.Material.Neon
	column.Transparency = 0.3
	column.Anchored = true
	column.CanCollide = false
	column.CanQuery = false
	column.CanTouch = false
	column.CastShadow = false
	column.Parent = effectsFolder
	Debris:AddItem(column, 1.4)
	TweenService:Create(column, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(60, 5, 5), Transparency = 1 }):Play()
end

local function rarityColor(rarity: unknown): Color3
	if typeof(rarity) == "string" and CrittersConfig.Rarities[rarity] then
		return CrittersConfig.Rarities[rarity].color
	end
	return GOLD
end

local function onEffect(kind: string, position: unknown, data: unknown)
	local here = if typeof(position) == "Vector3" then position else nil
	if kind == "captura" and here then
		local burstConfig = if typeof(data) == "string" then Gameplay.CatchBurst[data] else nil
		local color = rarityColor(data)
		burst(here, color, if burstConfig then burstConfig.particles else 12, 14, 10, 0.8)
		confetti(here, if burstConfig then burstConfig.confetti else 20)
		shockwave(here, color)
		if burstConfig and burstConfig.flash then
			flash(here, color, 16)
		end
		if burstConfig and burstConfig.column then
			lightColumn(here, color)
		end
	elseif kind == "captura_mia" then
		Effects.Play("captura_ok")
		Effects.Play("confeti")
	elseif kind == "fallo" then
		Effects.Play("captura_fallo")
		if here then
			burst(here, Color3.fromRGB(200, 200, 200), 8, 6, 4, 0.5)
		end
	elseif kind == "deposito" and here then
		Effects.Play("deposito")
		burst(here, rarityColor(data), 20, 10, 6, 0.7)
	elseif kind == "monedas" and here then
		Effects.Play("monedas")
		coinFountain(here, if typeof(data) == "number" then data else 1)
	elseif kind == "desbloqueo" then
		Effects.Play("desbloqueo")
		flashScreen()
		if here then
			burst(here, GOLD, 50, 20, 8, 1.2)
			flash(here, GOLD, 30)
		end
	elseif kind == "compra" then
		Effects.Play("compra")
		if here then
			burst(here, GOLD, 25, 12, 6, 0.8)
		end
	elseif kind == "recompensa" then
		Effects.Play("recompensa")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			burst(root.Position + Vector3.new(0, 3, 0), GOLD, 35, 14, 6, 1)
		end
	end
end

-- Pequeño "bote" al pulsar un botón y sonido de click.
function Effects.BindButton(button: GuiButton)
	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = button
	button.Activated:Connect(function()
		Effects.Play("click")
		scale.Scale = 0.88
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
end

-- Hace "pop" al aparecer (para la barra del minijuego y los paneles).
function Effects.Pop(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = gui
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Effects.Start()
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "EfectosLocales"
	effectsFolder.Parent = Workspace

	local soundFolder = Instance.new("Folder")
	soundFolder.Name = "SonidosJuego"
	soundFolder.Parent = SoundService
	for name, sound in Audio.Sfx do
		sounds[name] = makeSound(name, sound.id, sound.volume, soundFolder)
	end

	-- Música clásica: una pieza de día y otra de noche, con fundido al cambiar.
	local dayMusic = makeSound("MusicaDia", Audio.Music.dia.id, 0, soundFolder)
	local nightMusic = makeSound("MusicaNoche", Audio.Music.noche.id, 0, soundFolder)
	dayMusic.Looped = true
	nightMusic.Looped = true
	local fade = TweenInfo.new(Events.DayNight.musicFadeSeconds)
	local function updateMusic()
		local night = ReplicatedStorage:GetAttribute("IsNight") == true
		local playing = if night then nightMusic else dayMusic
		local stopping = if night then dayMusic else nightMusic
		if not playing.IsPlaying then
			playing.TimePosition = 0
			playing:Play()
		end
		TweenService:Create(playing, fade, { Volume = if night then Audio.Music.noche.volume else Audio.Music.dia.volume }):Play()
		local out = TweenService:Create(stopping, fade, { Volume = 0 })
		out.Completed:Connect(function()
			if stopping.Volume <= 0.001 then
				stopping:Pause()
			end
		end)
		out:Play()
	end
	ReplicatedStorage:GetAttributeChangedSignal("IsNight"):Connect(updateMusic)
	updateMusic()

	local gui = Instance.new("ScreenGui")
	gui.Name = "EfectosUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui
	screenFlash = frame

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect") :: RemoteEvent
	remote.OnClientEvent:Connect(onEffect)
end

return Effects
