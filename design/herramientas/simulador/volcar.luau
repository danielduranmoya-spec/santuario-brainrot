-- Arranca el servidor como en Roblox y vuelca lo que hay en Workspace.
local ok, err = pcall(function()
	RBX.run(scripts["ServerScriptService/Server/Main"])
end)
if not ok then RBX.log("ERROR al arrancar: " .. tostring(err)) end

-- Bichos de muestra para las capturas: unos cuantos por zona, elegidos con el reparto real.
local critterList = {}
do
	local RS = game:GetService("ReplicatedStorage")
	local VM = RBX.require(RS.Shared.VaultMath)
	local GP = RBX.require(RS.Shared.Config.Gameplay)
	local seedRng = 0
	local function rnd() seedRng = (seedRng * 1103515245 + 12345) % 2147483648 return seedRng / 2147483648 end
	for n = 1, 8 do
		for k = 1, 7 do
			local def = VM.pickCritter(n, 1.6, rnd())
			if def then
				local p = VM.point(n, rnd() * 0.8 - 0.4, rnd() * 0.8 - 0.4)
				local size = GP.CritterSizes[def.rarity]
				table.insert(critterList, string.format('{"id":"%s","p":[%.2f,%.2f,%.2f],"size":%.2f,"yaw":%.2f}', def.id, p.X, p.Y, p.Z, size, rnd() * 6.28))
			end
		end
	end
	-- y unos pocos en la plaza (en los santuarios)
	local LO = RBX.require(RS.Shared.Layout)
	local Critters = RBX.require(RS.Shared.Config.Critters)
	for i = 1, 6 do
		local cf = LO.plot(i)
		for k = 1, 3 do
			local def = Critters.List[((i * 3 + k) % #Critters.List) + 1]
			local p = (cf * RBX.CFrame.new((k - 2) * 8.5, 0, -5)).Position
			table.insert(critterList, string.format('{"id":"%s","p":[%.2f,%.2f,%.2f],"size":%.2f,"yaw":%.2f,"plot":true}', def.id, p.X, p.Y + 1.2, p.Z, GP.CritterSizes[def.rarity] * 0.8, 0))
		end
	end
end

local ws = RBX.workspace
local function num(x) return string.format("%.4g", x) end
local function vec(v) return "[" .. num(v.X) .. "," .. num(v.Y) .. "," .. num(v.Z) .. "]" end
local function cf(c) local t = { c:GetComponents() } for i, x in t do t[i] = num(x) end return "[" .. table.concat(t, ",") .. "]" end
local function col(c) return "[" .. num(c.R) .. "," .. num(c.G) .. "," .. num(c.B) .. "]" end
local function str(s) return '"' .. tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub("\n", "\\n") .. '"' end
local parts, lights, terrain, labels = {}, {}, {}, {}
for _, i in RBX.all do
	if not rawget(i, "__destroyed") and i:IsDescendantOf(ws) then
		local P = i.__props
		if i:IsA("BasePart") then
			local mesh = i:FindFirstChildOfClass("SpecialMesh")
			local shape = rawget(i, "ClassName") == "WedgePart" and "Wedge" or rawget(i, "ClassName") == "CornerWedgePart" and "CornerWedge" or (P.Shape and P.Shape.Name or "Block")
			if mesh and mesh.__props.MeshType then shape = "Mesh" .. mesh.__props.MeshType.Name end
			table.insert(parts, "{" .. table.concat({
				'"n":' .. str(i:GetFullName()), '"s":' .. str(shape), '"size":' .. vec(P.Size), '"cf":' .. cf(P.CFrame),
				'"c":' .. col(P.Color or RBX.Color3.new(0.6, 0.6, 0.6)), '"m":' .. str(P.Material and P.Material.Name or "Plastic"),
				'"t":' .. num(P.Transparency or 0), '"r":' .. num(P.Reflectance or 0),
				'"ms":' .. (mesh and mesh.__props.Scale and vec(mesh.__props.Scale) or "null"),
			}, ",") .. "}")
		elseif i:IsA("Light") and P.Parent and P.Parent:IsA("BasePart") then
			table.insert(lights, "{" .. '"p":' .. vec(P.Parent.__props.CFrame.p) .. ',"c":' .. col(P.Color or RBX.Color3.new(1, 1, 1)) .. ',"range":' .. num(P.Range or 8) .. ',"b":' .. num(P.Brightness or 1) .. "}")
		elseif (rawget(i, "ClassName") == "TextLabel") and P.Text then
			local anc = i:FindFirstAncestorWhichIsA("BasePart")
			if anc then table.insert(labels, "{" .. '"text":' .. str(P.Text) .. ',"p":' .. vec(anc.__props.CFrame.p) .. "}") end
		end
	end
end
for _, t in RBX.terrain do
	local s = '{"k":' .. str(t.kind) .. ',"mat":' .. str(t.mat)
	if t.cf then s ..= ',"cf":' .. cf(t.cf) end
	if t.size then s ..= ',"size":' .. vec(t.size) end
	if t.center then s ..= ',"center":' .. vec(t.center) end
	if t.radius then s ..= ',"radius":' .. num(t.radius) end
	if t.height then s ..= ',"height":' .. num(t.height) end
	table.insert(terrain, s .. "}")
end
local tcol = {}
for k, v in RBX.terrainColors or {} do table.insert(tcol, str(k) .. ":" .. col(v)) end
local logs = {}
for _, l in RBX.logs do table.insert(logs, str(l)) end
local L = game:GetService("Lighting").__props
print("{" .. table.concat({
	'"parts":[' .. table.concat(parts, ",") .. "]",
	'"lights":[' .. table.concat(lights, ",") .. "]",
	'"terrain":[' .. table.concat(terrain, ",") .. "]",
	'"labels":[' .. table.concat(labels, ",") .. "]",
	'"terrainColors":{' .. table.concat(tcol, ",") .. "}",
	'"clock":' .. num(L.ClockTime or 14),
	'"critters":[' .. table.concat(critterList, ",") .. "]",
	'"logs":[' .. table.concat(logs, ",") .. "]",
}, ",") .. "}")
