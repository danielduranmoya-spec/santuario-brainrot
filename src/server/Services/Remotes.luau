--!strict
-- Crea los RemoteEvents en ReplicatedStorage.Remotes. El cliente los busca con WaitForChild.
-- Todo lo que llega del cliente se valida en el servidor (tipo, rango y cooldown).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local function newEvent(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local Remotes = {
	-- servidor -> cliente
	StartMinigame = newEvent("StartMinigame"), -- (datos de la barra)
	CatchResult = newEvent("CatchResult"), -- (acierto: boolean, mensaje: string)
	Notify = newEvent("Notify"), -- (mensaje: string)
	Effect = newEvent("Effect"), -- (tipo: string, posición: Vector3?, dato: any) solo efectos visuales/sonido
	-- cliente -> servidor
	AttemptCatch = newEvent("AttemptCatch"), -- (momento en tiempo de servidor: number)
	ReleaseCarried = newEvent("ReleaseCarried"), -- ()
	BuyUpgrade = newEvent("BuyUpgrade"), -- (nombre de la mejora: string)
	PromptPurchase = newEvent("PromptPurchase"), -- (tipo: "pass" | "product", nombre: string)
}

folder.Parent = ReplicatedStorage

return Remotes
