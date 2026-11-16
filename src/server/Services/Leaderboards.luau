--!strict
-- Rankings físicos (Config/Gameplay.Leaderboards): tres carteles detrás de los santuarios, visibles
-- para todos: más Robux gastados, más monedas ahora mismo y más bichos capturados en total.
--   * Cada updateSeconds se guarda la puntuación de cada jugador en un OrderedDataStore por ranking
--     y se leen los 10 primeros de todos los servidores.
--   * Sin OrderedDataStore (Studio sin publicar), los carteles enseñan a los jugadores de este servidor.
--   * Foto de cada jugador con rbxthumb:// (no hace falta pedirla a ninguna API).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Format = require(Shared:WaitForChild("Format"))

local Data = require(script.Parent:WaitForChild("Data"))

local L = Gameplay.Leaderboards
local G = Gameplay.GroundY
local MAX_SCORE = 2 ^ 53 -- OrderedDataStore guarda enteros; con esto no se pasa

type BoardDef = typeof(L.Boards[1])
type Entry = { userId: number, score: number }
type Board = { def: BoardDef, store: OrderedDataStore?, rows: { { frame: Frame, photo: ImageLabel, name: TextLabel, score: TextLabel } } }

local Leaderboards = {}

local boards: { Board } = {}
local nameCache: { [number]: string } = {}
local storesAvailable = true

local function statOf(profile: Data.Profile, stat: string): number
	local value = (profile :: any)[stat]
	return if type(value) == "number" and value == value then math.clamp(math.floor(value), 0, MAX_SCORE) else 0
end

local function nameOf(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local player = Players:GetPlayerByUserId(userId)
	local name = if player then player.DisplayName else nil
	if not name then
		local ok, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		name = if ok and type(result) == "string" then result else "Jugador"
	end
	nameCache[userId] = name :: string
	return name :: string
end

local function newText(parent: Instance, name: string, size: UDim2, position: UDim2, font: Enum.Font, color: Color3, align: Enum.TextXAlignment?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.TextXAlignment = align or Enum.TextXAlignment.Center
	label.Parent = parent
	return label
end

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(radius, 0)
	c.Parent = parent
end

-- Cartel: marco de madera dorada, tablero oscuro con SurfaceGui y patas.
local function buildBoard(def: BoardDef, index: number, folder: Folder): Board
	local x = (index - (#L.Boards + 1) / 2) * L.spacingX
	local size = L.size
	local model = Instance.new("Model")
	model.Name = "Ranking" .. def.id
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	-- La cara delantera (-Z del cartel) mira hacia la plaza (Z menores).
	local center = CFrame.new(x, G + 2 + size.Y / 2, L.z)

	local panel = Instance.new("Part")
	panel.Name = "Tablero"
	panel.Size = size
	panel.CFrame = center
	panel.Color = Color3.fromRGB(30, 34, 60)
	panel.Material = Enum.Material.SmoothPlastic
	panel.Anchored = true
	panel.Parent = model
	local frameColor = Color3.fromRGB(190, 140, 50)
	for _, offset in { Vector3.new(0, size.Y / 2 + 0.4, 0), Vector3.new(0, -size.Y / 2 - 0.4, 0) } do
		local bar = Instance.new("Part")
		bar.Name = "Marco"
		bar.Size = Vector3.new(size.X + 1.6, 0.8, size.Z + 0.4)
		bar.CFrame = center * CFrame.new(offset)
		bar.Color = frameColor
		bar.Material = Enum.Material.Wood
		bar.Anchored = true
		bar.Parent = model
	end
	for _, side in { -1, 1 } do
		local post = Instance.new("Part")
		post.Name = "Pata"
		post.Size = Vector3.new(0.8, size.Y + 3.6, size.Z + 0.4)
		post.CFrame = CFrame.new(x + side * (size.X / 2 + 0.4), G + (size.Y + 3.6) / 2, L.z)
		post.Color = frameColor
		post.Material = Enum.Material.Wood
		post.Anchored = true
		post.Parent = model
	end

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.MaxDistance = 250
	gui.Parent = panel

	local header = Instance.new("Frame")
	header.Name = "Cabecera"
	header.Size = UDim2.fromScale(0.94, 0.14)
	header.Position = UDim2.fromScale(0.03, 0.015)
	header.BackgroundColor3 = def.color
	header.Parent = gui
	corner(header, 0.2)
	newText(header, "Titulo", UDim2.fromScale(0.94, 0.6), UDim2.fromScale(0.03, 0.04), Enum.Font.LuckiestGuy, Color3.new(1, 1, 1)).Text = def.title
	newText(header, "Subtitulo", UDim2.fromScale(0.94, 0.3), UDim2.fromScale(0.03, 0.66), Enum.Font.GothamBold, Color3.new(1, 1, 1)).Text = def.subtitle

	local rows = {}
	local top = 0.17
	local rowHeight = (0.93 - top) / L.rows
	local medal = { Color3.fromRGB(255, 205, 60), Color3.fromRGB(200, 205, 215), Color3.fromRGB(215, 140, 70) }
	for rank = 1, L.rows do
		local row = Instance.new("Frame")
		row.Name = "Puesto" .. rank
		row.Size = UDim2.fromScale(0.94, rowHeight * 0.88)
		row.Position = UDim2.fromScale(0.03, top + (rank - 1) * rowHeight)
		row.BackgroundColor3 = medal[rank] or Color3.fromRGB(45, 55, 95)
		row.BackgroundTransparency = if medal[rank] then 0.1 else 0.2
		row.Parent = gui
		corner(row, 0.3)
		local textColor = if medal[rank] then Color3.fromRGB(30, 25, 20) else Color3.new(1, 1, 1)
		newText(row, "Puesto", UDim2.fromScale(0.1, 0.8), UDim2.fromScale(0.02, 0.1), Enum.Font.GothamBlack, textColor).Text = tostring(rank)
		local photo = Instance.new("ImageLabel")
		photo.Name = "Foto"
		photo.Size = UDim2.fromScale(0.12, 0.9)
		photo.Position = UDim2.fromScale(0.13, 0.05)
		photo.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		photo.BackgroundTransparency = 0.3
		photo.Parent = row
		corner(photo, 0.5)
		local name = newText(row, "Nombre", UDim2.fromScale(0.42, 0.7), UDim2.fromScale(0.27, 0.15), Enum.Font.GothamBold, textColor, Enum.TextXAlignment.Left)
		local score = newText(row, "Puntos", UDim2.fromScale(0.3, 0.7), UDim2.fromScale(0.68, 0.15), Enum.Font.GothamBlack, textColor, Enum.TextXAlignment.Right)
		row.Visible = false
		table.insert(rows, { frame = row, photo = photo, name = name, score = score })
	end
	newText(gui, "Pie", UDim2.fromScale(0.94, 0.04), UDim2.fromScale(0.03, 0.95), Enum.Font.Gotham, Color3.fromRGB(200, 200, 220)).Text = "Se actualiza cada minuto"

	model.Parent = folder

	local store: OrderedDataStore? = nil
	if storesAvailable then
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore("Ranking_" .. def.id .. "_v" .. L.storeVersion)
		end)
		if ok then
			store = result
		else
			storesAvailable = false
		end
	end
	return { def = def, store = store, rows = rows }
end

local function render(board: Board, entries: { Entry })
	for rank, row in board.rows do
		local entry = entries[rank]
		row.frame.Visible = entry ~= nil
		if entry then
			row.photo.Image = "rbxthumb://type=AvatarHeadShot&id=" .. entry.userId .. "&w=48&h=48"
			row.name.Text = nameOf(entry.userId)
			row.score.Text = Format.number(entry.score) .. board.def.suffix
		end
	end
end

-- Los 10 primeros solo con los jugadores de este servidor.
local function localTop(board: Board): { Entry }
	local entries: { Entry } = {}
	for _, player in Players:GetPlayers() do
		local profile = Data.Get(player)
		if profile then
			table.insert(entries, { userId = player.UserId, score = statOf(profile, board.def.stat) })
		end
	end
	table.sort(entries, function(a, b)
		return a.score > b.score
	end)
	return entries
end

local function update(board: Board)
	local store = board.store
	if not store or not storesAvailable then
		render(board, localTop(board))
		return
	end
	-- Guardar las puntuaciones de quien juega aquí (solo si sus datos se guardan de verdad).
	for _, player in Players:GetPlayers() do
		local profile = Data.Get(player)
		if profile and Data.IsPersistent(player) then
			local score = statOf(profile, board.def.stat)
			pcall(function()
				store:SetAsync(tostring(player.UserId), score)
			end)
		end
	end
	local ok, result = pcall(function()
		return store:GetSortedAsync(false, L.rows):GetCurrentPage()
	end)
	if not ok then
		storesAvailable = false
		warn("[Leaderboards] Rankings globales no disponibles, se muestran los de este servidor: " .. tostring(result))
		render(board, localTop(board))
		return
	end
	local entries: { Entry } = {}
	for _, item in result do
		local userId = tonumber(item.key)
		if userId then
			table.insert(entries, { userId = userId, score = item.value })
		end
	end
	render(board, entries)
end

function Leaderboards.Start()
	local folder = Instance.new("Folder")
	folder.Name = "Rankings"
	folder.Parent = Workspace
	for index, def in L.Boards do
		table.insert(boards, buildBoard(def, index, folder))
	end
	task.spawn(function()
		task.wait(5) -- que carguen los primeros jugadores
		while true do
			for _, board in boards do
				update(board)
			end
			task.wait(L.updateSeconds)
		end
	end)
end

return Leaderboards
