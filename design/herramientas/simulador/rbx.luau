-- Simulación mínima de Roblox para ejecutar el código del juego fuera de Studio y registrar lo que
-- construye (piezas, terreno, luces). No es Roblox: solo lo justo para que el código del mapa corra.

local RBX = {}
local unpackT = table.unpack

------------------------------------------------------------------ Vector3
local V3 = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __t = "Vector3" }, V3)
end
V3.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	elseif k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then return v3(0, 0, 0) end
		return v3(t.X / m, t.Y / m, t.Z / m)
	elseif k == "x" then return t.X elseif k == "y" then return t.Y elseif k == "z" then return t.Z
	end
	return V3[k]
end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return v3(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__idiv = function(a, b) return v3(a.X // b, a.Y // b, a.Z // b) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(a) return string.format("%g, %g, %g", a.X, a.Y, a.Z) end
function V3.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3.Cross(a, b) return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
function V3.Lerp(a, b, t) return a + (b - a) * t end
function V3.Max(a, b) return v3(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z)) end
function V3.Min(a, b) return v3(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z)) end
function V3.Abs(a) return v3(math.abs(a.X), math.abs(a.Y), math.abs(a.Z)) end
function V3.FuzzyEq(a, b, e) return (a - b).Magnitude <= (e or 1e-5) end
RBX.Vector3 = {
	new = v3, zero = v3(0, 0, 0), one = v3(1, 1, 1),
	xAxis = v3(1, 0, 0), yAxis = v3(0, 1, 0), zAxis = v3(0, 0, 1),
	fromNormalId = function() return v3(0, 1, 0) end,
}

local function plain(tname, fields)
	fields.__t = tname
	return fields
end
RBX.Vector2 = { new = function(x, y) return setmetatable(plain("Vector2", { X = x or 0, Y = y or 0 }), {
	__add = function(a, b) return RBX.Vector2.new(a.X + b.X, a.Y + b.Y) end,
	__sub = function(a, b) return RBX.Vector2.new(a.X - b.X, a.Y - b.Y) end,
	__mul = function(a, b) if type(b) == "number" then return RBX.Vector2.new(a.X * b, a.Y * b) end return RBX.Vector2.new(a.X * b.X, a.Y * b.Y) end,
	__index = function(t, k) if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end end,
}) end }
RBX.Vector2.zero = RBX.Vector2.new(0, 0)
RBX.Vector2.one = RBX.Vector2.new(1, 1)
RBX.UDim = { new = function(s, o) return plain("UDim", { Scale = s, Offset = o }) end }
RBX.UDim2 = {
	new = function(a, b, c, d) return plain("UDim2", { X = RBX.UDim.new(a, b), Y = RBX.UDim.new(c, d) }) end,
	fromScale = function(a, b) return RBX.UDim2.new(a, 0, b, 0) end,
	fromOffset = function(a, b) return RBX.UDim2.new(0, a, 0, b) end,
}
RBX.Rect = { new = function(...) return plain("Rect", { ... }) end }
RBX.NumberRange = { new = function(a, b) return plain("NumberRange", { Min = a, Max = b or a }) end }
RBX.NumberSequence = { new = function(...) return plain("NumberSequence", { ... }) end }
RBX.NumberSequenceKeypoint = { new = function(...) return plain("NSK", { ... }) end }
RBX.ColorSequence = { new = function(a, b) return plain("ColorSequence", { a, b }) end }
RBX.ColorSequenceKeypoint = { new = function(t, c) return plain("CSK", { Time = t, Value = c }) end }
RBX.TweenInfo = { new = function(...) return plain("TweenInfo", { ... }) end }
RBX.PhysicalProperties = { new = function(...) return plain("PhysicalProperties", { ... }) end }
RBX.Font = { new = function(...) return plain("Font", { ... }) end, fromEnum = function(e) return e end }
RBX.BrickColor = { new = function(n) return plain("BrickColor", { Name = n }) end }

------------------------------------------------------------------ Color3
local C3 = {}
C3.__index = C3
local function c3(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0, __t = "Color3" }, C3) end
function C3.Lerp(a, b, t) return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
function C3.ToHSV(c)
	local r, g, b = c.R, c.G, c.B
	local mx, mn = math.max(r, g, b), math.min(r, g, b)
	local h, s, v = 0, 0, mx
	local d = mx - mn
	if mx > 0 then s = d / mx end
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6 elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h, s, v
end
C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
local function hsv(h, s, v)
	h = (h % 1) * 6
	local i = math.floor(h)
	local f = h - i
	local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
	local r, g, b
	if i == 0 then r, g, b = v, t, p elseif i == 1 then r, g, b = q, v, p elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v elseif i == 4 then r, g, b = t, p, v else r, g, b = v, p, q end
	return c3(r, g, b)
end
RBX.Color3 = {
	new = c3,
	fromRGB = function(r, g, b) return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	fromHSV = hsv,
	fromHex = function(h)
		h = h:gsub("#", "")
		return c3(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255)
	end,
	toHSV = C3.ToHSV,
}

------------------------------------------------------------------ CFrame
local CF = {}
local function cfm(p, m) -- m: filas {r00,r01,r02, r10,r11,r12, r20,r21,r22}
	return setmetatable({ p = p, m = m, __t = "CFrame" }, CF)
end
local I3 = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function mmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return r
end
local function mv(m, v)
	return v3(m[1] * v.X + m[2] * v.Y + m[3] * v.Z, m[4] * v.X + m[5] * v.Y + m[6] * v.Z, m[7] * v.X + m[8] * v.Y + m[9] * v.Z)
end
local function mT(m) return { m[1], m[4], m[7], m[2], m[5], m[8], m[3], m[6], m[9] } end
local function rx(a) local c, s = math.cos(a), math.sin(a) return { 1, 0, 0, 0, c, -s, 0, s, c } end
local function ry(a) local c, s = math.cos(a), math.sin(a) return { c, 0, s, 0, 1, 0, -s, 0, c } end
local function rz(a) local c, s = math.cos(a), math.sin(a) return { c, -s, 0, s, c, 0, 0, 0, 1 } end
local function lookAt(pos, target, up)
	up = up or v3(0, 1, 0)
	local look = (target - pos).Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then right = look:Cross(v3(0, 0, 1)) end
	right = right.Unit
	local upv = right:Cross(look)
	-- columnas: right, up, -look
	return cfm(pos, { right.X, upv.X, -look.X, right.Y, upv.Y, -look.Y, right.Z, upv.Z, -look.Z })
end
CF.__index = function(t, k)
	if k == "Position" then return t.p
	elseif k == "X" then return t.p.X elseif k == "Y" then return t.p.Y elseif k == "Z" then return t.p.Z
	elseif k == "LookVector" then return v3(-t.m[3], -t.m[6], -t.m[9])
	elseif k == "RightVector" then return v3(t.m[1], t.m[4], t.m[7])
	elseif k == "UpVector" then return v3(t.m[2], t.m[5], t.m[8])
	elseif k == "XVector" then return v3(t.m[1], t.m[4], t.m[7])
	elseif k == "YVector" then return v3(t.m[2], t.m[5], t.m[8])
	elseif k == "ZVector" then return v3(t.m[3], t.m[6], t.m[9])
	elseif k == "Rotation" then return cfm(v3(0, 0, 0), t.m)
	end
	return CF[k]
end
CF.__mul = function(a, b)
	if b.__t == "Vector3" then return a.p + mv(a.m, b) end
	return cfm(a.p + mv(a.m, b.p), mmul(a.m, b.m))
end
CF.__add = function(a, v) return cfm(a.p + v, a.m) end
CF.__sub = function(a, v) return cfm(a.p - v, a.m) end
function CF.Inverse(a) local t = mT(a.m) return cfm(-mv(t, a.p), t) end
function CF.ToWorldSpace(a, b) return a * b end
function CF.ToObjectSpace(a, b) return a:Inverse() * b end
function CF.PointToWorldSpace(a, v) return a * v end
function CF.PointToObjectSpace(a, v) return a:Inverse() * v end
function CF.VectorToWorldSpace(a, v) return mv(a.m, v) end
function CF.VectorToObjectSpace(a, v) return mv(mT(a.m), v) end
function CF.Lerp(a, b, t) return cfm(a.p:Lerp(b.p, t), t < 0.5 and a.m or b.m) end
function CF.GetComponents(a) local m = a.m return a.p.X, a.p.Y, a.p.Z, m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9] end
CF.components = CF.GetComponents
function CF.ToEulerAnglesXYZ(a)
	local m = a.m
	local y = math.asin(math.clamp(m[3], -1, 1))
	local x = math.atan2(-m[6], m[9])
	local z = math.atan2(-m[2], m[1])
	return x, y, z
end
function CF.ToOrientation(a)
	local m = a.m
	local x = math.asin(math.clamp(-m[6], -1, 1))
	local y = math.atan2(m[3], m[9])
	local z = math.atan2(m[4], m[5])
	return x, y, z
end
local function angles(x, y, z) return cfm(v3(0, 0, 0), mmul(mmul(rx(x or 0), ry(y or 0)), rz(z or 0))) end
local function orientation(x, y, z) return cfm(v3(0, 0, 0), mmul(mmul(ry(y or 0), rx(x or 0)), rz(z or 0))) end
RBX.CFrame = {
	new = function(a, b, c, ...)
		if a == nil then return cfm(v3(0, 0, 0), I3) end
		if type(a) == "number" then
			local rest = { ... }
			if #rest == 9 then return cfm(v3(a, b, c), rest) end
			return cfm(v3(a, b, c), I3)
		end
		if b ~= nil then return lookAt(a, b) end
		return cfm(a, I3)
	end,
	lookAt = lookAt,
	Angles = angles,
	fromEulerAnglesXYZ = angles,
	fromEulerAngles = angles,
	fromOrientation = orientation,
	fromEulerAnglesYXZ = orientation,
	fromAxisAngle = function(axis, ang)
		local u = axis.Unit
		local c, s, t = math.cos(ang), math.sin(ang), 1 - math.cos(ang)
		local x, y, z = u.X, u.Y, u.Z
		return cfm(v3(0, 0, 0), { t * x * x + c, t * x * y - s * z, t * x * z + s * y, t * x * y + s * z, t * y * y + c, t * y * z - s * x, t * x * z - s * y, t * y * z + s * x, t * z * z + c })
	end,
	fromMatrix = function(pos, vx, vy, vz)
		vz = vz or vx:Cross(vy)
		return cfm(pos, { vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z })
	end,
}
RBX.CFrame.identity = RBX.CFrame.new()

------------------------------------------------------------------ Enum
local function enumItem(enumName, name)
	return setmetatable({ Name = name, EnumType = enumName, Value = 0, __t = "EnumItem" }, {
		__tostring = function() return "Enum." .. enumName .. "." .. name end,
		__eq = function(a, b) return rawget(a, "Name") == rawget(b, "Name") and rawget(a, "EnumType") == rawget(b, "EnumType") end,
	})
end
local enumCache = {}
RBX.Enum = setmetatable({}, { __index = function(_, enumName)
	enumCache[enumName] = enumCache[enumName] or setmetatable({ GetEnumItems = function() return {} end }, {
		__index = function(t, name)
			local item = enumItem(enumName, name)
			rawset(t, name, item)
			return item
		end,
	})
	return enumCache[enumName]
end })

------------------------------------------------------------------ Señales
local Signal = {}
Signal.__index = Signal
local function signal() return setmetatable({ handlers = {} }, Signal) end
function Signal:Connect(fn)
	table.insert(self.handlers, fn)
	return { Disconnect = function() end, Connected = true }
end
Signal.Once = Signal.Connect
Signal.ConnectParallel = Signal.Connect
function Signal:Wait() if coroutine.isyieldable() then coroutine.yield() end end
function Signal:Fire(...) for _, h in self.handlers do RBX.spawn(h, ...) end end

------------------------------------------------------------------ task (los bucles no vuelven)
function RBX.spawn(fn, ...)
	if type(fn) ~= "function" then return end
	local co = coroutine.create(fn)
	local ok, err = coroutine.resume(co, ...)
	if not ok then RBX.log("ERROR en hilo: " .. tostring(err)) end
	return co
end
RBX.task = {
	spawn = RBX.spawn,
	defer = RBX.spawn,
	delay = function(_, fn, ...) return nil end, -- lo programado para más tarde no se ejecuta
	wait = function() if coroutine.isyieldable() then coroutine.yield() end return 0 end,
	cancel = function() end,
	synchronize = function() end,
	desynchronize = function() end,
}
RBX.logs = {}
function RBX.log(s) table.insert(RBX.logs, s) end

------------------------------------------------------------------ Instancias
local BASEPART = { MeshPart = true, Part = true, WedgePart = true, CornerWedgePart = true, TrussPart = true, MeshPart = true, SpawnLocation = true, Seat = true, UnionOperation = true }
local DEFAULTS = {
	Part = { Size = v3(4, 1, 2), Shape = RBX.Enum.PartType.Block, Transparency = 0, Anchored = false, CanCollide = true, Material = RBX.Enum.Material.Plastic, Color = c3(0.64, 0.64, 0.64) },
}
RBX.all = {}
local Inst = {}
local instMeta = {}
local function newInstance(class)
	local self = setmetatable({ __t = "Instance", __props = {}, __children = {}, __attrs = {}, __signals = {}, ClassName = class }, instMeta)
	self.__props.Name = class
	local d = DEFAULTS[BASEPART[class] and "Part" or class]
	if d then for k, v in d do self.__props[k] = v end end
	if BASEPART[class] then
		self.__props.CFrame = RBX.CFrame.new()
	end
	table.insert(RBX.all, self)
	return self
end
instMeta.__index = function(self, k)
	local props = rawget(self, "__props")
	if k == "Name" or k == "Parent" then return props[k] end
	local v = props[k]
	if v ~= nil then return v end
	if Inst[k] then return Inst[k] end
	if k == "Position" and props.CFrame then return props.CFrame.p end
	if k == "Orientation" then return v3(0, 0, 0) end
	-- hijo con ese nombre
	for _, c in rawget(self, "__children") do
		if c.__props.Name == k then return c end
	end
	-- eventos
	if type(k) == "string" and (k:match("Changed$") or k:match("Added$") or k:match("Removing$") or k:match("^Touch") or k:match("Triggered$") or k:match("Event$") or k:match("Activated$") or k:match("Ended$") or k:match("Began$") or k:match("^On") or k:match("Heartbeat") or k:match("Stepped$") or k == "Invoked" or k:match("Hold") or k:match("Shown$") or k:match("Hidden$") or k:match("Clicked$") or k:match("Finished$") or k:match("Completed$") or k:match("Died$") or k:match("Released$") or k:match("Pressed$") or k == "ChildAdded" or k == "Destroying") then
		local s = rawget(self, "__signals")
		s[k] = s[k] or signal()
		return s[k]
	end
	return nil
end
instMeta.__newindex = function(self, k, v)
	local props = rawget(self, "__props")
	if k == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "__children")
			for i, c in list do if c == self then table.remove(list, i) break end end
		end
		props.Parent = v
		if v then table.insert(rawget(v, "__children"), self) end
		return
	end
	if k == "Position" and props.CFrame then
		props.CFrame = cfm(v, props.CFrame.m)
		return
	end
	if k == "Orientation" and BASEPART[rawget(self, "ClassName")] then
		local cf = props.CFrame
		props.CFrame = cfm(cf.p, orientation(math.rad(v.X), math.rad(v.Y), math.rad(v.Z)).m)
		props.Orientation = v
		return
	end
	if k == "PivotOffset" or k == "WorldPivot" then props[k] = v return end
	props[k] = v
end
instMeta.__tostring = function(self) return self.__props.Name end

function Inst:IsA(c)
	local cls = rawget(self, "ClassName")
	if cls == c or c == "Instance" then return true end
	if c == "BasePart" and BASEPART[cls] then return true end
	if c == "PVInstance" and (BASEPART[cls] or cls == "Model") then return true end
	if c == "LuaSourceContainer" and (cls == "Script" or cls == "ModuleScript" or cls == "LocalScript") then return true end
	if c == "GuiObject" and (cls:match("^Text") or cls == "Frame" or cls == "ImageLabel" or cls == "ImageButton" or cls == "ScrollingFrame") then return true end
	if c == "Light" and cls:match("Light$") then return true end
	if c == "ValueBase" and cls:match("Value$") then return true end
	if c == "PostEffect" and cls:match("Effect$") then return true end
	return false
end
function Inst:GetChildren() return table.clone(rawget(self, "__children")) end
function Inst:GetDescendants()
	local out = {}
	local function walk(n) for _, c in rawget(n, "__children") do table.insert(out, c) walk(c) end end
	walk(self)
	return out
end
function Inst:FindFirstChild(name, recursive)
	for _, c in rawget(self, "__children") do if c.__props.Name == name then return c end end
	if recursive then for _, d in self:GetDescendants() do if d.__props.Name == name then return d end end end
	return nil
end
function Inst:WaitForChild(name)
	local c = self:FindFirstChild(name)
	if not c then RBX.log("WaitForChild sin hijo: " .. tostring(self.__props.Name) .. "." .. name) end
	return c
end
function Inst:FindFirstChildOfClass(cls) for _, c in rawget(self, "__children") do if rawget(c, "ClassName") == cls then return c end end return nil end
function Inst:FindFirstChildWhichIsA(cls, rec)
	local list = rec and self:GetDescendants() or rawget(self, "__children")
	for _, c in list do if c:IsA(cls) then return c end end
	return nil
end
function Inst:FindFirstAncestor(name) local p = self.__props.Parent while p do if p.__props.Name == name then return p end p = p.__props.Parent end return nil end
function Inst:FindFirstAncestorOfClass(cls) local p = self.__props.Parent while p do if rawget(p, "ClassName") == cls then return p end p = p.__props.Parent end return nil end
Inst.FindFirstAncestorWhichIsA = Inst.FindFirstAncestorOfClass
function Inst:IsDescendantOf(a) local p = self.__props.Parent while p do if p == a then return true end p = p.__props.Parent end return false end
function Inst:ClearAllChildren() for _, c in self:GetChildren() do c:Destroy() end end
function Inst:Destroy() self.Parent = nil rawset(self, "__destroyed", true) end
function Inst:Clone()
	local c = newInstance(rawget(self, "ClassName"))
	for k, v in self.__props do if k ~= "Parent" then c.__props[k] = v end end
	for k, v in rawget(self, "__attrs") do rawget(c, "__attrs")[k] = v end
	for _, ch in rawget(self, "__children") do ch:Clone().Parent = c end
	return c
end
function Inst:SetAttribute(k, v) rawget(self, "__attrs")[k] = v end
function Inst:GetAttribute(k) return rawget(self, "__attrs")[k] end
function Inst:GetAttributes() return table.clone(rawget(self, "__attrs")) end
function Inst:GetAttributeChangedSignal() return signal() end
function Inst:GetPropertyChangedSignal() return signal() end
function Inst:GetFullName()
	local names, n = {}, self
	while n do table.insert(names, 1, n.__props.Name) n = n.__props.Parent end
	return table.concat(names, ".")
end
-- Modelos: pivote = el de la PrimaryPart o el centro de sus piezas.
local function modelParts(m)
	local out = {}
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then table.insert(out, d) end end
	return out
end
function Inst:GetPivot()
	if BASEPART[rawget(self, "ClassName")] then return self.__props.CFrame end
	if self.__props.WorldPivot then return self.__props.WorldPivot end
	if self.__props.PrimaryPart then return self.__props.PrimaryPart.__props.CFrame end
	local parts = modelParts(self)
	if #parts == 0 then return RBX.CFrame.new() end
	local s = v3(0, 0, 0)
	for _, p in parts do s = s + p.__props.CFrame.p end
	return RBX.CFrame.new(s / #parts)
end
function Inst:PivotTo(cf)
	if BASEPART[rawget(self, "ClassName")] then
		self.__props.CFrame = cf
		return
	end
	local delta = cf * self:GetPivot():Inverse()
	for _, p in modelParts(self) do p.__props.CFrame = delta * p.__props.CFrame end
	self.__props.WorldPivot = cf
end
function Inst:SetPrimaryPartCFrame(cf) self:PivotTo(cf) end
function Inst:GetBoundingBox()
	local parts = modelParts(self)
	if #parts == 0 then return RBX.CFrame.new(), v3(0, 0, 0) end
	local mn, mx = v3(math.huge, math.huge, math.huge), v3(-math.huge, -math.huge, -math.huge)
	for _, p in parts do
		local c, s = p.__props.CFrame.p, p.__props.Size / 2
		mn = mn:Min(c - s)
		mx = mx:Max(c + s)
	end
	return RBX.CFrame.new((mn + mx) / 2), mx - mn
end
function Inst:GetExtentsSize() local _, s = self:GetBoundingBox() return s end
function Inst:ScaleTo(k) rawset(self, "__scale", k) end
function Inst:GetScale() return 1 end
function Inst:BreakJoints() end
function Inst:MakeJoints() end
function Inst:SetNetworkOwner() end
function Inst:GetMass() return 1 end
function Inst:ApplyImpulse() end
function Inst:AddTag(t) rawget(self, "__attrs")["tag_" .. t] = true end
function Inst:HasTag(t) return rawget(self, "__attrs")["tag_" .. t] == true end
function Inst:RemoveTag() end
function Inst:GetTags() return {} end
-- RemoteEvent / BindableFunction / sonidos / tweens
function Inst:FireClient() end
function Inst:FireAllClients() end
function Inst:FireServer() end
function Inst:Fire() end
function Inst:Invoke() end
function Inst:InvokeClient() end
function Inst:Play() end
function Inst:Stop() end
function Inst:Emit() end
function Inst:Clear() end
function Inst:LoadAnimation() return newInstance("AnimationTrack") end
function Inst:MoveTo() end
function Inst:GetPlayers() return {} end
function Inst:GetPlayerFromCharacter() return nil end
function Inst:GetServerTimeNow() return os.clock() end
function Inst:IsStudio() return true end
function Inst:IsServer() return true end
function Inst:IsClient() return false end
function Inst:IsRunning() return true end
function Inst:Create() return newInstance("Tween") end
function Inst:GetDataStore() return newInstance("DataStore") end
function Inst:GetOrderedDataStore() return newInstance("DataStore") end
function Inst:GetAsync() return nil end
function Inst:SetAsync() end
function Inst:UpdateAsync() end
function Inst:UserOwnsGamePassAsync() return false end
function Inst:GetProductInfo() return {} end
function Inst:RegisterChatCallback() end
function Inst:SetPartCollisionGroup() end
function Inst:RegisterCollisionGroup() end
function Inst:CollisionGroupSetCollidable() end
function Inst:GetCollisionGroups() return {} end
function Inst:IsCollisionGroupRegistered() return false end
function Inst:GetTagged() return {} end
function Inst:GetInstanceAddedSignal() return signal() end
function Inst:GetInstanceRemovedSignal() return signal() end
function Inst:BindToClose() end
function Inst:GetTextSize() return RBX.Vector2.new(10, 10) end
function Inst:Raycast() return nil end
function Inst:GetPartBoundsInBox() return {} end
function Inst:GetPartBoundsInRadius() return {} end
function Inst:GetPartsInPart() return {} end
function Inst:Blockcast() return nil end
function Inst:Spherecast() return nil end
function Inst:ComputeAsync() end
function Inst:LogCustomEvent() end
function Inst:LogOnboardingFunnelStepEvent() end
function Inst:LogEconomyEvent() end
function Inst:LogProgressionEvent() end
function Inst:LogFunnelStepEvent() end
function Inst:PromptPurchase() end
function Inst:PromptGamePassPurchase() end
function Inst:PromptProductPurchase() end
function Inst:PromptPremiumPurchase() end
function Inst:PromptSubscriptionPurchase() end
function Inst:Kick() end
function Inst:SetCore() end
function Inst:GetCore() end
function Inst:GetUserIdFromNameAsync() return 0 end
function Inst:GetNameFromUserIdAsync() return "" end
function Inst:GetUserThumbnailAsync() return "" end
function Inst:SetMinutesAfterMidnight() end
function Inst:GetMinutesAfterMidnight() return 0 end
function Inst:GetSunDirection() return v3(0, 1, 0) end
function Inst:SendNotification() end
function Inst:DisplaySystemMessage() end
function Inst:SendAsync() end
function Inst:CanUserChatAsync() return true end
function Inst:SetTextFromInput() end

------------------------------------------------------------------ Terreno
RBX.terrain = {}
local function terrainRecord(kind, data) data.kind = kind table.insert(RBX.terrain, data) end
function Inst:FillBlock(cf, size, mat) terrainRecord("block", { cf = cf, size = size, mat = mat.Name }) end
function Inst:FillBall(center, radius, mat) terrainRecord("ball", { center = center, radius = radius, mat = mat.Name }) end
function Inst:FillCylinder(cf, height, radius, mat) terrainRecord("cyl", { cf = cf, height = height, radius = radius, mat = mat.Name }) end
function Inst:FillWedge(cf, size, mat) terrainRecord("wedge", { cf = cf, size = size, mat = mat.Name }) end
function Inst:FillRegion() end
function Inst:SetMaterialColor(mat, color) RBX.terrainColors = RBX.terrainColors or {} RBX.terrainColors[mat.Name] = color end
function Inst:ReplaceMaterial() end
function Inst:Clear() RBX.terrain = {} end

RBX.Instance = { new = function(class, parent)
	local i = newInstance(class)
	if parent then i.Parent = parent end
	return i
end }

------------------------------------------------------------------ DataModel
local game = newInstance("DataModel")
game.__props.Name = "game"
RBX.game = game
local services = {}
function Inst:GetService(name)
	if rawget(self, "ClassName") ~= "DataModel" then return nil end
	if not services[name] then
		local s = self:FindFirstChild(name) or newInstance(name)
		s.__props.Name = name
		s.Parent = self
		services[name] = s
		if name == "Workspace" then
			local t = newInstance("Terrain")
			t.__props.Name = "Terrain"
			t.Parent = s
			s.__props.CurrentCamera = newInstance("Camera")
			s.__props.Gravity = 196.2
			s.__props.Terrain = t
		elseif name == "Players" then
			s.__props.LocalPlayer = nil
		elseif name == "Lighting" then
			s.__props.ClockTime = 14
		end
	end
	return services[name]
end
game.__props.PlaceId = 0
game.__props.GameId = 0
game.__props.JobId = "simulacion"
game.__props.PrivateServerId = ""
function Inst:BindToClose() end
RBX.workspace = game:GetService("Workspace")

------------------------------------------------------------------ Módulos (require por instancia)
local loaded = {}
RBX.sources = {}
local env -- se rellena abajo
function RBX.require(m)
	if type(m) ~= "table" then error("require de algo que no es un ModuleScript: " .. tostring(m)) end
	if loaded[m] ~= nil then return loaded[m] end
	local src = RBX.sources[m]
	if not src then error("require sin código: " .. m:GetFullName()) end
	local fn, err = loadstring(src, "=" .. m:GetFullName())
	if not fn then error(err) end
	setfenv(fn, setmetatable({ script = m }, { __index = env }))
	local result = fn()
	loaded[m] = result
	return result
end
function RBX.run(scriptInst)
	local fn, err = loadstring(RBX.sources[scriptInst], "=" .. scriptInst:GetFullName())
	if not fn then error(err) end
	setfenv(fn, setmetatable({ script = scriptInst }, { __index = env }))
	return fn()
end

-- Un ModuleScript/Script en el árbol, con su código.
function RBX.addSource(parent, name, class, src)
	local s = newInstance(class)
	s.__props.Name = name
	s.Parent = parent
	RBX.sources[s] = src
	return s
end
function RBX.folder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local f = newInstance("Folder")
	f.__props.Name = name
	f.Parent = parent
	return f
end

local rand = {}
rand.__index = rand
local seed = 12345
local function lcg() seed = (seed * 1103515245 + 12345) % 2147483648 return seed / 2147483648 end
function rand:NextNumber(a, b) a = a or 0 b = b or 1 return a + (b - a) * lcg() end
function rand:NextInteger(a, b) return math.floor(a + (b - a + 1) * lcg()) end
function rand:NextUnitVector() return v3(lcg() - 0.5, lcg() - 0.5, lcg() - 0.5).Unit end
function rand:Shuffle(t) end
function rand:Clone() return self end

env = setmetatable({
	game = game, workspace = RBX.workspace, Workspace = RBX.workspace,
	Instance = RBX.Instance, Vector3 = RBX.Vector3, Vector2 = RBX.Vector2, CFrame = RBX.CFrame,
	Color3 = RBX.Color3, Enum = RBX.Enum, UDim = RBX.UDim, UDim2 = RBX.UDim2, Rect = RBX.Rect,
	NumberRange = RBX.NumberRange, NumberSequence = RBX.NumberSequence, NumberSequenceKeypoint = RBX.NumberSequenceKeypoint,
	ColorSequence = RBX.ColorSequence, ColorSequenceKeypoint = RBX.ColorSequenceKeypoint, TweenInfo = RBX.TweenInfo,
	PhysicalProperties = RBX.PhysicalProperties, Font = RBX.Font, BrickColor = RBX.BrickColor,
	task = RBX.task, require = RBX.require,
	RaycastParams = { new = function() return {} end }, OverlapParams = { new = function() return {} end },
	Ray = { new = function(o, d) return { Origin = o, Direction = d } end },
	Region3 = { new = function(a, b) return { CFrame = RBX.CFrame.new((a + b) / 2), Size = b - a } end },
	wait = RBX.task.wait, spawn = RBX.spawn, delay = RBX.task.delay, tick = os.clock, time = os.clock,
	Random = { new = function(s) if s then seed = math.floor(s) % 2147483648 end return setmetatable({}, rand) end },
	DateTime = { now = function() return { UnixTimestamp = 1763337600, UnixTimestampMillis = 1763337600000, ToUniversalTime = function() return { Year = 2026, Month = 11, Day = 17, Hour = 0, Minute = 0, Second = 0 } end } end,
		fromUnixTimestamp = function(t) return { UnixTimestamp = t, ToUniversalTime = function() return { Year = 2026, Month = 11, Day = 17, Hour = 0, Minute = 0, Second = 0 } end, FormatUniversalTime = function() return "" end } end },
	typeof = function(v)
		if type(v) == "table" then
			local t = rawget(v, "__t")
			if t then return t end
		end
		return type(v)
	end,
	warn = function(...) RBX.log("warn: " .. table.concat(table.pack(...), " ")) end,
	print = function(...) RBX.log("print: " .. table.concat((function(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end return t end)(...), " ")) end,
	shared = {}, _G = {},
}, { __index = getfenv() })
-- math.random con semilla fija: el mapa sale igual en cada ejecución
local m2 = table.clone(math)
m2.random = function(a, b)
	local r = lcg()
	if a == nil then return r end
	if b == nil then return math.floor(r * a) + 1 end
	return math.floor(a + r * (b - a + 1))
end
m2.randomseed = function() end
m2.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
env.math = m2
RBX.env = env

return RBX
