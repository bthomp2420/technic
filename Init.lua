local context = getfenv()

local __pragma_once = { }
local __FILE__ = "Init.lua"
local __include_stack = { __FILE__ }
__pragma_once[__FILE__] = true

function PragmaOnce()
	if not __pragma_once[__FILE__] then return end
	error(__pragma_once)
end

function Include(file)
	local result
	if fs.exists(file) and not __pragma_once[file] then
		local f = fs.open(file, "r")
		if f ~= nil then
			local data = f.readAll()
			f.close()

			local chunk = loadstring(data, file)
			if chunk ~= nil then
				__include_stack[#__include_stack+1] = file
				__FILE__ = __include_stack[#__include_stack]
				
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
Require("core/TurtleExecutor.lua")

local driver = TurtleDriver()
driver:LoadPosition()

local executor = TurtleExecutor()
for i, file in ipairs(fs.list("modules")) do
	local result = Include(fs.combine("modules", file))
	if executor:AddHandler(result) then
		print(string.format("Loading Module %s", file))
	end
end

executor:Run(driver)