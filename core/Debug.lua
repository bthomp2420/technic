PRAGMA_ONCE()

local function init_instrument_api()
	local __isUnwindingStack = false
	function __instrument_class(t, tname)
		local function __instrument_function(f, fname, ...)
			local result
			local args = { ... }

			__isUnwindingStack = false
			local success, err = pcall(function() result = { f(unpack(args)) } end)
			if not success then
				if not __isUnwindingStack then
					__isUnwindingStack = true

					if err then
						print(("Error: %s"):format(tostring(err)))
					else
						print("Error: ???")
					end

					print(("--> %s"):format(fname))
					error(err or "???")
				else
					print((" in %s"):format(fname))
					error(err or "???")
				end
			end

			if not result then return end
			return unpack(result)
		end

		for fname, f in pairs(t) do
			if type(f) == "function" then
				local name = ("%s:%s"):format(tname, fname)
				t[fname] = function(...) return __instrument_function(f, name, ...) end
			end
		end
	end
	return __instrument_class
end

local __instrument_class = init_instrument_api()
init_instrument_api = nil
return __instrument_class