PRAGMA_ONCE()

CraftHandler = class("CraftHandler", TurtleHandler, function (o) end)

function CraftHandler:Startup(executor, driver)
	local c = self._config
	if (c["autostart"]) then
		Message("Craft: auto-start")
		self:Start(executor, driver)
	end
end

function CraftHandler:Run(executor, driver, desc)
	if not driver:IsSlotEmpty(16) then
		if not driver:SelectSlot(16) or not driver:Drop() then
			return true
		end
	end

	for i = 1, 15, 1 do
		if desc.slot[i] and driver:IsSlotEmpty(i) then
			driver:SelectSlot(i)
			if not driver:SuckUp() then
				driver:SuckDown()
			end
			return true
		end
	end

	if driver:SelectSlot(16) then
		driver:Craft()
	end

	return true
end

function CraftHandler:Init(executor, driver)
	local config = LoadConfig("config/craft.cfg.lua",
		{
			["autostart"] = false,
		})
	self._config = config
end

function CraftHandler:Handles(desc)
	return desc.type == "craft"	
end

function CraftHandler:Start(executor, driver)
	local desc = {}

	desc.type = "craft"
	desc.slot = {}

	for i = 1, 15, 1 do

		desc.slot[i] = driver:IsSlotEmpty(i) == false
	end

	executor:Push(desc)
end

return CraftHandler()