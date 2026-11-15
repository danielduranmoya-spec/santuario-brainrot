--!strict
-- Punto de entrada del servidor: arranca los servicios (ver design/GDD.md).
-- Data.Start va el último: al cargar a cada jugador avisa a los demás servicios (Data.OnLoaded),
-- en el orden en que se registraron aquí.

local Services = script.Parent:WaitForChild("Services")

local Data = require(Services:WaitForChild("Data"))
local Economy = require(Services:WaitForChild("Economy"))
local WorldArt = require(Services:WaitForChild("WorldArt"))
local Plots = require(Services:WaitForChild("Plots"))
local Boundary = require(Services:WaitForChild("Boundary"))
local Zones = require(Services:WaitForChild("Zones"))
local Upgrades = require(Services:WaitForChild("Upgrades"))
local Purchases = require(Services:WaitForChild("Purchases"))
local DailyReward = require(Services:WaitForChild("DailyReward"))
local CritterSpawner = require(Services:WaitForChild("CritterSpawner"))

WorldArt.Start()
Economy.Start()
Plots.Start()
Boundary.Start()
Zones.Start()
Upgrades.Start()
Purchases.Start()
DailyReward.Start()
CritterSpawner.Start()
Data.Start()

print("Santuario de Bichos Raros: servidor listo")
