PRAGMA_ONCE()

local k_no_cleanup = 0
local k_refuel_cleanup = 1
local k_partial_cleanup = 2
local k_full_cleanup = 3

local k_inventory_mode_manual = -1
local k_inventory_mode_refuel_only = 0
local k_inventory_mode_drop_junk = 1
local k_inventory_mode_ender_chest = 2

TurtleDriver = class("TurtleDriver",
	function(drv, id)
		if not id then id = "default" end
		
		-- load or create the config file for the turtle driver
		local config = LoadConfig("config/turtle.cfg.lua",
			{
				["mode"] = "refuel",
			},
			"Modes:"..
			"    manual 			= user must manually unload and refuel within custom module\n"..
			"    refuel (default)	= only refuels as needed and requires user to empty the contents of the turtle when full\n"..
			"    junk				= automatically refuels and drops any item that matches the first 4 inventory slots\n"..
			"    ender-chest		= uses an ender chest in the first slot to send items to a distribution plant\n")
		drv._config = config

		function switch(t)
			t.case = function (self, x)
				local v
				if x then v = self[x] end
				if not v then
					x = "<default>"
					v = self.default
				end
				if v then
					if type(v) == "function" then
						return v(x, self), x
					else
						return v, x
					end
				end
			end
			return t
		end

		local modes = switch {
			["manual"] = k_inventory_mode_manual,
			["junk"] = k_inventory_mode_drop_junk,
			["ender-chest"] = k_inventory_mode_ender_chest,
			["refuel"] = k_inventory_mode_refuel_only,
			default = k_inventory_mode_manual
		}

		drv._id = id
		drv._x = 0
		drv._y = 0
		drv._z = 0
		drv._dx = 1
		drv._dz = 0

		drv._selectSleepTime = 0.001
		drv._dropSleepTime = 0.001
		drv._retrySleepTime = 0.05
		drv._moveSleepTime = 0.1
		drv._digSleepTime = 0.001
		drv._attackSleepTime = 0.001

		drv._fuelSlotState = { }

		local mode, configMode = modes:case(config["mode"])
		Message("Inventory Mode: %s", configMode)

		drv._inventoryMode = mode
		drv._nextUpdate = 0
		drv._emptySlots = 0
		drv._activeSlot = -1
		drv._junkCount = 0
		drv._chestSlot = 0
		drv._minFuelLevel = 2048

		if drv._inventoryMode == k_inventory_mode_drop_junk then
			drv._junkCount = 4
		elseif drv._inventoryMode == k_inventory_mode_ender_chest then
			drv._chestSlot = 1
		end

		drv._posFile = ".save/driver_pos_"..id
		EnsureDirectory(drv._posFile)
		
		if drv:_restorePosition() then
			Message("Restored position: (%d, %d, %d, %d, %d)", drv._x, drv._y, drv._z, drv._dx, drv._dz)
		end

		drv.TurtleAPI = { }
		for k,v in pairs(turtle) do
			if type(v) == "function" then
				drv.TurtleAPI[k] = v
			end
		end
		__instrument_class(drv.TurtleAPI, "TurtleAPI")
	end)

function TurtleDriver:_getItemCount(...) return self.TurtleAPI.getItemCount(...) end
function TurtleDriver:_getItemSpace(...) return self.TurtleAPI.getItemSpace(...) end

function TurtleDriver:_select(...) return self.TurtleAPI.select(...) end
function TurtleDriver:_compareTo(...) return self.TurtleAPI.compareTo(...) end
function TurtleDriver:_drop(...) return self.TurtleAPI.drop(...) end
function TurtleDriver:_transferTo(...) return self.TurtleAPI.transferTo(...) end
function TurtleDriver:_place(...) return self.TurtleAPI.place(...) end

function TurtleDriver:_refuel(...) return self.TurtleAPI.refuel(...) end
function TurtleDriver:_getFuelLevel(...) return self.TurtleAPI.getFuelLevel(...) end

function TurtleDriver:_attack(...) return self.TurtleAPI.attack(...) end
function TurtleDriver:_attackDown(...) return self.TurtleAPI.attackDown(...) end
function TurtleDriver:_attackUp(...) return self.TurtleAPI.attackUp(...) end

function TurtleDriver:_detect(...) return self.TurtleAPI.detect(...) end
function TurtleDriver:_detectUp(...) return self.TurtleAPI.detectUp(...) end
function TurtleDriver:_detectDown(...) return self.TurtleAPI.detectDown(...) end

function TurtleDriver:_dig(...) return self.TurtleAPI.dig(...) end
function TurtleDriver:_digUp(...) return self.TurtleAPI.digUp(...) end
function TurtleDriver:_digDown(...) return self.TurtleAPI.digDown(...) end

function TurtleDriver:_forward(...) return self.TurtleAPI.forward(...) end
function TurtleDriver:_back(...) return self.TurtleAPI.back(...) end
function TurtleDriver:_up(...) return self.TurtleAPI.up(...) end
function TurtleDriver:_down(...) return self.TurtleAPI.down(...) end

function TurtleDriver:_turnLeft(...) return self.TurtleAPI.turnLeft(...) end
function TurtleDriver:_turnRight(...) return self.TurtleAPI.turnRight(...) end

function TurtleDriver:_craft(...) return self.TurtleAPI.craft(...) end
function TurtleDriver:_suck(...) return self.TurtleAPI.suck(...) end
function TurtleDriver:_suckUp(...) return self.TurtleAPI.suckUp(...) end
function TurtleDriver:_suckDown(...) return self.TurtleAPI.suckDown(...) end

function TurtleDriver:_beginSavePosition(x, y, z, dx, dz)
	local d = self
	local t = BeginSaveTable(d._posFile, { ["x"] = x, ["y"] = y, ["z"] = z, ["dx"] = dx, ["dz"] = dz })
	if t == false then return false end
	return function(c)
		if t(c) then
			d._x, d._y, d._z, d._dx, d._dz = x, y, z, dx, dz
			return true
		end
		return false
	end
end

function TurtleDriver:_restorePosition()
	local d = self
	local t = LoadTable(d._posFile)
	if t ~= nil then
		d._x, d._y, d._z, d._dx, d._dz = t["x"], t["y"], t["z"], t["dx"], t["dz"]
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

function TurtleDriver:Craft(a) return self:_craft(a) end
function TurtleDriver:Suck() return self:_suck() end
function TurtleDriver:SuckUp() return self:_suckUp() end
function TurtleDriver:SuckDown() return self:_suckDown() end

function TurtleDriver:Drop(a) return self:_drop(a) end


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
	if self:SlotHasItems(a) and self:SelectSlot(a) then
		if c and self:_drop(c) then
			self._fuelSlotState[a] = false
			sleep(self._dropSleepTime)
			return self:IsSlotEmpty(a)
		elseif self:_drop() then
			self._fuelSlotState[a] = false
			sleep(self._dropSleepTime)
			return self:IsSlotEmpty(a)
		end
	end
	return false
end

function TurtleDriver:DropSlotUp(a, c)
	if self:SlotHasItems(a) and self:SelectSlot(a) then
		if c and self:_dropUp(c) then
			self._fuelSlotState[a] = false
			sleep(self._dropSleepTime)
			return self:IsSlotEmpty(a)
		elseif self:_dropUp() then
			self._fuelSlotState[a] = false
			sleep(self._dropSleepTime)
			return self:IsSlotEmpty(a)
		end
	end
	return false
end

function TurtleDriver:RefuelFromSlot(a, c) 
	if self:IsSlotEmpty(a) or self._fuelSlotState[a] then
		self._fuelSlotState[a] = self:SlotHasItems(a)
		return false
	end
	local result = self:SelectSlot(a) and self:_refuel(c)
	self._fuelSlotState[a] = not result or self:SlotHasItems(a)
	return result
end

function TurtleDriver:HasFuel()
	local fuelLevel = self:_getFuelLevel()
	return fuelLevel == "unlimited" or fuelLevel > 0
end

function TurtleDriver:NeedsFuel()
	local fuelLevel = self:_getFuelLevel()
	return fuelLevel ~= "unlimited" and fuelLevel < self._minFuelLevel
end

function TurtleDriver:ProcessInventory(mode)
	local result = 0

	local inventoryMode = self._inventoryMode
	if inventoryMode <= k_inventory_mode_manual then
		return false
	end

	local junkCount = self._junkCount
	local initialSlot = self._activeSlot
	local chestSlot = self._chestSlot
	if initialSlot < 0 then initialSlot = 1 end

	for i = junkCount + 1, 16, 1 do
		if self:IsSlotEmpty(i) and (inventoryMode ~= k_inventory_mode_ender_chest or chestSlot ~= i) then
			result = result + 1
		elseif mode >= k_refuel_cleanup and chestSlot ~= i and self:NeedsFuel() and self:RefuelFromSlot(i) then
			result = result + 1
		elseif mode > k_refuel_cleanup and (mode == k_full_cleanup or self:IsSlotFull(i)) then
			if inventoryMode == k_inventory_mode_drop_junk then
				for j = 1, junkCount, 1 do
					if self:CompareSlots(i, j) then
						if self:DropSlot(i) then
							result = result + 1
						end
						break
					end
				end
			end
		end
	end

	if mode > k_refuel_cleanup then
		if inventoryMode == k_inventory_mode_drop_junk then
			for i = 1, junkCount, 1 do
				 if (mode == k_full_cleanup or self:IsSlotFull(i)) then
					local count = self:_getItemCount(i)
					if count > 1 then
						self:DropSlot(i, count - 1)
					end
				end
			end
		elseif inventoryMode == k_inventory_mode_ender_chest and mode == k_full_cleanup then
			-- must dig forward to make sure we have a place to drop the ender chest
			if not self:IsSlotEmpty(chestSlot) then
				self:DigForward()
			end
			
			-- check all slots for items to drop in the ender chest
			for i = 1, 16, 1 do
				if i ~= chestSlot and not self:IsSlotEmpty(i) then
					-- place the ender chest only if it hasn't already been placed
					if self:IsSlotEmpty(chestSlot) or (self:SelectSlot(chestSlot) and self:PlaceForward()) then
						self:DropSlot(i)
					end
				end
			end
		end

		local lastEmpty = 17
		for i = junkCount + 1, 16, 1 do
			if self:IsSlotEmpty(i) and (inventoryMode ~= k_inventory_mode_ender_chest or chestSlot ~= i) then
				for j = lastEmpty - 1, i + 1, -1 do
					if self:SelectSlot(j) and (inventoryMode ~= k_inventory_mode_ender_chest or chestSlot ~= j) then
						self:_transferTo(i)
						self._fuelSlotState[j] = false
						break
					end
					lastEmpty = j
				end
			end
			if lastEmpty <= i then break end 
		end
	end

	-- assume that the block directly infront of the turtle is *always* the ender chest if the slot is empty
	if inventoryMode == k_inventory_mode_ender_chest then
		if self:IsSlotEmpty(chestSlot) and self:SelectSlot(chestSlot) then
			self:DigForward()
		end
	end
	
	self:SelectSlot(initialSlot)
	return result
end

function TurtleDriver:Update()
	-- support manual mode operation
	local inventoryMode = self._inventoryMode
	if inventoryMode <= k_inventory_mode_manual then
		return self:HasFuel()
	end

	-- if the turtle needs fuel, try to refuel from the contents of the inventory
	if self:NeedsFuel() then
		self._emptySlots = self:ProcessInventory(k_refuel_cleanup)

		-- if the turtle is still dead in the water then end the program
		-- TODO: add refuel mode that utilizes an additional slot & ender chest to supply
		-- fuel to turtles remotely
		Assert(self:HasFuel(), "Out of fuel.")
	end
	
	self._nextUpdate = self._nextUpdate - 1
		
	if self._nextUpdate <= 0 then
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

	return self:HasFuel() and self._emptySlots ~= -1
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

function TurtleDriver:PlaceForward()
	if not self:_detect() and self:_place() then
		sleep(self._dropSleepTime)
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

function TurtleDriver:_doMoveOperation(x, y, z, dx, dz, op)
	if self:Update() then
		local t = self:_beginSavePosition(x, y, z, dx, dz)
		if t ~= false then
			if t(op() == false) then
				sleep(self._moveSleepTime)
				return true
			end
			return false
		end
	end
	return false
end

function TurtleDriver:MoveForward()
	local d = self

	local dx = d._dx
	local dz = d._dz
	local x = d._x + dx
	local y = d._y
	local z = d._z + dz
	return d:_doMoveOperation(x, y, z, dx, dz, function() return d:_forward() end)
end

function TurtleDriver:MoveBackward()
	local d = self

	local dx = d._dx
	local dz = d._dz
	local x = d._x - dx
	local y = d._y
	local z = d._z - dz
	return d:_doMoveOperation(x, y, z, dx, dz, function() return d:_back() end)
end

function TurtleDriver:MoveUp()
	local d = self

	local dx = d._dx
	local dz = d._dz
	local x = d._x
	local y = d._y + 1
	local z = d._z
	return d:_doMoveOperation(x, y, z, dx, dz, function() return d:_up() end)
end

function TurtleDriver:MoveDown()
	local d = self

	local dx = d._dx
	local dz = d._dz
	local x = d._x
	local y = d._y - 1
	local z = d._z
	return d:_doMoveOperation(x, y, z, dx, dz, function() return d:_down() end)
end

function TurtleDriver:TurnLeft()
	local d = self

	local dx = -d._dz
	local dz = d._dx
	local x = d._x
	local y = d._y
	local z = d._z
	return d:_doMoveOperation(x, y, z, dx, dz, function() return d:_turnLeft() end)
end

function TurtleDriver:TurnRight()
	local d = self

	local dx = d._dz
	local dz = -d._dx
	local x = d._x
	local y = d._y
	local z = d._z
	return d:_doMoveOperation(x, y, z, dx, dz, function() return d:_turnRight() end)
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

function TurtleDriver:Face(dx, dz)
	Assert((dx == 0 or dz == 0) and (dx ~= dz), "Either Dx or Dz need to be 0 but not both (%d, %d)", dx, dz)
	Assert(dx >= -1 and dx <= 1, "Dx must be in the range of [-1, 1] current value is %d", dx)
	Assert(dz >= -1 and dz <= 1, "Dz must be in the range of [-1, 1] current value is %d", dz)
	local turnRight = (self._dz == dx and self._dx == -dz)
	while not (self._dx == dx and self._dz == dz) do
		if turnRight then
			if not self:TurnRight() then
				sleep(self._retrySleepTime)
			end
		else
			if not self:TurnLeft() then
				sleep(self._retrySleepTime)
			end
		end
	end
end
