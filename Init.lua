local context = getfenv()
function Include(file)
	local result
	if fs.exists(file) then
		local f = fs.open(file, "r")
		if f ~= nil then
			local data = f.readAll()
			f.close()

			local chunk = loadstring(data, file)
			if chunk ~= nil then
				result = setfenv(chunk, context)()
			end
		end
	end
	return result
end

Include("core/Serialize.lua")
Include("core/Class.lua")
Include("core/Table.lua")
Include("core/TurtleDriver.lua")
Include("core/TurtleExecutor.lua")

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