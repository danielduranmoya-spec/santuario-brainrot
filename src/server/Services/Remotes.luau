--!strict
-- Crea los RemoteEvents en ReplicatedStorage.Remotes. El cliente los busca con WaitForChild.

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
	-- cliente -> servidor
	AttemptCatch = newEvent("AttemptCatch"), -- (momento en tiempo de servidor: number)
	ReleaseCarried = newEvent("ReleaseCarried"), -- ()
}

folder.Parent = ReplicatedStorage

return Remotes
