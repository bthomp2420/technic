local k_no_cleanup = 0
local k_partial_cleanup = 1
local k_full_cleanup = 2

TurtleDriver = class(
	function(drv, id)
		if not id then id = "default" end
		
		drv._id = id
		drv._x = 0
		drv._y = 0
		drv._z = 0
		drv._dx = 1
		drv._dz = 0   

		drv._selectSleepTime = 0.1
		drv._dropSleepTime = 0.1
		drv._retrySleepTime = 0.2
		drv._moveSleepTime = 0.2
		drv._digSleepTime = 0.05
		drv._turnSleepTime = 0.05
		drv._attackSleepTime = 0.05

		drv._nextUpdate = 16
		drv._emptySlots = 0
		drv._activeSlot = -1

		if not fs.isDir(".save") then
			fs.makeDir(".save")
		end
	end)

function TurtleDriver:_wrapCall(name, f, ...)
	local result = {}
	local args = {...}
	local success, error = pcall(function() result = { f(unpack(args)) } end)
	if not success then
		print("Unexpected error in turtle API: "..name)
		error(error)
	end
	return unpack(result)
end

function TurtleDriver:_getItemCount(...) return self:_wrapCall("getItemCount", turtle.getItemCount, ...) end
function TurtleDriver:_getItemSpace(...) return self:_wrapCall("getItemSpace", turtle.getItemSpace, ...) end

function TurtleDriver:_select(...) return self:_wrapCall("select", turtle.select, ...) end
function TurtleDriver:_compareTo(...) return self:_wrapCall("compareTo", turtle.compareTo, ...) end
function TurtleDriver:_drop(...) return self:_wrapCall("drop", turtle.drop, ...) end

function TurtleDriver:_refuel(...) return self:_wrapCall("refuel", turtle.refuel, ...) end
function TurtleDriver:_getFuelLevel(...) return self:_wrapCall("getFuelLevel", turtle.getFuelLevel, ...) end

function TurtleDriver:_attack(...) return self:_wrapCall("attack", turtle.attack, ...) end
function TurtleDriver:_attackDown(...) return self:_wrapCall("attackDown", turtle.attackDown, ...) end
function TurtleDriver:_attackUp(...) return self:_wrapCall("attackUp", turtle.attackUp, ...) end

function TurtleDriver:_detect(...) return self:_wrapCall("detect", turtle.detect, ...) end
function TurtleDriver:_detectUp(...) return self:_wrapCall("detectUp", turtle.detectUp, ...) end
function TurtleDriver:_detectDown(...) return self:_wrapCall("detectDown", turtle.detectDown, ...) end

function TurtleDriver:_dig(...) return self:_wrapCall("dig", turtle.dig, ...) end
function TurtleDriver:_digUp(...) return self:_wrapCall("digUp", turtle.digUp, ...) end
function TurtleDriver:_digDown(...) return self:_wrapCall("digDown", turtle.digDown, ...) end

function TurtleDriver:_forward(...) return self:_wrapCall("forward", turtle.forward, ...) end
function TurtleDriver:_back(...) return self:_wrapCall("back", turtle.back, ...) end
function TurtleDriver:_up(...) return self:_wrapCall("up", turtle.up, ...) end
function TurtleDriver:_down(...) return self:_wrapCall("down", turtle.down, ...) end

function TurtleDriver:_turnLeft(...) return self:_wrapCall("turnLeft", turtle.turnLeft, ...) end
function TurtleDriver:_turnRight(...) return self:_wrapCall("turnRight", turtle.turnRight, ...) end

function TurtleDriver:SavePosition()
	return SaveTable(".save/driver_pos_"..self._id,
	{
		["x"] = self._x,
		["y"] = self._y,
		["z"] = self._z,
		["dx"] = self._dx,
		["dz"] = self._dz,
	})
end

function TurtleDriver:LoadPosition()
	local t = LoadTable(".save/driver_pos_"..self._id)
	if t ~= nil then
		self._x = t["x"]
		self._y = t["y"]
		self._z = t["z"]
		self._dx = t["dx"]
		self._dz = t["dz"]
		return true
	end
	return false
end

function TurtleDriver:GetPosition()
	return self._x, self._y, self._z, self._dx, self._dz
end

function TurtleDriver:GetX() return self._x end
function TurtleDriver:GetY() return self._y end
function TurtleDriver:GetZ() return self._z end
function TurtleDriver:GetDx() return self._dx end
function TurtleDriver:GetDz() return self._dz end

function TurtleDriver:SelectSlot(a)
	if a > 0 and a <= 16 then
		if a ~= self._activeSlot then
			if self:_select(a) then
				self._activeSlot = a
				sleep(self._selectSleepTime)
				return true
			end
			return false
		end
		return true
	end
	return false
end

function TurtleDriver:SlotHasItems(a)
	return self:_getItemCount(a) > 0
end

function TurtleDriver:IsSlotEmpty(a)
	return self:_getItemCount(a) == 0
end

function TurtleDriver:IsSlotFull(a)
	return self:_getItemSpace(a) == 0
end

function TurtleDriver:CompareSlots(a, b)
	return self:SlotHasItems(a) and self:SlotHasItems(b) and self:SelectSlot(a) and self:_compareTo(b)
end

function TurtleDriver:DropSlot(a, c)
	if self:SlotHasItems(a) and self:SelectSlot(a) and self:_drop(c) and (c or self:IsSlotEmpty(a)) then
		sleep(self._dropSleepTime)
		return true
	end
	return false
end

function TurtleDriver:RefuelFromSlot(a, c)
	return self:SlotHasItems(a) and self:SelectSlot(a) and self:_refuel(c) and self:IsSlotEmpty(a)
end

function TurtleDriver:ProcessInventory(mode)
	local result = 0
	local initialSlot = self._activeSlot
	for i = 5, 16, 1 do
		if self:IsSlotEmpty(i) or (mode == k_full_cleanup and self:RefuelFromSlot(i)) then
			result = result + 1
		elseif mode ~= k_no_cleanup and (mode == k_full_cleanup or self:IsSlotFull(i)) then
			for j = 1, 4, 1 do
				if self:CompareSlots(i, j) then
					if self:DropSlot(i) then
						result = result + 1
					end
					break
				end
			end
		end
	end
	for i = 1, 4, 1 do
		if mode ~= k_no_cleanup and (mode == k_full_cleanup or self:IsSlotFull(i)) then
			local count = self:_getItemCount(i)
			if count > 1 then
				self:DropSlot(i, count - 1)
			end
		end
	end
	self:SelectSlot(initialSlot)
	return result
end

function TurtleDriver:Update()
	if self:_getFuelLevel() == 0 then
		self._emptySlots = self:ProcessInventory(k_full_cleanup)
		self._nextUpdate = 16
	else
		self._nextUpdate = self._nextUpdate - 1
		
		if self._nextUpdate == 0 then
			self._emptySlots = self:ProcessInventory(k_no_cleanup)
			self._nextUpdate = 16
		end
		
		if self._emptySlots == 0 then
			self._emptySlots = self:ProcessInventory(k_partial_cleanup)
		end
		
		if self._emptySlots == 0 then
			self._emptySlots = self:ProcessInventory(k_full_cleanup)
		end

		if self._emptySlots == 0 then
			self._emptySlots = -1
			self._nextUpdate = 64
		end
	end
	local fuelLevel = self:_getFuelLevel()
	return fuelLevel == "unlimited" or fuelLevel > 0
end

function TurtleDriver:AttackForward()
	if self:_attack() then
		sleep(self._attackSleepTime)
		return true
	end
	return false
end

function TurtleDriver:AttackDown()
	if self:_attackDown() then
		sleep(self._attackSleepTime)
		return true
	end
	return false
end

function TurtleDriver:AttackUp()
	if self:_attackUp() then
		sleep(self._attackSleepTime)
		return true
	end
	return false
end

function TurtleDriver:DigForward()
	if self:_detect() and self:_dig() then
		sleep(self._digSleepTime)
		return true
	end
	return false
end

function TurtleDriver:DigUp()
	if self:_detectUp() and self:_digUp() then
		sleep(self._digSleepTime)
		return true
	end
	return false
end

function TurtleDriver:DigDown()
	if self:_detectDown() and self:_digDown() then
		sleep(self._digSleepTime)
		return true
	end
	return false
end

function TurtleDriver:MoveForward()
	if self:Update() and self:_forward() then
		self._x = self._x + self._dx
		self._z = self._z + self._dz
		self:SavePosition()
		sleep(self._moveSleepTime)
		return true
	end
	return false
end

function TurtleDriver:MoveBackward()
	if self:Update() and self:_back() then
		self._x = self._x - self._dx
		self._z = self._z - self._dz
		self:SavePosition()
		sleep(self._moveSleepTime)
		return true
	end
	return false
end

function TurtleDriver:MoveUp()
	if self:Update() and self:_up() then
		self._y = self._y + 1
		self:SavePosition()
		sleep(self._moveSleepTime)
		return true
	end
	return false
end

function TurtleDriver:MoveDown()
	if self:Update() and self:_down() then
		self._y = self._y - 1
		self:SavePosition()
		sleep(self._moveSleepTime)
		return true
	end
	return false
end

function TurtleDriver:TurnLeft()
	if self:_turnLeft() then
		self._dx, self._dz = -self._dz, self._dx
		self:SavePosition()
		sleep(self._turnSleepTime)
		return true
	end
	return false
end

function TurtleDriver:TurnRight()
	if self:_turnRight() then
		self._dx, self._dz = self._dz, -self._dx
		self:SavePosition()
		sleep(self._turnSleepTime)
		return true
	end
	return false
end

function TurtleDriver:MineForward()
	while not self:MoveForward() do
		if not self:DigForward() and not self:AttackForward() then
			sleep(self._retrySleepTime)
		end
	end
end

function TurtleDriver:MineDown()
	while not self:MoveDown() do
		if not self:DigDown() and not self:AttackDown() then
			sleep(self._retrySleepTime)
		end
	end
end

function TurtleDriver:MineUp()
	while not self:MoveUp() do
		if not self:DigUp() and not self:AttackUp() then
			sleep(self._retrySleepTime)
		end
	end
end