QuaryHandler = class(TurtleHandler, function (o) end)

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
		print("error")
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
	local xDirection = layerFactor * (1 - (z % 2) * 2)
	while not (driver:GetDx() ==  dx * xDirection and driver:GetDz() == dz * xDirection) do
		if driver:GetDz() == dx * xDirection then
			driver:TurnRight()
		else
			driver:TurnLeft()
		end
	end

	local xEnd = (w - 1) * ((xDirection + 1) / 2)
	local zEnd = (h - 1) * ((layerFactor + 1) / 2)
	local yEnd = d - 1

	-- once we reach the end of a row depending on the direction we are going
	-- we need to either dig down to the next layer or we need to turn and
	-- advance to the next row
	if x == xEnd then
		if z == zEnd then
			if y + 2 >= d then
				-- once we reach the last row in the last layer return false
				-- to indicate that the quary program has finished
				print("done")
				executor:Pop()
				return true
			end
			driver:MineDown()
		else
			if xDirection * layerFactor < 0 then
				driver:TurnRight()
				driver:MineForward()
				driver:TurnRight()
			else
				driver:TurnLeft()
				driver:MineForward()
				driver:TurnLeft()
			end
		end
	else
		if (x + xDirection >= 0 and x + xDirection <= w - 1) and (z >= 0 and z <= h - 1) then
			driver:MineForward()
		else
			-- something bad happened and we are going out of bounds
			print("error: stepQuary failed to determine next step based on current turtle state")
			print(string.format("x, z, y [dx, dz] = %d, %d, %d [%d, %d]", x, z, y, dx, dz))
			print(string.format("xEnd, zEnd, yEnd = %d, %d, %d", xEnd, zEnd, yEnd))
			print(string.format("layer, layerFactor, xDirection = %d, %d, %d", layer, layerFactor, xDirection))
			return false
		end
	end

	return true
end

function QuaryHandler:Init(executor, driver)
	print ("Quary Initialized")
end

function QuaryHandler:Startup(executor, driver)
	print ("Quary Starting")
	self:Start(executor, driver, 16, 16, 16)
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