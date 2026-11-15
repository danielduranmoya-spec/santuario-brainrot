--!strict
-- Formato de números para la interfaz: 1234567 -> "1.234.567".

local Format = {}

function Format.number(value: number): string
	local text = tostring(math.floor(value))
	local negative = string.sub(text, 1, 1) == "-"
	if negative then
		text = string.sub(text, 2)
	end
	local grouped = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1.")))
	if string.sub(grouped, 1, 1) == "." then
		grouped = string.sub(grouped, 2)
	end
	return (if negative then "-" else "") .. grouped
end

return Format
