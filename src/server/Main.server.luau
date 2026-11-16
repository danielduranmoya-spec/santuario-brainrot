--!strict
-- Punto de entrada del servidor: arranca los servicios (ver design/GDD.md).
-- Data.Start va el último: al cargar a cada jugador avisa a los demás servicios (Data.OnLoaded),
-- en el orden en que se registraron aquí.

local Services = script.Parent:WaitForChild("Services")

local Data = require(Services:WaitForChild("Data"))
local Analytics = require(Services:WaitForChild("Analytics"))
local Economy = require(Services:WaitForChild("Economy"))
local WorldArt = require(Services:WaitForChild("WorldArt"))
local Plots = require(Services:WaitForChild("Plots"))
local Boundary = require(Services:WaitForChild("Boundary"))
local Vaults = require(Services:WaitForChild("Vaults"))
local DayNight = require(Services:WaitForChild("DayNight"))
local Upgrades = require(Services:WaitForChild("Upgrades"))
local Purchases = require(Services:WaitForChild("Purchases"))
local DailyReward = require(Services:WaitForChild("DailyReward"))
local CritterSpawner = require(Services:WaitForChild("CritterSpawner"))
local LiveEvents = require(Services:WaitForChild("LiveEvents"))
local Bait = require(Services:WaitForChild("Bait"))
local Codes = require(Services:WaitForChild("Codes"))

Analytics.Start() -- el primero en apuntarse a Data.OnLoaded: paso "entra" del embudo
WorldArt.Start()
Economy.Start()
Plots.Start()
Boundary.Start()
Vaults.Start()
DayNight.Start()
Upgrades.Start()
Purchases.Start()
DailyReward.Start()
CritterSpawner.Start()
LiveEvents.Start()
Bait.Start()
Codes.Start()
Data.Start()

print("Santuario de Bichos Raros: servidor listo")
