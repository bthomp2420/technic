TurtleExecutor = class(
	function(o)
		o._programStack = { }
		o._handlerStack = { }
		o._handlers = { }
		o._clean = 0

		if not fs.isDir(".save") then
			fs.makeDir(".save")
		end

		if not fs.isDir(".save/stack") then
			fs.makeDir(".save/stack")
		end
	end)

TurtleHandler = class(function(o) end)

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
	self._clean = #self._programStack
	return result
end

function TurtleExecutor:Store()
	for i = self._clean + 1, #self._programStack, 1 do
		SaveTable(fs.combine(".save/stack", tostring(i)), self._programStack[i])
	end
	self._clean = #self._programStack
	local files = fs.list(".save/stack")
	if #files > 0 then
		for i, file in ipairs(files) do
			if tonumber(file) > self._clean then
				fs.delete(fs.combine(".save/stack", file))
			end
		end
	end
end

function TurtleExecutor:_restore()
	local result = false
	local files = fs.list(".save/stack")
	if #files > 0 then
		local function compare(a, b)
			return tonumber(a) < tonumber(b)
		end
		table.sort(files, compare)
		for i, file in ipairs(files) do
			local t = LoadTable(fs.combine(".save/stack", file))
			if t then
				self:Push(t)
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

function TurtleExecutor:Run(driver)
	for i, handler in ipairs(self._handlers) do
		handler:Init(self, driver)
	end

	if not self:_restore() then
		for i, handler in ipairs(self._handlers) do
			handler:Startup(self, driver)
		end
	end

	if self._clean ~= #self._programStack then
		self:Store()
	end

	while true do
		local count = #self._programStack
		if count > 0 then
			local desc = self._programStack[count]
			local handler = self._handlerStack[count]
			if not handler:Run(self, driver, desc) then
				self:Pop()
			end
			if self._clean ~= #self._programStack then
				self:Store()
			end
		else
			sleep(1.0)
		end
	end
end