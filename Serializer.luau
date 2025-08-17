--!strict

local Serializer = {}

export type Options = {
	pretty: boolean?,
	indent: string?,
	sortKeys: boolean?,
	trailingComma: boolean?,
	maxDepth: number?,
	detectCycles: boolean?,
	customSerialize: ((any, string) -> string?)?,
}

local function isInteger(n: number): boolean
	return n % 1 == 0
end

local function denseArrayLen(t: { [number]: any }): number
	local n = 0
	while t[n + 1] ~= nil do
		n += 1
	end
	return n
end

local function sortKeyFn(a: any, b: any): boolean
	local ta, tb = typeof(a), typeof(b)
	if ta ~= tb then
		local order: { [string]: number } = { number = 1, string = 2, boolean = 3 }
		local ra = order[ta] or 99
		local rb = order[tb] or 99
		if ra ~= rb then return ra < rb end
		return ta < tb
	end
	if ta == "number" then
		return (a :: number) < (b :: number)
	elseif ta == "string" then
		return (a :: string) < (b :: string)
	elseif ta == "boolean" then
		return (a == false and b == true)
	else
		return tostring(a) < tostring(b)
	end
end

local function quoteString(s: string): string
	return string.format("%q", s)
end

local function numberToLiteral(n: number, path: string)
	if n ~= n then error(("Cannot serialize NaN at %s"):format(path), 0) end
	if n == math.huge or n == -math.huge then error(("Cannot serialize infinity at %s"):format(path), 0) end
	return tostring(n)
end

local DEFAULTS: Options = {
	pretty = true,
	indent = "  ",
	sortKeys = true,
	trailingComma = true,
	maxDepth = math.huge,
	detectCycles = true,
	customSerialize = nil,
}

local function indentStr(o: Options, level: number): string
	return (o.pretty and string.rep((o.indent or "  "), level)) or ""
end

local function lead(o: Options, level: number): string
	return o.pretty and ("\n" .. indentStr(o, level)) or ""
end

local function commaJoin(o: Options, parts: { string }, level: number): string
	if not o.pretty then return table.concat(parts, ", ") end
	if #parts == 0 then return "" end
	local sep = "," .. lead(o, level)
	local body = lead(o, level) .. table.concat(parts, sep)
	if o.trailingComma then body ..= "," end
	return body .. lead(o, level - 1)
end

local function keyLiteral(o: Options, k: any, path: string): string
	if typeof(k) == "string" then
		if string.match(k, "^[A-Za-z_][A-Za-z0-9_]*$") then
			return k
		else
			return "[" .. quoteString(k) .. "]"
		end
	elseif typeof(k) == "number" then
		return "[" .. numberToLiteral(k :: number, path) .. "]"
	elseif typeof(k) == "boolean" then
		return "[" .. tostring(k) .. "]"
	else
		return "[" .. quoteString(tostring(k)) .. "]"
	end
end

local function serializeInner(o: Options, seen: { [any]: string }, v: any, path: string, depth: number): string
	local tv = typeof(v)
	if tv == "nil" then
		return "nil"
	elseif tv == "boolean" then
		return tostring(v)
	elseif tv == "number" then
		return numberToLiteral(v, path)
	elseif tv == "string" then
		return quoteString(v)
	elseif tv == "table" then
		if depth > (o.maxDepth or math.huge) then
			error(("Max depth (%d) exceeded at %s"):format(o.maxDepth :: number, path), 0)
		end
		if o.detectCycles and seen[v] then
			error(("Cycle detected: %s -> %s"):format(seen[v], path), 0)
		end
		if o.detectCycles then seen[v] = path end

		local dict = v :: { [any]: any }
		local parts: { string } = {}

		local nArr = denseArrayLen(dict :: { [number]: any })
		for i = 1, nArr do
			table.insert(parts, serializeInner(o, seen, dict[i], path .. "[" .. i .. "]", depth + 1))
		end

		local mapKeys: { any } = {}
		for k, _ in dict do
			if not (typeof(k) == "number" and isInteger(k :: number) and k >= 1 and k <= nArr) then
				table.insert(mapKeys, k)
			end
		end
		if o.sortKeys then table.sort(mapKeys, sortKeyFn) end
		for _, k in mapKeys do
			local val = dict[k]
			if val ~= nil then
				local kl = keyLiteral(o, k, path)
				local vl = serializeInner(o, seen, val, path .. "[" .. tostring(k) .. "]", depth + 1)
				table.insert(parts, (o.pretty and (kl .. " = " .. vl)) or (kl .. "=" .. vl))
			end
		end

		local body = (#parts > 0) and commaJoin(o, parts, depth + 1) or ""
		if o.detectCycles then seen[v] = nil end
		return "{" .. body .. "}"
	else
		if o.customSerialize then
			local out = o.customSerialize(v, path)
			if out ~= nil then return out end
		end
		error(("Unsupported type '%s' at %s"):format(tv, path), 0)
	end
end

function Serializer.serialize(value: any, opts: Options?): string
	local o: Options = table.clone(DEFAULTS)
	if opts then
		for k, v in opts do
			(o :: any)[k] = v
		end
	end

	local seen: { [any]: string } = {}
	local header = "-- https://github.com/IvyyDev/luau-serializer"
	local tblSrc = serializeInner(o, seen, value, "$", 0)
	return header .. "\n\n"
		.. "local tbl = " .. tblSrc .. "\n\n"
		.. "return tbl"
end

return Serializer
