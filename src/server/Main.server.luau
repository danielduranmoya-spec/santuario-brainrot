--!strict
-- Punto de entrada del servidor: arranca los servicios del bucle principal (semanas 7-8, ver design/GDD.md).
-- Siguientes pasos: Services/Data (DataStore), mejoras, tienda y Services/Purchases (ProcessReceipt).

local Services = script.Parent:WaitForChild("Services")

local Economy = require(Services:WaitForChild("Economy"))
local Plots = require(Services:WaitForChild("Plots"))
local CritterSpawner = require(Services:WaitForChild("CritterSpawner"))

Economy.Start()
Plots.Start()
CritterSpawner.Start()

print("Santuario de Bichos Raros: servidor listo")
