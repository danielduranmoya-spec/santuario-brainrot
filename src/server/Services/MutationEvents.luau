--!strict
-- Eventos de mutación (Config/Mutations.Events): cada 20 minutos empieza uno, sorteado por peso,
-- y dura 5 minutos. Mientras dura, sube el % de sus colores en TODOS los bichos que aparecen
-- (CritterSpawner pregunta CurrentBoosts al crear cada bicho).
--   * Los jugadores pueden invocar uno con Robux (Services/Purchases llama a Invoke desde
--     ProcessReceipt). Si ya hay un evento en marcha, el invocado espera su turno en una cola.
--   * El estado se publica en ReplicatedStorage (atributos MutationEvent, MutationEventEndsAt y
--     MutationEventNextAt, en tiempo de servidor) para que el cliente cambie el cielo y avise.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared:WaitForChild("Config"):WaitForChild("Mutations"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))

local Remotes = require(script.Parent:WaitForChild("Remotes"))

type EventDef = Mutations.EventDef

local E = Mutations.Events
local CHECK_SECONDS = 1

local MutationEvents = {}

local rng = Random.new()
local active: EventDef? = nil
local endsAt = 0 -- os.clock()
local nextAutoAt = 0 -- os.clock()
local queue: { EventDef } = {}

local function announce(text: string, color: Color3?)
	Remotes.Announce:FireAllClients(text, color)
end

-- "Oro 18 %" / "Espectral 0,9 % y Vacío 0,15 %"
local function boostText(def: EventDef): string
	local parts = {}
	for _, color in Mutations.Colors do
		local chance = def.boosts[color.id]
		if chance then
			table.insert(parts, color.label .. " " .. string.gsub(tostring(chance), "%.", ",") .. " %")
		end
	end
	return table.concat(parts, " y ")
end

local function publish()
	local now = os.clock()
	local serverNow = Workspace:GetServerTimeNow()
	ReplicatedStorage:SetAttribute("MutationEvent", if active then active.id else nil)
	ReplicatedStorage:SetAttribute("MutationEventEndsAt", if active then serverNow + (endsAt - now) else nil)
	ReplicatedStorage:SetAttribute("MutationEventNextAt", serverNow + (nextAutoAt - now))
end

local function start(def: EventDef)
	active = def
	endsAt = os.clock() + E.durationSeconds
	publish()
	announce(def.icon .. " ¡" .. string.upper(def.name) .. "! Durante " .. E.durationSeconds // 60 .. " minutos: " .. boostText(def) .. " en todos los bichos.", def.color)
end

local function finish()
	local def = active
	active = nil
	publish()
	if def and #queue == 0 then
		announce(def.icon .. " " .. def.name .. " ha terminado.", def.color)
	end
end

local function loop()
	while true do
		task.wait(CHECK_SECONDS)
		local now = os.clock()
		if active and now >= endsAt then
			finish()
		end
		if now >= nextAutoAt then
			nextAutoAt = now + E.intervalSeconds
			-- En un servidor vacío no se gasta el evento; con cola, ya hay uno a punto de empezar.
			if #Players:GetPlayers() > 0 and #queue == 0 and active == nil then
				table.insert(queue, MutationMath.rollEvent(rng:NextNumber()))
			end
			publish()
		end
		if active == nil and #queue > 0 then
			start(table.remove(queue, 1) :: EventDef)
		end
	end
end

-- % de los colores potenciados ahora mismo (nil si no hay evento).
function MutationEvents.CurrentBoosts(): { [string]: number }?
	local def = active
	return if def then def.boosts else nil
end

-- Un jugador ha comprado la invocación de `def`: aviso dorado para todos y a la cola.
-- Devuelve el texto para quien lo ha comprado. Nunca falla (la compra ya está cobrada).
function MutationEvents.Invoke(player: Player, def: EventDef): string
	table.insert(queue, def)
	local waiting = active ~= nil or #queue > 1
	announce("🌟 ¡" .. player.DisplayName .. " ha invocado " .. def.article .. " para todos!" .. (if waiting then " Empezará cuando termine el evento actual." else ""), Mutations.announceColor)
	return def.icon .. " Has invocado " .. def.article .. "."
end

function MutationEvents.Start()
	nextAutoAt = os.clock() + E.intervalSeconds
	publish()
	task.spawn(loop)

	-- Solo en Studio: ServerStorage.DebugEventoMutacion:Invoke("GrietaVacio") lo pone en la cola ya.
	if RunService:IsStudio() then
		local debugEvent = Instance.new("BindableFunction")
		debugEvent.Name = "DebugEventoMutacion"
		debugEvent.OnInvoke = function(id: string)
			local def = MutationMath.event(id)
			if def then
				table.insert(queue, def)
			end
			return def ~= nil
		end
		debugEvent.Parent = ServerStorage
	end
end

return MutationEvents
