PRAGMA_ONCE()

AttackHandler = class("AttackHandler", TurtleHandler, function (o) end)

function AttackHandler:Startup(executor, driver)
	local c = self._config
	if (c["autostart"]) then
		Message("Attack: auto-start")
		self:Start(executor, driver)
	end
end

function AttackHandler:Run(executor, driver, desc)
	for i = 1, 16, 1 do
		driver:DropSlotUp(i)
	end

	driver:SelectSlot(1)

	while driver:AttackForward() do end
	while driver:Suck() do end
	
	return true
end

function AttackHandler:Init(executor, driver)
	local config = LoadConfig("config/attack.cfg.lua",
		{
			["autostart"] = false,
		})
	self._config = config
end

function AttackHandler:Handles(desc)
	return desc.type == "attack"	
end

function AttackHandler:Start(executor, driver)
	local desc = {}

	desc.type = "attack"
	desc.slot = {}

	executor:Push(desc)
end

return AttackHandler()