PRAGMA_ONCE()

QuaryHandler = class("QuaryHandler", TurtleHandler, function (o) end)

function QuaryHandler:Startup(executor, driver)
	local c = self._config
	if c["autostart"] then
		Message("Quary: auto-start")
		self:Start(executor, driver, c["width"], c["height"], c["depth"])
	end
end

function QuaryHandler:Run(executor, driver, desc)
	local w, h, d = desc.w, desc.h, desc.d
	local i = driver:GetX() - desc.x
	local j = driver:GetZ() - desc.z

	local dx = desc.dx
	local dz = desc.dz
	local m11, m12 = dx, dz
	local m21, m22 = -dz, dx

	local x = i * m11 + j * m12
	local z = i * m21 + j * m22
	local y = desc.y - driver:GetY()

	-- move our cursor to the correct y value to mine out the current layer
	while y % 3 ~= 1 and y < d - 1 do
		driver:MineDown()
		y = desc.y - driver:GetY()
	end

	-- double check our depth to make sure that the depth hasn't been overshot
	if y < 0 or y >= d then
		Critical("Quary: y is out-of-range [0,%d): %d", d, y)
		return false
	end

	-- mine above and below if they are valid layers for stripping
	if y > 0 then driver:DigUp() end
	if d - 1 > y then driver:DigDown() end

	-- direction is always either +x or -x except when turning around
	--     * if odd h then alternate each layer
	--     * alternate each z
	local layer = math.floor((y + 2) / 3)
	local layerFactor = (1 - (layer % 2) * 2) * ((h % 2) * 2 - 1)
	local direction = layerFactor * (1 - (z % 2) * 2)
	driver:Face(dx * direction, dz * direction)

	local xEnd = (w - 1) * ((direction + 1) / 2)
	local zEnd = (h - 1) * ((layerFactor + 1) / 2)
	local yEnd = d - 1

	-- once we reach the end of a row depending on the direction we are going
	-- we need to either dig down to the next layer or we need to turn and
	-- advance to the next row
	if x == xEnd then
		if z == zEnd then
			if y + 1 >= d then
				-- once we reach the last row in the last layer return false
				-- to indicate that the quary program has finished
				Message("Quary: done")
				executor:Pop()
				return true
			end

			-- mine down one space to the next layer
			driver:MineDown()
		else

			-- face toward the next row to strip and then mine forward to advance to the next row
			-- the next iteration on the loop will align the turtle in the right direction
			if direction * layerFactor < 0 then
				driver:Face(dz * direction, -dx * direction)
				driver:MineForward()
			else
				driver:Face(-dz * direction, dx * direction)
				driver:MineForward()
			end
		end
	else
		if (x + direction >= 0 and x + direction <= w - 1) and (z >= 0 and z <= h - 1) then
			driver:MineForward()
		else
			-- something bad happened and we are going out of bounds
			Critical("Quary error: stepQuary failed to determine next step based on current turtle state")
			Critical("x, z, y [dx, dz] = %d, %d, %d [%d, %d]", x, z, y, dx, dz)
			Critical("xEnd, zEnd, yEnd = %d, %d, %d", xEnd, zEnd, yEnd)
			Critical("layer, layerFactor, direction = %d, %d, %d", layer, layerFactor, direction)
			return false
		end
	end

	return true
end

function QuaryHandler:Init(executor, driver)
	local config = LoadConfig("config/quary.cfg.lua",
		{
			["autostart"] = false,
			["width"] = 16,
			["height"] = 16,
			["depth"] = 16
		})
	self._config = config
end

function QuaryHandler:Handles(desc)
	return desc.type == "quary"	
end

function QuaryHandler:Start(executor, driver, w, h, d)
	local desc = {}

	desc.type = "quary"
	desc.w, desc.h, desc.d = w, h, d
	desc.x, desc.y, desc.z, desc.dx, desc.dz = driver:GetPosition()

	executor:Push(desc)
end

return QuaryHandler()