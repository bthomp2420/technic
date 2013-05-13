local context = getfenv()

local __pragma_once = { }
local __FILE__ = "Init.lua"
local __include_stack = { __FILE__ }

__pragma_once[__FILE__] = true
function PRAGMA_ONCE()
	if not __pragma_once[__FILE__] then return end
	error(__pragma_once)
end

function LoadConfig(file, d)
	local r = nil
	local f, e = loadfile(file)
	if f ~= nil then
		r = f()
	end

	if r == nil and d ~= nil then
		local dType = type(d)
		if dType == "table" then
			r = d
		elseif dType == "function" then
			r = d()
			if r ~= nil and type(r) == "table" then
				SaveTable(file, r)
			else
				r = nil
			end
		end
	end

	if r == nil then
		r = { }
	end

	return r
end

function Include(file)
	local result
	if fs.exists(file) then
		local f = fs.open(file, "r")
		if f ~= nil then
			local data = f.readAll()
			f.close()

			local chunk = loadstring(data, file)
			if chunk ~= nil then
				table.insert(__include_stack, file)
				__FILE__ = __include_stack[#__include_stack]
				
				print(("+ %s"):format(file))
				local success, err = pcall(function() result = setfenv(chunk, context)() or true end)
				if not success then
					if not rawequal(err, __pragma_once) then
						print(("Failed to include %s: %s"):format(file, err))
					else
						result = __pragma_once[__FILE__]
					end
				else
					__pragma_once[__FILE__] = result
				end

				table.remove(__include_stack, #__include_stack)
				__FILE__ = __include_stack[#__include_stack]
			else
				print(("Failed to load %s..."):format(file))
			end
		end
	end
	return result
end

function Require(file)
	local result = Include(file)
	if not result then
		error(-1)
	end
	return result
end

Require("core/Serialize.lua")
Require("core/Debug.lua")
Require("core/Class.lua")
Require("core/Table.lua")

Require("core/TurtleDriver.lua")
local driver = TurtleDriver()
driver:LoadPosition()

Require("core/TurtleExecutor.lua")
local executor = TurtleExecutor()
for i, file in ipairs(fs.list("modules")) do
	local result = Include(fs.combine("modules", file))
	if executor:AddHandler(result) then
		print(string.format("Loading Module %s", file))
	end
end

executor:Run(driver)