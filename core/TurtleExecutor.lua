PRAGMA_ONCE()

TurtleExecutor = class("TurtleExecutor",
	function(o)
		o._programStack = { }
		o._handlerStack = { }
		o._handlers = { }
		o._storedStackSize = 0

		o._computerId = os.getComputerLabel()
		if o._computerId == nil or o._computerId == "" then
			o._computerId = "turtle-" + os.getComputerId()
			os.setComputerLabel(o._computerId)
		end

		print("Turtle Id: " + o._computerId)

		if not fs.isDir(".save") then
			fs.makeDir(".save")
		end

		if not fs.isDir(".save/stack") then
			fs.makeDir(".save/stack")
		end
	end)

TurtleHandler = class("TurtleHandler", function(o) end)

function TurtleHandler:Run(executor, driver, desc)
	
end

function TurtleHandler:Init(executor, driver)

end

function TurtleHandler:Startup(executor, driver)

end

function TurtleHandler:Handles(desc)

end

function TurtleExecutor:Push(desc)
	for i, handler in ipairs(self._handlers) do
		if handler:Handles(desc) then
			local j = #self._programStack + 1
			self._programStack[j] = desc
			self._handlerStack[j] = handler
			break
		end
	end
end

function TurtleExecutor:Pop()
	local result
	local count = #self._programStack
	if count > 0 then
		result = self._programStack[count]
		table.remove(self._programStack, count)
		table.remove(self._handlerStack, count)
	end
	return result
end

function TurtleExecutor:Store()
	if self._storedStackSize ~= #self._programStack then
		for i = self._storedStackSize + 1, #self._programStack, 1 do
			SaveTable(fs.combine(".save/stack", tostring(i)), self._programStack[i])
		end
		self._storedStackSize = #self._programStack
		local files = fs.list(".save/stack")
		if #files > 0 then
			for i, file in ipairs(files) do
				if tonumber(file) > self._storedStackSize then
					fs.delete(fs.combine(".save/stack", file))
				end
			end
		end
	end
end

function TurtleExecutor:Resume()
	local result = false
	local files = fs.list(".save/stack")
	if #files > 0 then
		print("Resuming...")
		local function compare(a, b)
			return tonumber(a) < tonumber(b)
		end
		table.sort(files, compare)
		for i, file in ipairs(files) do
			local t = LoadTable(fs.combine(".save/stack", file))
			if t ~= nil then
				self:Push(t)
				self._storedStackSize = self._storedStackSize + 1
			end
		end
		result = true
	end
	return result
end

function TurtleExecutor:AddHandler(handler)
	local result = false
	if handler ~= nil and handler:is_a(TurtleHandler) then
		self._handlers[#self._handlers + 1] = handler
		result = true
	end
	return result
end

function TurtleExecutor:Update(driver)
	local count = #self._programStack
	if count > 0 then
		local exec = self
		local desc = self._programStack[count]
		local handler = self._handlerStack[count]
		local result = false
		
		if desc ~= nil then
			local success, err = pcall(function() result = handler:Run(exec, driver, desc) end)
			if not success then
				print(err)
			end
		end
		
		if not result then
			self:Pop()
		end

		self:Store()
	else
		sleep(1.0)
	end
end

function TurtleExecutor:Run(driver)
	print("TurtleExecutor: Initializing...")
	for i, handler in ipairs(self._handlers) do
		handler:Init(self, driver)
	end

	if not self:Resume() then
		print("TurtleExecutor: Starting...")
		for i, handler in ipairs(self._handlers) do
			handler:Startup(self, driver)
		end
		self:Store()
	end

	local exec = self
	while true do
		local success, err = pcall(function() exec:Update(driver) end)
		if not success then
			print(("Unhandled error caught: %s"):format(err))
			break
		end
	end

	print("TurtleExecutor: Shutting down...")
end